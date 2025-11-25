import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/l10n/app_localizations.dart';
import 'package:kickadoor/logic/team_maker.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/widgets/player_avatar.dart';

/// Team maker screen - works with both Games and Events
class TeamMakerScreen extends ConsumerWidget {
  final String gameId; // Can be gameId or eventId
  final bool isEvent; // If true, gameId is actually an eventId
  final String? hubId; // Required if isEvent == true

  const TeamMakerScreen({
    super.key,
    required this.gameId,
    this.isEvent = false,
    this.hubId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (isEvent) {
      return _buildForEvent(context, ref, l10n);
    } else {
      return _buildForGame(context, ref, l10n);
    }
  }

  Widget _buildForEvent(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    if (hubId == null) {
      return AppScaffold(
        title: l10n.teamFormation,
        body: Center(child: Text(l10n.errorMissingHubId)),
      );
    }

    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);
    // Get single event by ID - use FutureBuilder for single event

    return AppScaffold(
      title: l10n.teamFormation,
      body: FutureBuilder<HubEvent?>(
        future: hubEventsRepo.getHubEvent(hubId!, gameId),
        builder: (context, eventSnapshot) {
          if (eventSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (eventSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${eventSnapshot.error}'),
                ],
              ),
            );
          }

          final event = eventSnapshot.data;
          if (event == null) {
            return Center(child: Text(l10n.eventNotFound));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(hubId!));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(l10n.teamFormation),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAdminPermissionForScreen,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.onlyHubAdminsCanCreateTeams,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Use registered players from event
              final registeredPlayerIds = event.registeredPlayerIds;

              if (registeredPlayerIds.length <
                  event.teamCount * AppConstants.minPlayersPerTeam) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.notEnoughRegisteredPlayers,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.requiredPlayersCount(
                            event.teamCount * AppConstants.minPlayersPerTeam),
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.registeredPlayerCount(registeredPlayerIds.length),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              // Pass initial data to the new TeamBuilderDashboard
              return TeamBuilderDashboard(
                playerIds: registeredPlayerIds,
                teamCount: event.teamCount,
                hubId: hubId!,
                isEvent: true,
                eventId: gameId,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.permissionCheckErrorDetails(error.toString())),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForGame(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final signupsRepo = ref.watch(signupsRepositoryProvider);

    final gameStream = gamesRepo.watchGame(gameId);
    final signupsStream = signupsRepo.watchSignups(gameId);

    return AppScaffold(
      title: l10n.teamFormation,
      body: StreamBuilder<Game?>(
        stream: gameStream,
        builder: (context, gameSnapshot) {
          if (gameSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (gameSnapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${gameSnapshot.error}'),
                ],
              ),
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return Center(child: Text(l10n.gameNotFound));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(game.hubId));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text(l10n.teamFormation),
                  ),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noAdminPermissionForScreen,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.onlyHubAdminsCanCreateTeams,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return StreamBuilder<List<GameSignup>>(
                stream: signupsStream,
                builder: (context, signupsSnapshot) {
                  if (signupsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final signups = signupsSnapshot.data ?? [];
                  final confirmedPlayerIds = signups
                      .where((s) => s.status == SignupStatus.confirmed)
                      .map((s) => s.playerId)
                      .toList();

                  if (confirmedPlayerIds.length <
                      game.teamCount * AppConstants.minPlayersPerTeam) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 64,
                            color: Colors.orange,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.notEnoughRegisteredPlayers,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.requiredPlayersCount(game.teamCount *
                                AppConstants.minPlayersPerTeam),
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.registeredPlayerCount(
                                confirmedPlayerIds.length),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return TeamBuilderDashboard(
                    playerIds: confirmedPlayerIds,
                    teamCount: game.teamCount,
                    hubId: game.hubId,
                    isEvent: false,
                    gameId: game.gameId,
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.permissionCheckErrorDetails(error.toString())),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A stateful widget that provides a full dashboard for team creation and manual adjustment.
class TeamBuilderDashboard extends ConsumerStatefulWidget {
  final List<String> playerIds;
  final int teamCount;
  final String hubId;
  final bool isEvent;
  final String? eventId;
  final String? gameId;

  const TeamBuilderDashboard({
    super.key,
    required this.playerIds,
    required this.teamCount,
    required this.hubId,
    required this.isEvent,
    this.eventId,
    this.gameId,
  });

  @override
  ConsumerState<TeamBuilderDashboard> createState() =>
      _TeamBuilderDashboardState();
}

class _TeamBuilderDashboardState extends ConsumerState<TeamBuilderDashboard> {
  late Future<List<PlayerForTeam>> _playersFuture;
  List<Team> _teams = [];
  final Map<String, User> _userMap = {};
  double _balanceScore = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _playersFuture = _fetchPlayers();
    _playersFuture.then((players) {
      _generateTeams(players);
    });
  }

  Future<List<PlayerForTeam>> _fetchPlayers() async {
    final usersRepo = ref.read(usersRepositoryProvider);
    final hub = await ref.read(hubsRepositoryProvider).getHub(widget.hubId);
    final managerRatings = hub?.managerRatings ?? {};

    final userFutures =
        widget.playerIds.map((id) => usersRepo.getUser(id)).toList();
    final users = await Future.wait(userFutures);
    final validUsers = users.whereType<User>().toList();

    // Populate user map
    for (var user in validUsers) {
      _userMap[user.uid] = user;
    }

    return validUsers
        .map((user) => PlayerForTeam.fromUser(user,
            hubId: widget.hubId, managerRatings: managerRatings))
        .toList();
  }

  void _generateTeams(List<PlayerForTeam> players) {
    final result = TeamMaker.createBalancedTeams(
      players,
      teamCount: widget.teamCount,
    );
    setState(() {
      _teams = result.teams;
      _balanceScore = result.balanceScore;
      _isLoading = false;
    });
  }

  void _movePlayer(String playerId, String fromTeamId, String toTeamId) async {
    final allPlayers = await _playersFuture;
    final playerToMove = allPlayers.firstWhere((p) => p.uid == playerId);

    setState(() {
      // Remove from old team
      final fromTeam = _teams.firstWhere((t) => t.teamId == fromTeamId);
      final updatedFromPlayerIds =
          fromTeam.playerIds.where((id) => id != playerId).toList();
      final updatedFromTeam = fromTeam.copyWith(
        playerIds: updatedFromPlayerIds,
        totalScore: fromTeam.totalScore - playerToMove.rating,
      );

      // Add to new team
      final toTeam = _teams.firstWhere((t) => t.teamId == toTeamId);
      final updatedToPlayerIds = [...toTeam.playerIds, playerId];
      final updatedToTeam = toTeam.copyWith(
        playerIds: updatedToPlayerIds,
        totalScore: toTeam.totalScore + playerToMove.rating,
      );

      // Update teams list
      _teams = _teams.map((team) {
        if (team.teamId == fromTeamId) return updatedFromTeam;
        if (team.teamId == toTeamId) return updatedToTeam;
        return team;
      }).toList();

      // Recalculate balance score
      final metrics = TeamMaker.calculateBalanceMetrics(_teams);
      _balanceScore = (1.0 - (metrics.stddev / 5.0)).clamp(0.0, 1.0) * 100.0;
    });
  }

  void _showMovePlayerDialog(
      String playerId, String currentTeamId, List<PlayerForTeam> allPlayers) {
    final l10n = AppLocalizations.of(context)!;
    final playerName = allPlayers.firstWhere((p) => p.uid == playerId).uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Move $playerName'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _teams
                  .where((team) => team.teamId != currentTeamId)
                  .map((targetTeam) {
                return ListTile(
                  title: Text('Move to ${targetTeam.name}'),
                  tileColor:
                      _getColorForTeam(targetTeam.color).withValues(alpha: 0.2),
                  onTap: () {
                    _movePlayer(playerId, currentTeamId, targetTeam.teamId);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  Color _getColorForTeam(String? colorName) {
    switch (colorName) {
      case 'Red':
        return Colors.red.shade300;
      case 'Blue':
        return Colors.blue.shade300;
      case 'Yellow':
        return Colors.yellow.shade400;
      case 'Green':
        return Colors.green.shade300;
      case 'Orange':
        return Colors.orange.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.teamFormation,
      body: FutureBuilder<List<PlayerForTeam>>(
        future: _playersFuture,
        builder: (context, snapshot) {
          if (_isLoading || !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allPlayers = snapshot.data!;

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(
                      label: Text(
                          'Quality: ${_balanceScore.toStringAsFixed(0)}/100'),
                      backgroundColor: Colors.teal.withValues(alpha: 0.1),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _generateTeams(allPlayers),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                    ),
                  ],
                ),
              ),
              // Team Columns
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    final teamColor = _getColorForTeam(team.color);
                    final teamPlayers = team.playerIds
                        .map(
                            (pid) => allPlayers.firstWhere((p) => p.uid == pid))
                        .toList();
                    final hasGoalkeeper =
                        teamPlayers.any((p) => p.isGoalkeeper);

                    return Container(
                      width: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        elevation: 2,
                        child: Column(
                          children: [
                            // Team Header
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              color: teamColor,
                              child: Text(
                                team.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Player List
                            Expanded(
                              child: ListView.builder(
                                itemCount: teamPlayers.length,
                                itemBuilder: (context, pIndex) {
                                  final player = teamPlayers[pIndex];
                                  return ListTile(
                                    leading: PlayerAvatar(
                                      user: _userMap[player.uid]!,
                                      radius: 18,
                                    ),
                                    title: Text(_userMap[player.uid]?.name ??
                                        player.uid.substring(0, 6)),
                                    subtitle:
                                        Text(player.rating.toStringAsFixed(1)),
                                    trailing: player.isGoalkeeper
                                        ? const Icon(Icons.sports_soccer,
                                            color: Colors.black)
                                        : null,
                                    onTap: () => _showMovePlayerDialog(
                                        player.uid, team.teamId, allPlayers),
                                  );
                                },
                              ),
                            ),
                            if (!hasGoalkeeper)
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.no_accounts,
                                    color: Colors.grey,
                                    semanticLabel: 'No Goalkeeper'),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
