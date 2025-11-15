import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/core/constants.dart';

/// Home screen - central hub with personalized content
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);
    final gamesRepo = ref.watch(gamesRepositoryProvider);
    final notificationsRepo = ref.watch(notificationsRepositoryProvider);
    final locationService = ref.watch(locationServiceProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'בית',
        body: const Center(
          child: Text('נא להתחבר'),
        ),
      );
    }

    final unreadCountStream = notificationsRepo.watchUnreadCount(currentUserId);

    return AppScaffold(
      title: 'בית',
      actions: [
        StreamBuilder<int>(
          stream: unreadCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return Badge(
              label: count > 0 ? Text('$count') : null,
              child: IconButton(
                icon: const Icon(Icons.notifications),
                tooltip: 'התראות',
                onPressed: () => context.push('/notifications'),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.map),
          tooltip: 'מפה',
          onPressed: () => context.push('/map'),
        ),
        IconButton(
          icon: const Icon(Icons.explore),
          tooltip: 'גלה הובים',
          onPressed: () => context.push('/discover'),
        ),
        IconButton(
          icon: const Icon(Icons.emoji_events),
          tooltip: 'שולחן מובילים',
          onPressed: () => context.push('/leaderboard'),
        ),
        IconButton(
          icon: const Icon(Icons.chat),
          tooltip: 'הודעות',
          onPressed: () => context.push('/messages'),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/hubs/create'),
        icon: const Icon(Icons.add),
        label: const Text('צור הוב'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Force refresh
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick actions
              _QuickActionsSection(),
              const SizedBox(height: 24),

              // Upcoming games
              _UpcomingGamesSection(
                currentUserId: currentUserId,
                gamesRepo: gamesRepo,
                hubsRepo: hubsRepo,
              ),
              const SizedBox(height: 24),

              // Nearby hubs
              _NearbyHubsSection(
                locationService: locationService,
                hubsRepo: hubsRepo,
              ),
              const SizedBox(height: 24),

              // Activity feed preview
              _ActivityFeedPreview(
                currentUserId: currentUserId,
                hubsRepo: hubsRepo,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'פעולות מהירות',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/hubs/create'),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.group_add, size: 32),
                        SizedBox(height: 8),
                        Text('צור הוב'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/discover'),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.explore, size: 32),
                        SizedBox(height: 8),
                        Text('גלה הובים'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push('/map'),
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.map, size: 32),
                        SizedBox(height: 8),
                        Text('מפה'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpcomingGamesSection extends ConsumerWidget {
  final String currentUserId;
  final GamesRepository gamesRepo;
  final HubsRepository hubsRepo;

  const _UpcomingGamesSection({
    required this.currentUserId,
    required this.gamesRepo,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);

    return StreamBuilder<List<Hub>>(
      stream: hubsStream,
      builder: (context, hubsSnapshot) {
        if (hubsSnapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: SkeletonLoader(height: 100),
            ),
          );
        }

        final hubs = hubsSnapshot.data ?? [];
        if (hubs.isEmpty) {
          return const SizedBox.shrink();
        }

        final hubIds = hubs.map((h) => h.hubId).toList();
        final now = DateTime.now();
        final nextWeek = now.add(const Duration(days: 7));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'משחקים קרובים',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<Game>>(
              future: _getUpcomingGames(hubIds, now, nextWeek),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final games = snapshot.data ?? [];
                if (games.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'אין משחקים קרובים',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: games.take(3).map((game) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.sports_soccer),
                        title: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(game.gameDate),
                        ),
                        subtitle: Text(game.location ?? 'מיקום לא צוין'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/games/${game.gameId}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<Game>> _getUpcomingGames(
    List<String> hubIds,
    DateTime start,
    DateTime end,
  ) async {
    final allGames = <Game>[];
    for (final hubId in hubIds) {
      final games = await gamesRepo.getGamesByHub(hubId);
      allGames.addAll(games);
    }

    return allGames
        .where((game) =>
            game.gameDate.isAfter(start) && game.gameDate.isBefore(end))
        .toList()
      ..sort((a, b) => a.gameDate.compareTo(b.gameDate));
  }
}

class _NearbyHubsSection extends ConsumerWidget {
  final LocationService locationService;
  final HubsRepository hubsRepo;

  const _NearbyHubsSection({
    required this.locationService,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'הובים מומלצים',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Hub>>(
          future: _getNearbyHubs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const FuturisticLoadingState(message: 'מחפש הובים קרובים...');
            }

            final hubs = snapshot.data ?? [];
            if (hubs.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'אין הובים קרובים',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: hubs.take(3).map((hub) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(hub.name),
                    subtitle: Text('${hub.memberIds.length} חברים'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push('/hubs/${hub.hubId}'),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<List<Hub>> _getNearbyHubs() async {
    try {
      final position = await locationService.getCurrentLocation();
      if (position == null) return [];
      return await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 10.0,
      );
    } catch (e) {
      return [];
    }
  }
}

class _ActivityFeedPreview extends ConsumerWidget {
  final String currentUserId;
  final HubsRepository hubsRepo;

  const _ActivityFeedPreview({
    required this.currentUserId,
    required this.hubsRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubsStream = hubsRepo.watchHubsByMember(currentUserId);
    final feedRepo = ref.watch(feedRepositoryProvider);

    return StreamBuilder<List<Hub>>(
      stream: hubsStream,
      builder: (context, hubsSnapshot) {
        if (hubsSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final hubs = hubsSnapshot.data ?? [];
        if (hubs.isEmpty) {
          return const SizedBox.shrink();
        }

        final hubId = hubs.first.hubId;
        final feedStream = feedRepo.watchFeed(hubId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'פיד פעילות',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () => context.push('/hubs/$hubId'),
                  child: const Text('הצג הכל'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<FeedPost>>(
              stream: feedStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final posts = snapshot.data ?? [];
                if (posts.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          'אין פעילות עדיין',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: posts.take(3).map((post) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.feed),
                        title: Text(_getPostTypeText(post.type)),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(post.createdAt),
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/hubs/$hubId/feed/${post.postId}'),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getPostTypeText(String type) {
    switch (type) {
      case 'game':
        return 'משחק חדש';
      case 'achievement':
        return 'הישג חדש';
      case 'rating':
        return 'דירוג חדש';
      case 'post':
        return 'פוסט חדש';
      default:
        return 'פעילות';
    }
  }
}

