import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/features/games/presentation/notifiers/log_game_notifier.dart';

/// Log Game Screen - "The Session Dashboard" (Manager only)
///
/// This screen supports TWO modes:
/// 1. **Session Mode** (Multi-Match): If event has teams with colors
///    - Shows aggregate wins scoreboard (Blue: 6, Red: 4, Green: 2)
///    - "Log Match Result" button to record individual matches
///    - Attendance list
/// 2. **Single Game Mode**: If no teams or teams without colors
///    - Traditional Team A vs Team B score input
///    - Attendance and highlights
///
/// When "Finish & Log" is clicked, it calls GamesRepository.convertEventToGame()
/// which creates a Game document and triggers the Cloud Function to update stats.
class LogGameScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const LogGameScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<LogGameScreen> createState() => _LogGameScreenState();
}

class _LogGameScreenState extends ConsumerState<LogGameScreen> {
  // All state is now managed by LogGameNotifier
  // Access via: ref.watch(logGameNotifierProvider(widget.hubId, widget.eventId))

  Future<void> _submitGame() async {
    final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
    
    try {
      await notifier.submitGame();
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'המשחק נרשם בהצלחה!');
        context.pop(); // Return to events tab
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  // Helper methods that use the notifier
  void _togglePlayerPresence(String playerId) {
    ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier)
        .togglePlayerPresence(playerId);
  }

