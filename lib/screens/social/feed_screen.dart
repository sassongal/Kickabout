import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/feed_repository.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/widgets/game_photos_gallery.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Feed screen - shows activity feed for a hub
class FeedScreen extends ConsumerStatefulWidget {
  final String? hubId;

  const FeedScreen({super.key, this.hubId});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.hubId == null || widget.hubId!.isEmpty) return;
    if (_scrollController.position.extentAfter < 300) {
      final feedState = ref.read(feedNotifierProvider(widget.hubId!));
      if (!feedState.isLoading && feedState.hasMore) {
        ref.read(feedNotifierProvider(widget.hubId!).notifier).fetchNextPage();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final usersRepo = ref.read(usersRepositoryProvider);

    if (widget.hubId == null || widget.hubId!.isEmpty) {
      return const AppScaffold(
        title: 'קהילה',
        showBottomNav: true,
        forceBottomNav: true,
        body: Center(
          child: Text('פיד קהילתי בקרוב'),
        ),
      );
    }
    
    if (currentUserId == null) {
      return AppScaffold(
        title: 'פיד פעילות',
        body: const Center(child: Text('נא להתחבר')),
      );
    }
    
    return FutureBuilder<User?>(
      future: usersRepo.getUser(currentUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppScaffold(
            title: 'פיד פעילות',
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return AppScaffold(
            title: 'פיד פעילות',
            body: FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת המשתמש',
              message: ErrorHandlerService().handleException(
                snapshot.error,
                context: 'Feed screen - user loading',
              ),
            ),
          );
        }
        
        final user = snapshot.data;
        final userRegion = user?.region;
        final feedRepo = ref.read(feedRepositoryProvider);
        
        // If user has region, use regional feed; otherwise use hub feed
        final feedStream = userRegion != null && userRegion.isNotEmpty
            ? feedRepo.streamRegionalFeed(region: userRegion)
            : feedRepo.watchFeed(widget.hubId!);
        
        return AppScaffold(
          title: userRegion != null ? 'פיד אזורי ($userRegion)' : 'פיד פעילות',
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.push('/hubs/${widget.hubId}/create-post'),
            icon: const Icon(Icons.add),
            label: const Text('צור פוסט'),
          ),
          body: StreamBuilder<List<FeedPost>>(
            stream: feedStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SkeletonLoader(height: 120),
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return FuturisticEmptyState(
                  icon: Icons.error_outline,
                  title: 'שגיאה בטעינת הפיד',
                  message: ErrorHandlerService().handleException(
                    snapshot.error,
                    context: 'Feed screen',
                  ),
                  action: ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    icon: const Icon(Icons.refresh),
                    label: const Text('נסה שוב'),
                  ),
                );
              }
              
              final posts = snapshot.data ?? [];
              
              if (posts.isEmpty) {
                return FuturisticEmptyState(
                  icon: Icons.feed,
                  title: 'אין פעילות עדיין',
                  message: userRegion != null 
                      ? 'כשיהיו משחקים חדשים באזור שלך, הם יופיעו כאן'
                      : 'כשיהיו משחקים חדשים או הישגים, הם יופיעו כאן',
                  action: ElevatedButton.icon(
                    onPressed: () => context.push('/hubs/${widget.hubId}/create-post'),
                    icon: const Icon(Icons.add),
                    label: const Text('צור פוסט'),
                  ),
                );
              }
              
              return ListView.builder(
                itemCount: posts.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return _PostCard(
                    post: post,
                    currentUserId: currentUserId,
                    feedRepo: feedRepo,
                    usersRepo: ref.read(usersRepositoryProvider),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Removed: _buildBody - not used (using StreamBuilder directly)
}

class _PostCard extends ConsumerWidget {
  final FeedPost post;
  final String? currentUserId;
  final FeedRepository feedRepo;
  final UsersRepository usersRepo;

  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.feedRepo,
    required this.usersRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = usersRepo.watchUser(post.authorId);
    // Removed: Like functionality (simplified feed - no likes)

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('טוען...'),
          );
        }

        if (userSnapshot.hasError) {
          return ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: const Text('שגיאה בטעינת המשתמש'),
            subtitle: Text(
              ErrorHandlerService().handleException(
                userSnapshot.error,
                context: 'Feed post - user loading',
              ),
            ),
          );
        }

        final author = userSnapshot.data;
        if (author == null) {
          return const ListTile(
            leading: Icon(Icons.person_off),
            title: Text('משתמש לא נמצא'),
          );
        }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    PlayerAvatar(
                      user: author,
                      radius: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            _getPostTypeText(post.type),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatTime(post.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Content
                if (post.content != null) ...[
                  Text(post.content ?? post.text ?? ''),
                  const SizedBox(height: 8),
                ],
                // Photos
                if (post.photoUrls.isNotEmpty) ...[
                  GamePhotosGallery(
                    photoUrls: post.photoUrls,
                    canAddPhotos: false,
                    canDelete: false,
                  ),
                  const SizedBox(height: 8),
                ],
                // Action buttons based on post type
                // For completed games: "View Result"
                if (post.type == 'game_completed' || post.gameId != null)
                  InkWell(
                    onTap: () => context.push('/games/${post.gameId ?? post.entityId}'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_soccer, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'צפה בתוצאה',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // For events: "Join Game"
                if (post.type == 'event_created' || (post.entityId != null && post.gameId == null))
                  InkWell(
                    onTap: () {
                      // Navigate to event details
                      context.push('/hubs/${post.hubId}/events/${post.entityId}');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Colors.green),
                          const SizedBox(width: 8),
                          const Text(
                            'הצטרף למשחק',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Comments only (no likes)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      onPressed: () => context.push('/hubs/${post.hubId}/feed/${post.postId}'),
                    ),
                    Text('${post.commentsCount}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getPostTypeText(String type) {
    switch (type) {
      case 'game':
      case 'game_created':
        return 'יצר משחק חדש';
      case 'game_completed':
        return 'משחק הושלם';
      case 'event_created':
        return 'אירוע נפתח';
      case 'achievement':
        return 'השיג הישג';
      case 'rating':
        return 'דירג שחקן';
      case 'post':
        return 'פרסם פוסט';
      default:
        return 'פעילות';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'עכשיו';
    } else if (difference.inHours < 1) {
      return 'לפני ${difference.inMinutes} דקות';
    } else if (difference.inDays < 1) {
      return 'לפני ${difference.inHours} שעות';
    } else if (difference.inDays < 7) {
      return 'לפני ${difference.inDays} ימים';
    } else {
      return DateFormat('dd/MM/yyyy').format(time);
    }
  }
}
