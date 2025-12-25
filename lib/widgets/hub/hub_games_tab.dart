import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';

/// Games tab widget
class HubGamesTab extends ConsumerStatefulWidget {
  final String hubId;

  const HubGamesTab({super.key, required this.hubId});

  @override
  ConsumerState<HubGamesTab> createState() => _HubGamesTabState();
}

class _HubGamesTabState extends ConsumerState<HubGamesTab> {
  @override
  Widget build(BuildContext context) {
    final gameQueriesRepo = ref.watch(gameQueriesRepositoryProvider);
    final gamesStream = gameQueriesRepo.watchGamesByHub(widget.hubId);

    return StreamBuilder<List<Game>>(
      stream: gamesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 3,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 80),
            ),
          );
        }

        if (snapshot.hasError) {
          return PremiumEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת משחקים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Hub detail - games tab',
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
        final currentUserId = ref.watch(currentUserIdProvider);
        final hubPermissionsAsync = currentUserId != null
            ? ref.watch(hubPermissionsProvider(
                (hubId: widget.hubId, userId: currentUserId)))
            : null;
        final hubPermissions = hubPermissionsAsync?.valueOrNull;
        final canCreateGames = hubPermissions?.canCreateGames ?? false;

        // Filter completed games only
        final completedGames =
            games.where((g) => g.status == GameStatus.completed).toList();

        // Group games by eventId (for Winner Stays sessions)
        final groupedGames = <String, List<Game>>{};
        for (final game in completedGames) {
          final key = game.eventId ?? 'standalone_${game.gameId}';
          groupedGames.putIfAbsent(key, () => []).add(game);
        }

        return Column(
          children: [
            // Add game log button (for authorized users)
            if (canCreateGames)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/hubs/${widget.hubId}/log-past-game'),
                  icon: const Icon(Icons.add),
                  label: const Text('תיעוד משחק'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            // Games list
            Expanded(
              child: groupedGames.isEmpty
                  ? PremiumEmptyState(
                      icon: Icons.sports_soccer,
                      title: 'אין משחקים שהושלמו',
                      message: canCreateGames
                          ? 'תעד משחק חדש כדי להתחיל'
                          : 'אין משחקים להצגה',
                    )
                  : ListView.builder(
                      itemCount: groupedGames.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final entry = groupedGames.entries.elementAt(index);
                        final eventIdOrKey = entry.key;
                        final sessionGames = entry.value;
                        final primaryGame = sessionGames.first;

                        // Check if should collapse (24h after last update)
                        final now = DateTime.now();
                        final lastUpdate = sessionGames
                            .map((g) => g.updatedAt)
                            .reduce((a, b) => a.isAfter(b) ? a : b);
                        final hoursSinceUpdate =
                            now.difference(lastUpdate).inHours;
                        final shouldCollapse = hoursSinceUpdate >= 24;

                        final isStandalone =
                            eventIdOrKey.startsWith('standalone_');
                        final eventId = isStandalone ? null : eventIdOrKey;

                        return _buildGameCard(
                          context: context,
                          ref: ref,
                          game: primaryGame,
                          eventId: eventId,
                          matchCount: primaryGame.session.matches.length,
                          isCollapsed: shouldCollapse,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required WidgetRef ref,
    required Game game,
    required String? eventId,
    required int matchCount,
    required bool isCollapsed,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event title or standalone label
            if (eventId != null)
              FutureBuilder<HubEvent?>(
                future: ref
                    .read(hubEventsRepositoryProvider)
                    .getHubEvent(widget.hubId, eventId),
                builder: (context, snapshot) {
                  final event = snapshot.data;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event?.title ?? 'משחק',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${game.gameDate.day}/${game.gameDate.month}/${game.gameDate.year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  );
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sports_soccer, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'משחק עצמאי',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${game.gameDate.day}/${game.gameDate.month}/${game.gameDate.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Aggregate wins (Winner Stays sessions)
            if (game.session.aggregateWins.isNotEmpty) ...[
              const Text(
                'תוצאות סופיות:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...game.teams.map((team) {
                final wins =
                    game.session.aggregateWins[team.color ?? team.name] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          team.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '$wins ניצחונות',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],

            // Match details (collapsed/expanded)
            if (matchCount > 0)
              if (!isCollapsed)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    '$matchCount משחקים בסשן',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  children: game.session.matches.map((match) {
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        '${match.teamAColor} ${match.scoreA} - ${match.scoreB} ${match.teamBColor}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '${match.createdAt.hour}:${match.createdAt.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                )
              else
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.history, size: 20),
                  title: Text(
                    '$matchCount משחקים',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Text(
                    'לפני ${hoursSinceUpdate(game.updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String hoursSinceUpdate(DateTime updatedAt) {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inDays > 0) {
      return '${diff.inDays} ימים';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} שעות';
    } else {
      return '${diff.inMinutes} דקות';
    }
  }
}
