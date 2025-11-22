import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/models/hub_role.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/ui/team_builder/team_builder_page_with_tabs.dart';

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
    if (isEvent) {
      return _buildForEvent(context, ref);
    } else {
      return _buildForGame(context, ref);
    }
  }

  Widget _buildForEvent(BuildContext context, WidgetRef ref) {
    if (hubId == null) {
      return AppScaffold(
        title: 'יצירת קבוצות',
        body: const Center(child: Text('שגיאה: hubId חסר')),
      );
    }

    final hubEventsRepo = ref.watch(hubEventsRepositoryProvider);
    // Get single event by ID - use FutureBuilder for single event

    return AppScaffold(
      title: 'יצירת קבוצות',
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
                  Text('שגיאה: ${eventSnapshot.error}'),
                ],
              ),
            );
          }

          final event = eventSnapshot.data;
          if (event == null) {
            return const Center(child: Text('אירוע לא נמצא'));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(hubId!));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('יצירת קבוצות'),
                  ),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'אין לך הרשאת ניהול למסך זה',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'רק מנהלי Hub יכולים ליצור קבוצות',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Use registered players from event
              final registeredPlayerIds = event.registeredPlayerIds;

              if (registeredPlayerIds.length < event.teamCount * AppConstants.minPlayersPerTeam) {
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
                        'אין מספיק נרשמים',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'נדרשים לפחות ${event.teamCount * AppConstants.minPlayersPerTeam} שחקנים',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'נרשמו: ${registeredPlayerIds.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }

              // Create a temporary Game object for TeamBuilderPageWithTabs
              // (it needs Game for some properties, but we'll handle saving differently)
              final tempGame = Game(
                gameId: gameId,
                createdBy: event.createdBy,
                hubId: hubId!,
                eventId: gameId, // Mark as event
                gameDate: event.eventDate,
                teamCount: event.teamCount,
                status: GameStatus.teamSelection,
                createdAt: event.createdAt,
                updatedAt: event.updatedAt,
                teams: event.teams, // Use teams from event if they exist
              );

              // Create empty signups list (not used for events)
              final emptySignups = <GameSignup>[];

              return TeamBuilderPageWithTabs(
                gameId: gameId,
                game: tempGame,
                teamCount: event.teamCount,
                playerIds: registeredPlayerIds,
                signups: emptySignups,
                isEvent: true,
                eventId: gameId,
                hubId: hubId!,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('שגיאה בבדיקת הרשאות: $error'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForGame(BuildContext context, WidgetRef ref) {
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final signupsRepo = ref.watch(signupsRepositoryProvider);

    final gameStream = gamesRepo.watchGame(gameId);
    final signupsStream = signupsRepo.watchSignups(gameId);

    return AppScaffold(
      title: 'יצירת קבוצות',
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
                  Text('שגיאה: ${gameSnapshot.error}'),
                ],
              ),
            );
          }

          final game = gameSnapshot.data;
          if (game == null) {
            return const Center(child: Text('משחק לא נמצא'));
          }

          // Check admin permissions
          final roleAsync = ref.watch(hubRoleProvider(game.hubId));
          return roleAsync.when(
            data: (role) {
              if (role != UserRole.admin) {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('יצירת קבוצות'),
                  ),
                  body: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, size: 64, color: Colors.orange),
                        SizedBox(height: 16),
                        Text(
                          'אין לך הרשאת ניהול למסך זה',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'רק מנהלי Hub יכולים ליצור קבוצות',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return StreamBuilder<List<GameSignup>>(
                stream: signupsStream,
                builder: (context, signupsSnapshot) {
                  if (signupsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final signups = signupsSnapshot.data ?? [];
                  final confirmedPlayerIds = signups
                      .where((s) => s.status == SignupStatus.confirmed)
                      .map((s) => s.playerId)
                      .toList();

                  if (confirmedPlayerIds.length < game.teamCount * AppConstants.minPlayersPerTeam) {
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
                            'אין מספיק נרשמים',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'נדרשים לפחות ${game.teamCount * AppConstants.minPlayersPerTeam} שחקנים',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'נרשמו: ${confirmedPlayerIds.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }

                  return TeamBuilderPageWithTabs(
                    gameId: gameId,
                    game: game,
                    teamCount: game.teamCount,
                    playerIds: confirmedPlayerIds,
                    signups: signups,
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
                  Text('שגיאה בבדיקת הרשאות: $error'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