  void _toggleHighlight(String playerId, String highlight) {
    ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier)
        .togglePlayerHighlight(playerId, highlight);
  }

  bool _hasHighlight(String playerId, String highlight) {
    final state = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId));
    return state.playerHighlights[playerId]?.contains(highlight) ?? false;
  }

  void _togglePlayerPayment(String playerId) {
    ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier)
        .togglePlayerPayment(playerId);
  }

  Future<void> _logMatchResult() async {
    final state = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId));
    final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
    
    if (state.event == null || state.event!.teams.isEmpty) {
      SnackbarHelper.showError(context, 'אין קבוצות מוגדרות לאירוע');
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _LogMatchDialog(event: state.event!),
    );

    if (result == null) return;

    try {
      final teamAColor = result['teamAColor'] as String;
      final teamBColor = result['teamBColor'] as String;
      final scoreA = result['scoreA'] as int;
      final scoreB = result['scoreB'] as int;

      await notifier.logMatchResult(
        teamAColor: teamAColor,
        teamBColor: teamBColor,
        scoreA: scoreA,
        scoreB: scoreB,
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תוצאה נרשמה בהצלחה!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logGameNotifierProvider(widget.hubId, widget.eventId));
    
    if (state.isLoading) {
      return AppScaffold(
        title: 'רישום משחק',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (state.event == null) {
      return AppScaffold(
        title: 'רישום משחק',
        body: const Center(child: Text('אירוע לא נמצא')),
      );
    }

    // If Session Mode, show Session Dashboard
    if (state.isSessionMode) {
      return _buildSessionDashboard(context, state);
    }

    // Otherwise, show Single Game Mode
    return _buildSingleGameMode(context, state);
  }

  Widget _buildSessionDashboard(BuildContext context, LogGameState state) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return AppScaffold(
      title: state.event!.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            state.event!.title,
                            style: PremiumTypography.techHeadline.copyWith(
                              fontSize: 20,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'מפגש פעיל',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: PremiumColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(state.event!.eventDate),
                          style: PremiumTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Aggregate Wins Scoreboard
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תוצאות מצטברות',
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.event!.aggregateWins.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('עדיין לא נרשמו תוצאות'),
                        ),
                      )
                    else
                      ...state.event!.teams.map((team) {
                        final wins =
                            state.event!.aggregateWins[team.color ?? ''] ?? 0;
                        final colorValue = team.colorValue ?? 0xFF2196F3;
                        final maxWins = state.event!.aggregateWins.values.isEmpty
                            ? 1
                            : state.event!.aggregateWins.values
                                .reduce((a, b) => a > b ? a : b);
                        final percentage = maxWins > 0 ? (wins / maxWins) : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Color(colorValue),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          team.color ?? team.name,
                                          style: PremiumTypography.bodyLarge
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$wins ניצחונות',
                                    style: PremiumTypography.heading2,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: percentage,
                                  minHeight: 24,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(colorValue)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Log Match Result Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting ? null : _logMatchResult,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(state.isSubmitting ? 'שומר...' : 'רישום תוצאה'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Recent Matches
            if (state.event!.matches.isNotEmpty) ...[
              PremiumCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'משחקים אחרונים',
                        style: PremiumTypography.techHeadline.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...state.event!.matches.reversed.take(10).map((match) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForTeam(match.teamAColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      match.teamAColor,
                                      style: PremiumTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${match.scoreA}',
                                    style: PremiumTypography.heading2,
                                  ),
                                ],
                              ),
                              Text(
                                'VS',
                                style: PremiumTypography.bodyMedium.copyWith(
                                  color: PremiumColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${match.scoreB}',
                                    style: PremiumTypography.heading2,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      match.teamBColor,
                                      style: PremiumTypography.bodyMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: _getColorForTeam(match.teamBColor),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Attendance
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נוכחות',
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.registeredPlayers.map((player) {
                      final isPresent = state.presentPlayers[player.uid] ?? false;
                      final isPaid = state.paidPlayers[player.uid] ?? false;
                      return CheckboxListTile(
                        value: isPresent,
                        onChanged: (value) => _togglePlayerPresence(player.uid),
                        title: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: PremiumTypography.bodyLarge,
                              ),
                            ),
                            // Payment toggle (only if hub has payment link)
                            if (state.hub?.paymentLink != null &&
                                state.hub!.paymentLink!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _togglePlayerPayment(player.uid);
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        activeColor: PremiumColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Finish Session Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting ? null : _submitGame,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(state.isSubmitting ? 'שומר...' : 'סיים מפגש'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForTeam(String? colorName) {
    if (colorName == null) return Colors.grey;

    final state = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId));
    final team = state.event?.teams.firstWhere(
      (t) => t.color == colorName,
      orElse: () => Team(teamId: '', name: '', colorValue: 0xFF2196F3),
    );

    return Color(team?.colorValue ?? 0xFF2196F3);
  }

  Widget _buildSingleGameMode(BuildContext context, LogGameState state) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');

    return AppScaffold(
      title: 'רישום משחק',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info card
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.event!.title,
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: PremiumColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateFormat.format(state.event!.eventDate),
                          style: PremiumTypography.bodyMedium,
                        ),
                      ],
                    ),
                    if (state.event!.location != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: PremiumColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.event!.location!,
                              style: PremiumTypography.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Score input
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'תוצאה',
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Team A
                        Column(
                          children: [
                            Text(
                              'קבוצה א',
                              style: PremiumTypography.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: state.teamAScore > 0
                                      ? () {
                                          final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
                                          notifier.updateScores(teamAScore: state.teamAScore - 1);
                                        }
                                      : null,
                                  color: PremiumColors.primary,
                                ),
                                Container(
                                  width: 60,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: PremiumColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${state.teamAScore}',
                                    textAlign: TextAlign.center,
                                    style: PremiumTypography.heading2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                      final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
                                      notifier.updateScores(teamAScore: state.teamAScore + 1);
                                    },
                                  color: PremiumColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                        // VS
                        Text(
                          'VS',
                          style: PremiumTypography.heading2.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                        ),
                        // Team B
                        Column(
                          children: [
                            Text(
                              'קבוצה ב',
                              style: PremiumTypography.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: state.teamBScore > 0
                                      ? () {
                                          final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
                                          notifier.updateScores(teamBScore: state.teamBScore - 1);
                                        }
                                      : null,
                                  color: PremiumColors.primary,
                                ),
                                Container(
                                  width: 60,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: PremiumColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${state.teamBScore}',
                                    textAlign: TextAlign.center,
                                    style: PremiumTypography.heading2,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                      final notifier = ref.read(logGameNotifierProvider(widget.hubId, widget.eventId).notifier);
                                      notifier.updateScores(teamBScore: state.teamBScore + 1);
                                    },
                                  color: PremiumColors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Attendance
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'נוכחות',
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.registeredPlayers.map((player) {
                      final isPresent = state.presentPlayers[player.uid] ?? false;
                      final isPaid = state.paidPlayers[player.uid] ?? false;
                      return CheckboxListTile(
                        value: isPresent,
                        onChanged: (value) => _togglePlayerPresence(player.uid),
                        title: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: PremiumTypography.bodyLarge,
                              ),
                            ),
                            // Payment toggle (only if hub has payment link)
                            if (state.hub?.paymentLink != null &&
                                state.hub!.paymentLink!.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  _togglePlayerPayment(player.uid);
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green : Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: Icon(
                                    isPaid ? Icons.check : Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        activeColor: PremiumColors.primary,
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Highlights (optional)
            PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'הישגים (אופציונלי)',
                      style: PremiumTypography.techHeadline.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.registeredPlayers
                        .where((p) => state.presentPlayers[p.uid] == true)
                        .map((player) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            PlayerAvatar(
                              user: player,
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                player.displayName ?? '',
                                style: PremiumTypography.bodyMedium,
                              ),
                            ),
                            // Goal tag
                            FilterChip(
                              label: const Text('שער'),
                              selected: _hasHighlight(player.uid, 'goal'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'goal'),
                              selectedColor: PremiumColors.primary
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // Assist tag
                            FilterChip(
                              label: const Text('אסיסט'),
                              selected: _hasHighlight(player.uid, 'assist'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'assist'),
                              selectedColor: PremiumColors.primary
                                  .withValues(alpha: 0.2),
                            ),
                            const SizedBox(width: 8),
                            // MVP tag
                            FilterChip(
                              label: const Text('MVP'),
                              selected: _hasHighlight(player.uid, 'mvp'),
                              onSelected: (selected) =>
                                  _toggleHighlight(player.uid, 'mvp'),
                              selectedColor:
                                  Colors.amber.withValues(alpha: 0.3),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting ? null : _submitGame,
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(state.isSubmitting ? 'שומר...' : 'סיים ורשום משחק'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Dialog for logging a match result (used in Session Mode)
class _LogMatchDialog extends StatefulWidget {
  final HubEvent event;

  const _LogMatchDialog({required this.event});

  @override
  State<_LogMatchDialog> createState() => _LogMatchDialogState();
}

class _LogMatchDialogState extends State<_LogMatchDialog> {
  String? _selectedTeamA;
  String? _selectedTeamB;
  int _scoreA = 0;
  int _scoreB = 0;

  @override
  void initState() {
    super.initState();
    if (widget.event.teams.isNotEmpty) {
      _selectedTeamA =
          widget.event.teams[0].color ?? widget.event.teams[0].name;
      if (widget.event.teams.length > 1) {
        _selectedTeamB =
            widget.event.teams[1].color ?? widget.event.teams[1].name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('רישום תוצאה'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team A selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTeamA,
              decoration: const InputDecoration(
                labelText: 'קבוצה א',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamA = value),
            ),
            const SizedBox(height: 16),
            // Team B selection
            DropdownButtonFormField<String>(
              initialValue: _selectedTeamB,
              decoration: const InputDecoration(
                labelText: 'קבוצה ב',
                border: OutlineInputBorder(),
              ),
              items: widget.event.teams.where((team) {
                final colorName = team.color ?? team.name;
                return colorName != _selectedTeamA;
              }).map((team) {
                final colorName = team.color ?? team.name;
                return DropdownMenuItem(
                  value: colorName,
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(team.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(colorName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedTeamB = value),
            ),
            const SizedBox(height: 24),
            // Score input
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Score A
                Column(
                  children: [
                    const Text('קבוצה א'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreA > 0
                              ? () => setState(() => _scoreA--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreA',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreA++),
                        ),
                      ],
                    ),
                  ],
                ),
                const Text('VS'),
                // Score B
                Column(
                  children: [
                    const Text('קבוצה ב'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _scoreB > 0
                              ? () => setState(() => _scoreB--)
                              : null,
                        ),
                        Container(
                          width: 60,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$_scoreB',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _scoreB++),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _selectedTeamA != null && _selectedTeamB != null
              ? () => Navigator.pop(
                    context,
                    {
                      'teamAColor': _selectedTeamA,
                      'teamBColor': _selectedTeamB,
                      'scoreA': _scoreA,
                      'scoreB': _scoreB,
                    },
                  )
              : null,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
