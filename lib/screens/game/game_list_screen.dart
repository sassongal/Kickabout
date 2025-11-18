import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Selected hub provider (for filtering games)
final selectedHubProvider = StateProvider<String?>((ref) => null);

/// Game list screen - filter by selected hub, order by gameDate desc
class GameListScreen extends ConsumerStatefulWidget {
  const GameListScreen({super.key});

  @override
  ConsumerState<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends ConsumerState<GameListScreen> {

  @override
  Widget build(BuildContext context) {
    final selectedHubId = ref.watch(selectedHubProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    // Get user's hubs for filter
    final hubsStream = currentUserId != null
        ? hubsRepo.watchHubsByMember(currentUserId)
        : Stream.value(<Hub>[]);

    // Get games stream - show completed games from all hubs when no hub selected
    final gamesStream = selectedHubId != null
        ? gamesRepo.watchGamesByHub(selectedHubId)
        : gamesRepo.watchCompletedGames(limit: 100);

    return AppScaffold(
      title: 'משחקים',
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () => context.push('/calendar${selectedHubId != null ? '?hubId=$selectedHubId' : ''}'),
          tooltip: 'לוח שנה',
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/games/create'),
        icon: const Icon(Icons.add),
        label: const Text('צור משחק'),
      ),
      body: Column(
        children: [
          // Hub filter
          StreamBuilder<List<Hub>>(
            stream: hubsStream,
            builder: (context, hubsSnapshot) {
              if (hubsSnapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator();
              }

              final hubs = hubsSnapshot.data ?? [];

              if (hubs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: FuturisticEmptyState(
                    icon: Icons.group_outlined,
                    title: 'אין הובס',
                    message: 'צור הוב כדי ליצור משחקים',
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('/hubs/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('צור הוב'),
                    ),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedHubId,
                  decoration: const InputDecoration(
                    labelText: 'בחר הוב',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('כל ההובס'),
                    ),
                    ...hubs.map((hub) => DropdownMenuItem<String>(
                          value: hub.hubId,
                          child: Text(hub.name),
                        )),
                  ],
                  onChanged: (value) {
                    ref.read(selectedHubProvider.notifier).state = value;
                  },
                ),
              );
            },
          ),

          // Games list
          Expanded(
            child: StreamBuilder<List<Game>>(
              stream: gamesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    itemCount: 5,
                    itemBuilder: (context, index) => const SkeletonGameCard(),
                  );
                }

                if (snapshot.hasError) {
                  return FuturisticEmptyState(
                    icon: Icons.error_outline,
                    title: 'שגיאה בטעינת משחקים',
                    message: ErrorHandlerService().handleException(
                      snapshot.error,
                      context: 'Game list screen',
                    ),
                    action: ElevatedButton.icon(
                      onPressed: () {
                        // Retry by rebuilding - trigger rebuild via key change
                        // For ConsumerWidget, we can't use setState, so we'll just show the error
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('נסה שוב'),
                    ),
                  );
                }

                final games = snapshot.data ?? [];

                if (games.isEmpty) {
                  return FuturisticEmptyState(
                    icon: Icons.sports_soccer_outlined,
                    title: selectedHubId == null
                        ? 'אין משחקים'
                        : 'אין משחקים בהוב זה',
                    message: 'צור משחק חדש כדי להתחיל',
                    action: ElevatedButton.icon(
                      onPressed: () => context.push('/games/create'),
                      icon: const Icon(Icons.add),
                      label: const Text('צור משחק'),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    final dateFormat = DateFormat('dd/MM/yyyy', 'he');
                    
                    return _GameCard(
                      game: game,
                      dateFormat: dateFormat,
                      onTap: () => context.push('/games/${game.gameId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GameStatus status, BuildContext context) {
    switch (status) {
      case GameStatus.completed:
        return Colors.green;
      case GameStatus.inProgress:
        return Colors.blue;
      case GameStatus.teamsFormed:
        return Colors.orange;
      case GameStatus.statsInput:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(GameStatus status) {
    switch (status) {
      case GameStatus.teamSelection:
        return 'בחירת קבוצות';
      case GameStatus.teamsFormed:
        return 'קבוצות נוצרו';
      case GameStatus.inProgress:
        return 'במהלך';
      case GameStatus.completed:
        return 'הושלם';
      case GameStatus.statsInput:
        return 'הזנת סטטיסטיקות';
    }
  }
}

/// Game card widget - displays game as bulletin board item
class _GameCard extends ConsumerWidget {
  final Game game;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  const _GameCard({
    required this.game,
    required this.dateFormat,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final eventsRepo = ref.read(hubEventsRepositoryProvider);
    final venuesRepo = ref.read(venuesRepositoryProvider);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score row (prominent)
              if (game.teamAScore != null && game.teamBScore != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${game.teamAScore}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '-',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${game.teamBScore}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              if (game.teamAScore != null && game.teamBScore != null)
                const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateFormat.format(game.gameDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Location (from event, venue, or hub)
              FutureBuilder<Hub?>(
                future: hubsRepo.getHub(game.hubId),
                builder: (context, hubSnapshot) {
                  return FutureBuilder<List<HubEvent>>(
                    future: game.eventId != null
                        ? eventsRepo.getHubEvents(game.hubId)
                        : Future.value([]),
                    builder: (context, eventSnapshot) {
                      return FutureBuilder<Venue?>(
                        future: game.venueId != null
                            ? venuesRepo.getVenue(game.venueId!)
                            : Future.value(null),
                        builder: (context, venueSnapshot) {
                          final hub = hubSnapshot.data;
                          final events = eventSnapshot.data ?? [];
                          HubEvent? event;
                          if (game.eventId != null) {
                            try {
                              event = events.firstWhere(
                                (e) => e.eventId == game.eventId,
                              );
                            } catch (e) {
                              event = events.isNotEmpty ? events.first : null;
                            }
                          }
                          final venue = venueSnapshot.data;
                          
                          // Get location: from event, or venue name, or game location, or hub name
                          String? location;
                          if (event?.location != null && event!.location!.isNotEmpty) {
                            location = event.location;
                          } else if (venue != null) {
                            location = venue.name;
                          } else if (game.location != null && game.location!.isNotEmpty) {
                            location = game.location;
                          } else if (hub?.name != null) {
                            location = hub!.name;
                          }
                          
                          if (location != null && location.isNotEmpty) {
                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        location,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  );
                },
              ),
              
              // Hub name
              FutureBuilder<Hub?>(
                future: hubsRepo.getHub(game.hubId),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          snapshot.data!.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 12),
              
              // Created by (who logged the game)
              FutureBuilder<User?>(
                future: usersRepo.getUser(game.createdBy),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'תועד על ידי: ${snapshot.data!.name}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
