import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/games/domain/models/team_maker.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Result screen showing generated teams with balance metrics
/// Allows drag-and-drop editing and saving to the event
class TeamGeneratorResultScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String eventId;
  final List<PlayerForTeam> players;
  final int teamCount;

  const TeamGeneratorResultScreen({
    super.key,
    required this.hubId,
    required this.eventId,
    required this.players,
    required this.teamCount,
  });

  @override
  ConsumerState<TeamGeneratorResultScreen> createState() =>
      _TeamGeneratorResultScreenState();
}

class _TeamGeneratorResultScreenState
    extends ConsumerState<TeamGeneratorResultScreen> {
  late List<Team> _teams;
  late double _balanceScore;
  bool _isSaving = false;
  bool _teamsSaved = false; // Track if teams have been saved
  bool _isCreatingGame = false; // Track game creation state
  HubEvent? _event; // Store event for game creation
  Map<String, User> _usersMap = {};
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _generateTeams();
    _loadUsers();
    _loadEvent();
  }

  void _generateTeams() {
    final result = TeamMaker.createBalancedTeams(
      widget.players,
      teamCount: widget.teamCount,
    );
    setState(() {
      _teams = result.teams;
      _balanceScore = result.balanceScore;
    });
  }

  Future<void> _loadUsers() async {
    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final userIds = widget.players.map((p) => p.uid).toList();
      final users = await usersRepo.getUsers(userIds);

      if (mounted) {
        setState(() {
          _usersMap = {for (var user in users) user.uid: user};
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
        SnackbarHelper.showErrorFromException(context, e);
      }
    }
  }

  Future<void> _loadEvent() async {
    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final event = await eventsRepo.getHubEvent(widget.hubId, widget.eventId);
      if (mounted) {
        setState(() => _event = event);
      }
    } catch (e) {
      // Silently fail - not critical for team generation
      debugPrint('Failed to load event: $e');
    }
  }

  void _movePlayer(String playerId, int fromTeamIndex, int toTeamIndex) {
    if (fromTeamIndex == toTeamIndex) return;

    setState(() {
      final fromTeam = _teams[fromTeamIndex];
      final toTeam = _teams[toTeamIndex];

      // Find player rating
      final player = widget.players.firstWhere((p) => p.uid == playerId);

      // Remove from source team
      final newFromPlayerIds = List<String>.from(fromTeam.playerIds)
        ..remove(playerId);
      final newFromScore = fromTeam.totalScore - player.rating;

      // Add to destination team
      final newToPlayerIds = List<String>.from(toTeam.playerIds)..add(playerId);
      final newToScore = toTeam.totalScore + player.rating;

      // Update teams
      _teams[fromTeamIndex] = fromTeam.copyWith(
        playerIds: newFromPlayerIds,
        totalScore: newFromScore,
      );
      _teams[toTeamIndex] = toTeam.copyWith(
        playerIds: newToPlayerIds,
        totalScore: newToScore,
      );

      // Recalculate balance score
      final metrics = TeamMaker.calculateBalanceMetrics(_teams);
      _balanceScore = (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0) * 100;
    });
  }

  Future<void> _saveTeams() async {
    setState(() => _isSaving = true);

    try {
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      // Update event with teams and set status to 'active' (ready to start)
      await eventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'teams': _teams.map((t) => t.toJson()).toList(),
          'status': 'active', // Mark as active (teams ready, waiting to start)
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Send notifications to registered players
      if (_event != null && currentUserId != null) {
        await _notifyPlayersTeamsReady();
      }

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'הכוחות נשמרו בהצלחה!');
        setState(() => _teamsSaved = true); // Enable "Open Game" button
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Send push notifications to all registered players that teams are ready
  /// 
  /// Note: The actual notification sending should be done via Cloud Function
  /// triggered by the event status change. This method just sets a flag
  /// that the Cloud Function can check.
  Future<void> _notifyPlayersTeamsReady() async {
    if (_event == null) return;

    try {
      // Set a flag that teams are ready - Cloud Function will pick this up
      // and send notifications to all registered players
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      await eventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'teamsReadyAt': FieldValue.serverTimestamp(),
          'shouldNotifyTeamsReady': true,
        },
      );
      
      // Note: Cloud Function should listen to events with teamsReadyAt != null
      // and send notifications to registeredPlayerIds
    } catch (e) {
      // Don't fail the save operation if notification flag fails
      debugPrint('Failed to set teams ready notification flag: $e');
    }
  }

  Future<void> _createSessionGame() async {
    if (_event == null) {
      SnackbarHelper.showError(context, 'לא ניתן ליצור משחק - אירוע לא נמצא');
      return;
    }

    setState(() => _isCreatingGame = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final eventsRepo = ref.read(hubEventsRepositoryProvider);
      final currentUserId = ref.read(currentUserIdProvider);

      if (currentUserId == null) {
        throw Exception('משתמש לא מחובר');
      }

      // 1. Create Game document
      final gameId = gamesRepo.generateGameId();

      final game = Game(
        gameId: gameId,
        createdBy: currentUserId,
        hubId: widget.hubId,
        eventId: widget.eventId,
        gameDate: _event!.eventDate,
        location: _event!.location,
        locationPoint: _event!.locationPoint,
        teamCount: 3, // Always 3 teams for Winner Stays
        status: GameStatus.inProgress,
        teams: _teams, // Copy 3 teams to game
        session: const GameSession(
          matches: [], // Empty initially
          aggregateWins: {},
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await gamesRepo.createGame(game);

      // 2. Update Event with gameId reference and mark as started
      await eventsRepo.updateHubEvent(
        widget.hubId,
        widget.eventId,
        {
          'gameId': gameId,
          'isStarted': true,
          'startedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'משחק נפתח בהצלחה!');
        // Navigate to Game Session screen
        context
            .go('/hubs/${widget.hubId}/events/${widget.eventId}/game-session');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingGame = false);
      }
    }
  }

  bool _checkGameCreationPermission(Hub? hub) {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || hub == null) return false;

    // Check if user is manager (creator)
    if (hub.createdBy == currentUserId) return true;

    // Check if moderators are allowed and user is moderator
    final allowModerators =
        hub.settings.allowModeratorsToCreateGames;

    if (allowModerators) {
      // For now, simplified check - in production, fetch HubMember to verify role
      // This will be refined when we integrate with HubPermissions
      return true; // Allow if setting is enabled
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Fetch hub to check permissions
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    return FutureBuilder<Hub?>(
      future: hubsRepo.getHub(widget.hubId),
      builder: (context, hubSnapshot) {
        final hub = hubSnapshot.data;
        final hasPermission = _checkGameCreationPermission(hub);

        return AppScaffold(
          title: 'תוצאות מחולל הכוחות',
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Score Card
                      PremiumCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'ניקוד איזון',
                                style: PremiumTypography.techHeadline
                                    .copyWith(fontSize: 16),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _balanceScore.toStringAsFixed(1),
                                    style:
                                        PremiumTypography.heading1.copyWith(
                                      fontSize: 48,
                                      color: _getBalanceColor(_balanceScore),
                                    ),
                                  ),
                                  Text(
                                    '/100',
                                    style:
                                        PremiumTypography.heading2.copyWith(
                                      color: PremiumColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: _balanceScore / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getBalanceColor(_balanceScore),
                                ),
                                minHeight: 8,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getBalanceMessage(_balanceScore),
                                style: PremiumTypography.bodySmall.copyWith(
                                  color: PremiumColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Instructions
                      PremiumCard(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: PremiumColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'לחץ על שחקן להעברה בין קבוצות',
                                  style: PremiumTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Teams
                      ..._teams.asMap().entries.map((entry) {
                        final teamIndex = entry.key;
                        final team = entry.value;
                        final avgRating = team.playerIds.isEmpty
                            ? 0.0
                            : team.totalScore / team.playerIds.length;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PremiumCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Team header
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          if (team.colorValue != null)
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Color(team.colorValue!),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(width: 12),
                                          Text(
                                            team.name,
                                            style:
                                                PremiumTypography.heading2,
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${team.playerIds.length} שחקנים',
                                            style: PremiumTypography
                                                .bodySmall
                                                .copyWith(
                                              color: PremiumColors
                                                  .textSecondary,
                                            ),
                                          ),
                                          Text(
                                            'ממוצע: ${avgRating.toStringAsFixed(2)}',
                                            style: PremiumTypography
                                                .bodyMedium
                                                .copyWith(
                                              color: PremiumColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Players
                                  if (_isLoadingUsers)
                                    const Center(
                                        child: CircularProgressIndicator())
                                  else
                                    ...team.playerIds.map((playerId) {
                                      final user = _usersMap[playerId];
                                      final player = widget.players
                                          .firstWhere((p) => p.uid == playerId);

                                      if (user == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: InkWell(
                                          onTap: () => _showMoveDialog(
                                              playerId, teamIndex),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color:
                                                  PremiumColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: PremiumColors
                                                    .surfaceVariant,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                PlayerAvatar(
                                                  user: user,
                                                  size: AvatarSize.sm,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    user.name,
                                                    style: PremiumTypography
                                                        .bodyMedium,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: PremiumColors
                                                        .primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  child: Text(
                                                    player.rating
                                                        .toStringAsFixed(1),
                                                    style: PremiumTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(
                                                  Icons.drag_indicator,
                                                  color: PremiumColors
                                                      .textSecondary,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Save buttons at bottom
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: PremiumColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Save Teams button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving || _teamsSaved ? null : _saveTeams,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(_teamsSaved ? Icons.check : Icons.save),
                        label: Text(_isSaving
                            ? 'שומר...'
                            : _teamsSaved
                                ? 'הכוחות נשמרו'
                                : 'שמור כוחות לאירוע'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _teamsSaved
                              ? Colors.green
                              : PremiumColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    // Open Game button (shown after teams saved)
                    if (_teamsSaved && hasPermission) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isCreatingGame ? null : _createSessionGame,
                          icon: _isCreatingGame
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                              _isCreatingGame ? 'יוצר משחק...' : 'פתח משחק'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMoveDialog(String playerId, int currentTeamIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('העבר שחקן'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _teams.asMap().entries.map((entry) {
            final teamIndex = entry.key;
            final team = entry.value;
            final isCurrent = teamIndex == currentTeamIndex;

            return ListTile(
              leading: team.colorValue != null
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(team.colorValue!),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              title: Text(team.name),
              subtitle: Text('${team.playerIds.length} שחקנים'),
              trailing: isCurrent ? const Icon(Icons.check) : null,
              enabled: !isCurrent,
              onTap: () {
                _movePlayer(playerId, currentTeamIndex, teamIndex);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );
  }

  Color _getBalanceColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getBalanceMessage(double score) {
    if (score >= 90) return 'איזון מושלם! 🎯';
    if (score >= 80) return 'איזון מצוין 👍';
    if (score >= 70) return 'איזון טוב';
    if (score >= 60) return 'איזון סביר';
    return 'כדאי לבצע התאמות';
  }
}
