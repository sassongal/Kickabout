import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/ui/team_builder/manual_team_builder.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/features/games/presentation/notifiers/log_past_game_notifier.dart';
import 'package:kattrick/core/providers/auth_providers.dart';

/// Screen for logging a past game retroactively
class LogPastGameScreen extends ConsumerStatefulWidget {
  final String hubId;

  const LogPastGameScreen({super.key, required this.hubId});

  @override
  ConsumerState<LogPastGameScreen> createState() => _LogPastGameScreenState();
}

class _LogPastGameScreenState extends ConsumerState<LogPastGameScreen> {
  // All state is now managed by LogPastGameNotifier
  // Access via: ref.watch(logPastGameNotifierProvider(widget.hubId))
  
  final _teamAScoreController = TextEditingController();
  final _teamBScoreController = TextEditingController();

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final state = ref.read(logPastGameNotifierProvider(widget.hubId));
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: state.selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('he'),
    );
    if (picked != null) {
      notifier.setSelectedDate(picked);
    }
  }

  void _nextStep() {
    final state = ref.read(logPastGameNotifierProvider(widget.hubId));
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    try {
      if (state.currentStep < 2) {
        notifier.nextStep();
      } else {
        _saveGame();
      }
    } catch (e) {
      SnackbarHelper.showError(context, e.toString());
    }
  }

  void _previousStep() {
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    notifier.previousStep();
  }

  Future<void> _saveGame() async {
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    try {
      await notifier.saveGame();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק נרשם בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירה: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logPastGameNotifierProvider(widget.hubId));
    
    // Sync controllers with state
    if (_teamAScoreController.text != state.teamAScore) {
      _teamAScoreController.text = state.teamAScore;
    }
    if (_teamBScoreController.text != state.teamBScore) {
      _teamBScoreController.text = state.teamBScore;
    }
    
    if (state.isLoading && state.hub == null) {
      return AppScaffold(
        title: 'תיעוד משחק עבר',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return AppScaffold(
      title: 'תיעוד משחק עבר',
      body: Column(
        children: [
          // Step indicator
          LinearProgressIndicator(
            value: (state.currentStep + 1) / 3,
            backgroundColor: Colors.grey[300],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepIndicator(0, 'פרטים', state),
                _buildStepIndicator(1, 'שחקנים', state),
                _buildStepIndicator(2, 'קבוצות', state),
              ],
            ),
          ),
          
          // Step content
          Expanded(
            child: _buildStepContent(state),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('הקודם'),
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _nextStep,
                    child: Text(state.currentStep == 2 ? 'שמור' : 'הבא'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, LogPastGameState state) {
    final isActive = step == state.currentStep;
    final isCompleted = step < state.currentStep;
    
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive || isCompleted
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
          child: isCompleted
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : Text(
                  '${step + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(LogPastGameState state) {
    switch (state.currentStep) {
      case 0:
        return _buildDetailsStep(state);
      case 1:
        return _buildPlayersStep(state);
      case 2:
        return _buildTeamsStep(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep(LogPastGameState state) {
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date picker
          InkWell(
            onTap: _selectDate,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'תאריך המשחק',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(
                DateFormat('dd/MM/yyyy', 'he').format(state.selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Venue selector
          if (state.venues.isNotEmpty)
            DropdownButtonFormField<String>(
              value: state.selectedVenueId,
              decoration: const InputDecoration(
                labelText: 'מגרש',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: state.venues.map((venue) {
                return DropdownMenuItem<String>(
                  value: venue.venueId,
                  child: Text(venue.name),
                );
              }).toList(),
              onChanged: (value) {
                notifier.setSelectedVenueId(value);
              },
            ),
          if (state.venues.isEmpty) ...[
            const SizedBox(height: 16),
            const Text('אין מגרשים זמינים'),
          ],
          const SizedBox(height: 16),
          
          // Event selector
          if (state.events.isNotEmpty)
            DropdownButtonFormField<String>(
              value: state.selectedEventId,
              decoration: const InputDecoration(
                labelText: 'קישור לאירוע (אופציונלי)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('ללא אירוע'),
                ),
                ...state.events.map((event) => DropdownMenuItem<String>(
                  value: event.eventId,
                  child: Text(event.title),
                )),
              ],
              onChanged: (value) {
                notifier.setSelectedEventId(value);
              },
            ),
          const SizedBox(height: 16),
          
          // Scores
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _teamAScoreController,
                  decoration: const InputDecoration(
                    labelText: 'תוצאת קבוצה א\'',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    notifier.setTeamAScore(value);
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                ':',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _teamBScoreController,
                  decoration: const InputDecoration(
                    labelText: 'תוצאת קבוצה ב\'',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    notifier.setTeamBScore(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Show in Community Feed
          CheckboxListTile(
            title: const Text('להעלות ללוח אירועים הקהילתי?'),
            subtitle: const Text('המשחק יופיע בלוח הפעילות הקהילתי לכל המשתמשים'),
            value: state.showInCommunityFeed,
            onChanged: (value) {
              notifier.toggleShowInCommunityFeed();
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersStep(LogPastGameState state) {
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'בחר שחקנים שהשתתפו במשחק (${state.selectedPlayerIds.length} נבחרו)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.hubMembers.length,
            itemBuilder: (context, index) {
              final user = state.hubMembers[index];
              final isSelected = state.selectedPlayerIds.contains(user.uid);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  notifier.togglePlayerSelection(user.uid);
                },
                title: Text(user.name),
                subtitle: Text('דירוג: ${user.currentRankScore.toStringAsFixed(1)}'),
                secondary: CircleAvatar(
                  radius: 20,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(user.name[0].toUpperCase())
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTeamsStep(LogPastGameState state) {
    final notifier = ref.read(logPastGameNotifierProvider(widget.hubId).notifier);
    final currentUserId = ref.read(currentUserIdProvider) ?? '';
    
    return ManualTeamBuilder(
      gameId: '', // Not needed for past games
      game: Game(
        gameId: '',
        createdBy: currentUserId,
        hubId: widget.hubId,
        gameDate: state.selectedDate,
        teamCount: 2,
        status: GameStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      teamCount: 2,
      playerIds: state.selectedPlayerIds.toList(),
      onTeamsChanged: (teams) {
        notifier.setTeams(teams);
      },
    );
  }
}
