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

    // Get games stream
    final gamesStream = selectedHubId != null
        ? gamesRepo.watchGamesByHub(selectedHubId)
        : Stream.value(<Game>[]);

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
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'אין הובס. צור הוב כדי ליצור משחקים.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: DropdownButtonFormField<String>(
                  value: selectedHubId,
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
                    message: snapshot.error.toString(),
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
                    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'he');
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(game.status, context).withOpacity(0.2),
                          child: Icon(
                            Icons.sports_soccer,
                            color: _getStatusColor(game.status, context),
                          ),
                        ),
                        title: Text(
                          dateFormat.format(game.gameDate),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (game.location != null && game.location!.isNotEmpty)
                              Text(game.location!),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    _getStatusText(game.status),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: _getStatusColor(game.status, context)
                                      .withOpacity(0.1),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${game.teamCount} קבוצות',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/games/${game.gameId}'),
                      ),
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
