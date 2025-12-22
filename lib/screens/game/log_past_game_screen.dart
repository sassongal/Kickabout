import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/log_past_game_details.dart';
import 'package:kattrick/ui/team_builder/manual_team_builder.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/utils/city_utils.dart';

/// Screen for logging a past game retroactively
class LogPastGameScreen extends ConsumerStatefulWidget {
  final String hubId;

  const LogPastGameScreen({super.key, required this.hubId});

  @override
  ConsumerState<LogPastGameScreen> createState() => _LogPastGameScreenState();
}

class _LogPastGameScreenState extends ConsumerState<LogPastGameScreen> {
  int _currentStep = 0;
  
  // Step 1: Game details
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 1));
  String? _selectedVenueId;
  String? _selectedEventId;
  final _teamAScoreController = TextEditingController();
  final _teamBScoreController = TextEditingController();
  
  // Step 2: Players
  final Set<String> _selectedPlayerIds = {};
  
  // Step 3: Teams
  List<Team> _teams = [];
  
  bool _showInCommunityFeed = false;
  bool _isLoading = false;
  Hub? _hub;
  List<Venue> _venues = [];
  List<User> _hubMembers = [];
  List<HubEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _teamAScoreController.dispose();
    _teamBScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final usersRepo = ref.read(usersRepositoryProvider);
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      
      // Load hub
      final hub = await hubsRepo.getHub(widget.hubId);
      
      // Load venues
      final venueIds = hub?.venueIds ?? [];
      final venues = <Venue>[];
      for (final venueId in venueIds) {
        try {
          final venue = await venuesRepo.getVenue(venueId);
          if (venue != null) {
            venues.add(venue);
          }
        } catch (e) {
          // Skip if venue not found
          continue;
        }
      }
      
      // Load hub members
      final members = hub != null
          ? await usersRepo
              .getUsers(await hubsRepo.getHubMemberIds(hub.hubId))
          : <User>[];
      
      // Load events
      final events = await eventsRepo.getHubEvents(widget.hubId);
      
      if (mounted) {
        setState(() {
          _hub = hub;
          _venues = venues;
          _hubMembers = members;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'שגיאה בטעינת נתונים: $e');
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('he'),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _canProceedToNextStep() {
    switch (_currentStep) {
      case 0:
        return _teamAScoreController.text.trim().isNotEmpty &&
            _teamBScoreController.text.trim().isNotEmpty;
      case 1:
        return _selectedPlayerIds.length >= 4; // Minimum 4 players
      case 2:
        return _teams.isNotEmpty && _teams.every((team) => team.playerIds.isNotEmpty);
      default:
        return false;
    }
  }

  void _nextStep() {
    if (!_canProceedToNextStep()) {
      SnackbarHelper.showError(
        context,
        _currentStep == 0
            ? 'נא למלא את כל השדות'
            : _currentStep == 1
                ? 'נא לבחור לפחות 4 שחקנים'
                : 'נא לחלק את כל השחקנים לקבוצות',
      );
      return;
    }
    
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      _saveGame();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _saveGame() async {
    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);
      
      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      final teamAScore = int.tryParse(_teamAScoreController.text.trim()) ?? 0;
      final teamBScore = int.tryParse(_teamBScoreController.text.trim()) ?? 0;
      Venue? selectedVenue;
      if (_selectedVenueId != null) {
        for (final venue in _venues) {
          if (venue.venueId == _selectedVenueId) {
            selectedVenue = venue;
            break;
          }
        }
      }
      final city = _hub?.city ?? selectedVenue?.city;
      final region = _hub?.region ??
          (city != null ? CityUtils.getRegionForCity(city) : null);

      final details = LogPastGameDetails(
        hubId: widget.hubId,
        gameDate: _selectedDate,
        venueId: _selectedVenueId,
        eventId: _selectedEventId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        playerIds: _selectedPlayerIds.toList(),
        teams: _teams,
        showInCommunityFeed: _showInCommunityFeed,
        region: region,
        city: city,
      );
      
      await gamesRepo.logPastGame(details, currentUserId);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק נרשם בהצלחה!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _hub == null) {
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
            value: (_currentStep + 1) / 3,
            backgroundColor: Colors.grey[300],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepIndicator(0, 'פרטים'),
                _buildStepIndicator(1, 'שחקנים'),
                _buildStepIndicator(2, 'קבוצות'),
              ],
            ),
          ),
          
          // Step content
          Expanded(
            child: _buildStepContent(),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: const Text('הקודם'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    child: Text(_currentStep == 2 ? 'שמור' : 'הבא'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step == _currentStep;
    final isCompleted = step < _currentStep;
    
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

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildDetailsStep();
      case 1:
        return _buildPlayersStep();
      case 2:
        return _buildTeamsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDetailsStep() {
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
                DateFormat('dd/MM/yyyy', 'he').format(_selectedDate),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Venue selector
          if (_venues.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedVenueId,
              decoration: const InputDecoration(
                labelText: 'מגרש',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: _venues.map((venue) {
                return DropdownMenuItem<String>(
                  value: venue.venueId,
                  child: Text(venue.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedVenueId = value);
              },
            ),
          if (_venues.isEmpty) ...[
            const SizedBox(height: 16),
            const Text('אין מגרשים זמינים'),
          ],
          const SizedBox(height: 16),
          
          // Event selector
          if (_events.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedEventId,
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
                ..._events.map((event) => DropdownMenuItem<String>(
                  value: event.eventId,
                  child: Text(event.title),
                )),
              ],
              onChanged: (value) {
                setState(() => _selectedEventId = value);
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Show in Community Feed
          CheckboxListTile(
            title: const Text('להעלות ללוח אירועים הקהילתי?'),
            subtitle: const Text('המשחק יופיע בלוח הפעילות הקהילתי לכל המשתמשים'),
            value: _showInCommunityFeed,
            onChanged: (value) {
              setState(() {
                _showInCommunityFeed = value ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'בחר שחקנים שהשתתפו במשחק (${_selectedPlayerIds.length} נבחרו)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _hubMembers.length,
            itemBuilder: (context, index) {
              final user = _hubMembers[index];
              final isSelected = _selectedPlayerIds.contains(user.uid);
              
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPlayerIds.add(user.uid);
                    } else {
                      _selectedPlayerIds.remove(user.uid);
                    }
                  });
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

  Widget _buildTeamsStep() {
    return ManualTeamBuilder(
      gameId: '', // Not needed for past games
      game: Game(
        gameId: '',
        createdBy: ref.read(currentUserIdProvider) ?? '',
        hubId: widget.hubId,
        gameDate: _selectedDate,
        teamCount: 2,
        status: GameStatus.completed,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      teamCount: 2,
      playerIds: _selectedPlayerIds.toList(),
      onTeamsChanged: (teams) {
        setState(() => _teams = teams);
      },
    );
  }
}
