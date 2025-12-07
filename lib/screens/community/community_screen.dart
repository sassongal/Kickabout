import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/futuristic/empty_state.dart';
import 'package:kattrick/widgets/futuristic/skeleton_loader.dart';

/// Community screen showing hub recruiting posts and public games
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedRepo = ref.watch(feedRepositoryProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    // Region-aware recruiting posts
    final userFuture = currentUserId != null
        ? usersRepo.getUser(currentUserId)
        : Future<User?>.value(null);

    return FutureBuilder<User?>(
      future: userFuture,
      builder: (context, userSnap) {
        final user = userSnap.data;
        final region = user?.region;

        final recruitingStream = feedRepo.streamRegionalFeed(
          region: region,
          postType: 'hub_recruiting',
        );

        final publicGamesStream =
            gamesRepo.watchPublicCompletedGames(limit: 50, region: region);

        return AppScaffold(
          title: 'קהילה',
          showBottomNav: true,
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.public, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        region != null && region.isNotEmpty
                            ? 'תוכן לפי אזור: $region'
                            : 'תוכן קהילתי',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<FeedPost>>(
                  stream: recruitingStream,
                  builder: (context, recruitSnap) {
                    final recruitingPosts = recruitSnap.data ?? [];
                    return StreamBuilder<List<Game>>(
                      stream: publicGamesStream,
                      builder: (context, gameSnap) {
                        if (recruitSnap.connectionState ==
                                ConnectionState.waiting ||
                            gameSnap.connectionState ==
                                ConnectionState.waiting) {
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: 4,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SkeletonLoader(height: 120),
                            ),
                          );
                        }

                        if (recruitSnap.hasError || gameSnap.hasError) {
                          return FuturisticEmptyState(
                            icon: Icons.error_outline,
                            title: 'שגיאה בטעינה',
                            message: ErrorHandlerService().handleException(
                              recruitSnap.error ?? gameSnap.error,
                              context: 'Community screen',
                            ),
                            action: ElevatedButton.icon(
                              onPressed: () => {},
                              icon: const Icon(Icons.refresh),
                              label: const Text('נסה שוב'),
                            ),
                          );
                        }

                        final games = gameSnap.data ?? [];
                        final items = <_CommunityItem>[
                          ...recruitingPosts
                              .map((p) => _CommunityItem.recruiting(p)),
                          ...games.map((g) => _CommunityItem.game(g)),
                        ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

                        if (items.isEmpty) {
                          return FuturisticEmptyState(
                            icon: Icons.group,
                            title: 'אין כרגע פעילות קהילתית',
                            message:
                                'כשיתפרסמו חיפושי שחקנים או משחקים פתוחים באזור, הם יופיעו כאן.',
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return item.when(
                              recruiting: (post) => _RecruitingCard(post: post),
                              game: (game) => _GameCard(game: game),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecruitingCard extends StatelessWidget {
  final FeedPost post;
  const _RecruitingCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.hubName ?? 'חיפוש שחקנים',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(post.createdAt),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (post.content != null && post.content!.isNotEmpty)
              Text(post.content!),
            const SizedBox(height: 8),
            Row(
              children: [
                if (post.neededPlayers > 0) ...[
                  const Icon(Icons.group, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text('מחפשים ${post.neededPlayers} שחקנים'),
                ],
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    if (post.hubId.isNotEmpty) {
                      context.push('/hubs/${post.hubId}');
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('פרטי האב'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.sports_soccer, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.denormalized.hubName ?? 'Unknown Hub',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('dd/MM').format(game.gameDate),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    game.denormalized.venueName ??
                        game.location ??
                        'מיקום לא ידוע',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => context.push('/games/${game.gameId}'),
              icon: const Icon(Icons.info_outline),
              label: const Text('פרטי משחק'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityItem {
  final FeedPost? recruiting;
  final Game? game;
  final DateTime timestamp;

  _CommunityItem.recruiting(this.recruiting)
      : game = null,
        timestamp = recruiting?.createdAt ?? DateTime.now();

  _CommunityItem.game(this.game)
      : recruiting = null,
        timestamp = game?.createdAt ?? game?.gameDate ?? DateTime.now();

  T when<T>({
    required T Function(FeedPost) recruiting,
    required T Function(Game) game,
  }) {
    if (this.recruiting != null) return recruiting(this.recruiting!);
    return game(this.game!);
  }
}
