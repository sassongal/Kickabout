import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/core/providers/complex_providers.dart';
import 'package:kattrick/core/providers/auth_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/features/hubs/domain/services/hub_permissions_service.dart';
import 'package:kattrick/features/games/presentation/screens/session_controller.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/stopwatch_widget.dart';
import 'package:kattrick/widgets/session/rotation_queue_widget.dart';
import 'package:kattrick/widgets/session/pending_approvals_widget.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Game Session Screen - Winner Stays Format
///
/// Manages sessions with 2-8 teams where:
/// - 2 teams play at a time
/// - Winner stays, loser rotates out with waiting team
/// - Unlimited short matches
/// - Real-time stopwatch and score tracking
/// - Moderator approval workflow for tie-breaking
class GameSessionScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;

  const GameSessionScreen({
    super.key,
    required this.hubId,
    required this.eventId,
  });

  @override
  ConsumerState<GameSessionScreen> createState() => _GameSessionScreenState();
}

class _GameSessionScreenState extends ConsumerState<GameSessionScreen> {
  HubEvent? _event;
  Game? _game;
  bool _isLoading = true;
  StreamSubscription<Game?>? _gameSubscription;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() => _isLoading = true);

    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);

      if (event == null || event.gameId == null) {
        throw Exception('אירוע או משחק לא נמצא');
      }

      if (mounted) {
        setState(() {
          _event = event;
        });

        // Subscribe to real-time game updates
        _gameSubscription?.cancel();
        final gamesRepo = ref.read(gamesRepositoryProvider);
        _gameSubscription = gamesRepo.watchGame(event.gameId!).listen((game) {
          if (mounted) {
            setState(() {
              _game = game;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _startSession() async {
    if (_game == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      await sessionRepo.startSession(_game!.gameId, currentUserId);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הסשן התחיל!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _endSession() async {
    if (_game == null) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    // Confirm with user
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('סיום סשן'),
        content: const Text('האם אתה בטוח שברצונך לסיים את הסשן? כל הנתונים יישמרו.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.primary,
            ),
            child: const Text('סיים סשן'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      await sessionRepo.endSession(_game!.gameId, currentUserId);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הסשן הסתיים!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        title: 'משחק',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null || _game == null) {
      return AppScaffold(
        title: 'משחק',
        body: const Center(child: Text('משחק לא נמצא')),
      );
    }

    // Determine session phase
    final isActive = _game!.session.isActive;
    final hasEnded = _game!.session.sessionEndedAt != null;

    return AppScaffold(
      title: _event!.title,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phase 1: Setup (pre-session)
            if (!isActive && !hasEnded) ...[
              _buildSetupPhase(),
            ]
            // Phase 2: Active Session
            else if (isActive && !hasEnded) ...[
              _buildActiveSessionPhase(),
            ]
            // Phase 3: Summary (post-session)
            else ...[
              _buildSummaryPhase(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSetupPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: PremiumColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'הכנת סשן',
                        style: PremiumTypography.techHeadline.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'הקבוצות נוצרו ומוכנות למשחק. לחץ "התחל סשן" כדי להתחיל.',
                  style: PremiumTypography.bodyMedium.copyWith(
                    color: PremiumColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                // Show teams preview
                ...(_game!.teams.map((team) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(team.colorValue ?? 0xFF2196F3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          team.name,
                          style: PremiumTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${team.playerIds.length} שחקנים)',
                          style: PremiumTypography.bodySmall.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                })),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _startSession,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('התחל סשן'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: PremiumColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveSessionPhase() {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return const SizedBox.shrink();

    // Check permissions - for public games, creator is manager, for hub games check hub permissions
    if (_game!.hubId != null) {
      // Hub game - check hub permissions via hubStreamProvider
      final hubAsync = ref.watch(hubStreamProvider(_game!.hubId!));

      return hubAsync.when(
        data: (hub) {
          bool isManager = false;
          bool isModerator = false;

          if (hub != null) {
            final permissions = HubPermissions(hub: hub, userId: currentUserId);
            isManager = permissions.isManager;
            isModerator = permissions.isModerator;
          }

          if (!isManager && !isModerator) {
            return PremiumCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'רק מנהלי משחק יכולים לנהל את הסשן',
                  style: PremiumTypography.bodyMedium.copyWith(
                    color: PremiumColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return _buildActiveSessionContent(currentUserId, isManager, isModerator);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'שגיאה בטעינת הנתונים',
              style: PremiumTypography.bodyMedium.copyWith(
                color: PremiumColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    } else {
      // Public game - creator is manager
      final isManager = _game!.createdBy == currentUserId;

      if (!isManager) {
        return PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'רק מנהלי משחק יכולים לנהל את הסשן',
              style: PremiumTypography.bodyMedium.copyWith(
                color: PremiumColors.textSecondary,
              ),
            ),
          ),
        );
      }

      return _buildActiveSessionContent(currentUserId, isManager, false);
    }
  }

  Widget _buildActiveSessionContent(
    String currentUserId,
    bool isManager,
    bool isModerator,
  ) {
    // Use SessionController
    final sessionController = ref.watch(sessionControllerProvider(_game!.gameId).notifier);
    final sessionState = ref.watch(sessionControllerProvider(_game!.gameId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Aggregate Wins Scoreboard
        _buildAggregateScoreboard(),
        const SizedBox(height: 16),

        // Rotation Queue
        RotationQueueWidget(
          currentRotation: _game!.session.currentRotation,
          teams: _game!.teams,
        ),
        const SizedBox(height: 16),

        // Pending Approvals (Manager only)
        if (isManager) ...[
          StreamBuilder<List<MatchResult>>(
            stream: ref.read(matchApprovalRepositoryProvider).watchPendingMatches(_game!.gameId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final matches = snapshot.data!;
              return PendingApprovalsWidget(
                pendingMatches: matches,
                teams: _game!.teams,
                onApprove: (matchId) async {
                  try {
                    await ref.read(matchApprovalRepositoryProvider).approveMatch(
                          _game!.gameId,
                          matchId,
                          currentUserId,
                        );
                    if (mounted) {
                      SnackbarHelper.showSuccess(context, 'תוצאה אושרה!');
                    }
                  } catch (e) {
                    if (mounted) {
                      SnackbarHelper.showErrorFromException(context, e);
                    }
                  }
                },
                onReject: (matchId, reason) async {
                  try {
                    await ref.read(matchApprovalRepositoryProvider).rejectMatch(
                          _game!.gameId,
                          matchId,
                          currentUserId,
                          reason,
                        );
                    if (mounted) {
                      SnackbarHelper.showSuccess(context, 'תוצאה נדחתה');
                    }
                  } catch (e) {
                    if (mounted) {
                      SnackbarHelper.showErrorFromException(context, e);
                    }
                  }
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Stopwatch
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StopwatchWidget(
              stopwatch: sessionController.stopwatch,
              accentColor: PremiumColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Current Match Scoring
        if (_game!.session.currentRotation != null) ...[
          _buildCurrentMatchScoring(
            sessionController,
            sessionState,
            currentUserId,
            isManager,
            isModerator,
          ),
        ],
        const SizedBox(height: 16),

        // End Session Button (Manager only)
        if (isManager) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _endSession,
              icon: const Icon(Icons.stop),
              label: const Text('סיים סשן'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Recent Matches
        _buildRecentMatches(),
      ],
    );
  }

  Widget _buildCurrentMatchScoring(
    SessionController controller,
    SessionState state,
    String currentUserId,
    bool isManager,
    bool isModerator,
  ) {
    final rotation = _game!.session.currentRotation;
    if (rotation == null) return const SizedBox.shrink();

    // Find teams
    final teamA = _game!.teams.firstWhere(
      (t) => (t.color ?? t.name) == rotation.teamAColor,
      orElse: () => _game!.teams.first,
    );
    final teamB = _game!.teams.firstWhere(
      (t) => (t.color ?? t.name) == rotation.teamBColor,
      orElse: () => _game!.teams.first,
    );

    // Initialize scores if needed
    if (!state.currentScores.containsKey(rotation.teamAColor) ||
        !state.currentScores.containsKey(rotation.teamBColor)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.resetScores(rotation.teamAColor, rotation.teamBColor);
      });
    }

    final scoreA = state.currentScores[rotation.teamAColor] ?? 0;
    final scoreB = state.currentScores[rotation.teamBColor] ?? 0;

    // Show tie selection dialog if needed
    if (state.showTieDialog && state.pendingTieMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showTieSelectionDialog(controller, state.pendingTieMatch!, currentUserId);
      });
    }

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'משחק נוכחי',
              style: PremiumTypography.techHeadline.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Team A
                _buildTeamScore(teamA, scoreA, rotation.teamAColor, controller),
                Text(
                  'VS',
                  style: PremiumTypography.heading1.copyWith(
                    color: PremiumColors.textSecondary,
                  ),
                ),
                // Team B
                _buildTeamScore(teamB, scoreB, rotation.teamBColor, controller),
              ],
            ),
            const SizedBox(height: 24),

            // Error message
            if (state.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: PremiumTypography.bodySmall.copyWith(
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: controller.clearError,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Finish Match Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isSubmitting
                    ? null
                    : () => controller.finishMatch(
                          game: _game!,
                          currentUserId: currentUserId,
                          isManager: isManager,
                          isModerator: isModerator,
                          asModeratorRequest: !isManager && isModerator,
                        ),
                icon: state.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  state.isSubmitting
                      ? 'שומר...'
                      : (!isManager && isModerator)
                          ? 'שלח לאישור מנהל'
                          : 'סיום משחק',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTieSelectionDialog(
    SessionController controller,
    MatchResult tieMatch,
    String currentUserId,
  ) async {
    final selectedTeam = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('תיקו - בחר קבוצה שנשארת'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'המשחק הסתיים בתיקו. בחר איזו קבוצה תישאר על המגרש:',
              style: PremiumTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Team A Option
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(
                    _game!.teams
                            .firstWhere(
                              (t) => (t.color ?? t.name) == tieMatch.teamAColor,
                              orElse: () => _game!.teams.first,
                            )
                            .colorValue ??
                        0xFF2196F3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(tieMatch.teamAColor),
              onTap: () => Navigator.pop(context, tieMatch.teamAColor),
            ),
            // Team B Option
            ListTile(
              leading: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(
                    _game!.teams
                            .firstWhere(
                              (t) => (t.color ?? t.name) == tieMatch.teamBColor,
                              orElse: () => _game!.teams.first,
                            )
                            .colorValue ??
                        0xFF2196F3,
                  ),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(tieMatch.teamBColor),
              onTap: () => Navigator.pop(context, tieMatch.teamBColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.cancelTieSelection();
              Navigator.pop(context);
            },
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (selectedTeam != null) {
      await controller.selectStayingTeam(selectedTeam, _game!, currentUserId);
      if (mounted) {
        SnackbarHelper.showSuccess(context, 'תוצאה נרשמה!');
      }
    } else {
      controller.cancelTieSelection();
    }
  }

  Widget _buildTeamScore(
    Team team,
    int score,
    String teamColor,
    SessionController controller,
  ) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Color(team.colorValue ?? 0xFF2196F3),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team.name,
          style: PremiumTypography.bodyLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$score',
          style: PremiumTypography.heading1.copyWith(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decrement button
            IconButton(
              onPressed: score > 0 ? () => controller.decrementScore(teamColor) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: Colors.grey,
            ),
            // Increment button
            ElevatedButton.icon(
              onPressed: () => controller.incrementScore(teamColor),
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('גול'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(team.colorValue ?? 0xFF2196F3),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAggregateScoreboard() {
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ניצחונות מצטברים',
              style: PremiumTypography.techHeadline.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...(_game!.teams.map((team) {
              final wins =
                  _game!.session.aggregateWins[team.color ?? team.name] ?? 0;
              final colorValue = team.colorValue ?? 0xFF2196F3;
              final maxWins = _game!.session.aggregateWins.values.isEmpty
                  ? 1
                  : _game!.session.aggregateWins.values
                      .reduce((a, b) => a > b ? a : b);
              final percentage = maxWins > 0 ? (wins / maxWins) : 0.0;
              final isKing = wins > 0 && wins == maxWins;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Color(colorValue),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              team.name,
                              style: PremiumTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isKing) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '$wins',
                          style: PremiumTypography.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Color(colorValue),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(Color(colorValue)),
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMatches() {
    if (_game!.session.matches.isEmpty) return const SizedBox.shrink();

    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'משחקים אחרונים (${_game!.session.matches.where((m) => m.approvalStatus == MatchApprovalStatus.approved).length})',
              style: PremiumTypography.techHeadline.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ...(_game!.session.matches.reversed.take(5).map((match) {
              final teamAColor = _game!.teams
                  .firstWhere(
                    (t) => (t.color ?? t.name) == match.teamAColor,
                    orElse: () => _game!.teams.first,
                  )
                  .colorValue;
              final teamBColor = _game!.teams
                  .firstWhere(
                    (t) => (t.color ?? t.name) == match.teamBColor,
                    orElse: () => _game!.teams.first,
                  )
                  .colorValue;

              final isPending = match.approvalStatus == MatchApprovalStatus.pending;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange[50] : null,
                  borderRadius: BorderRadius.circular(8),
                  border: isPending
                      ? Border.all(color: Colors.orange[200]!)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(teamAColor ?? 0xFF2196F3),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(match.teamAColor),
                        const SizedBox(width: 8),
                        Text(
                          '${match.scoreA}',
                          style: PremiumTypography.heading2,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          'VS',
                          style: PremiumTypography.bodyMedium.copyWith(
                            color: PremiumColors.textSecondary,
                          ),
                        ),
                        if (isPending)
                          Text(
                            'ממתין',
                            style: PremiumTypography.bodySmall.copyWith(
                              color: Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          '${match.scoreB}',
                          style: PremiumTypography.heading2,
                        ),
                        const SizedBox(width: 8),
                        Text(match.teamBColor),
                        const SizedBox(width: 8),
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Color(teamBColor ?? 0xFF2196F3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            })),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPhase() {
    final approvedMatches = _game!.session.matches
        .where((m) => m.approvalStatus == MatchApprovalStatus.approved)
        .toList();

    // Find King of the Pitch
    final maxWins = _game!.session.aggregateWins.values.isEmpty
        ? 0
        : _game!.session.aggregateWins.values.reduce((a, b) => a > b ? a : b);

    final kingTeam = maxWins > 0
        ? _game!.teams.firstWhere(
            (t) =>
                (_game!.session.aggregateWins[t.color ?? t.name] ?? 0) ==
                maxWins,
            orElse: () => _game!.teams.first,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Session Complete Banner
        PremiumCard(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PremiumColors.primary.withValues(alpha: 0.1),
                  PremiumColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Colors.amber,
                ),
                const SizedBox(height: 12),
                Text(
                  'הסשן הסתיים!',
                  style: PremiumTypography.heading1.copyWith(fontSize: 24),
                ),
                if (kingTeam != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(kingTeam.colorValue ?? 0xFF2196F3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${kingTeam.name} - King of the Pitch!',
                        style: PremiumTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Final Standings
        _buildAggregateScoreboard(),
        const SizedBox(height: 16),

        // Session Stats
        PremiumCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'סטטיסטיקות סשן',
                  style: PremiumTypography.techHeadline.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard(
                      'משחקים',
                      '${approvedMatches.length}',
                      Icons.sports_soccer,
                    ),
                    _buildStatCard(
                      'קבוצות',
                      '${_game!.teams.length}',
                      Icons.groups,
                    ),
                    _buildStatCard(
                      'שחקנים',
                      '${_game!.teams.fold<int>(0, (sum, team) => sum + team.playerIds.length)}',
                      Icons.person,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // All Matches
        _buildRecentMatches(),
        const SizedBox(height: 24),

        // Back Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('חזרה למרכז'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: PremiumColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: PremiumColors.primary, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: PremiumTypography.heading1.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: PremiumTypography.bodySmall.copyWith(
            color: PremiumColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
