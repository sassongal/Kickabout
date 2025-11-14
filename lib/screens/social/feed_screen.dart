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

/// Feed screen - shows activity feed for a hub
class FeedScreen extends ConsumerStatefulWidget {
  final String hubId;

  const FeedScreen({super.key, required this.hubId});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  @override
  Widget build(BuildContext context) {
    final feedRepo = ref.watch(feedRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final feedStream = feedRepo.watchFeed(widget.hubId);

    return AppScaffold(
      title: 'פיד פעילות',
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

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.feed,
              title: 'אין פעילות עדיין',
              message: 'כשיהיו משחקים חדשים או הישגים, הם יופיעו כאן',
              action: ElevatedButton.icon(
                onPressed: () => context.push('/hubs/${widget.hubId}/create-post'),
                icon: const Icon(Icons.add),
                label: const Text('צור פוסט'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by rebuilding
            },
            child: ListView.builder(
              itemCount: posts.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final post = posts[index];
                return _PostCard(
                  post: post,
                  currentUserId: currentUserId,
                  feedRepo: feedRepo,
                  usersRepo: usersRepo,
                );
              },
            ),
          );
        },
      ),
    );
  }
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
    final isLiked = currentUserId != null && post.likes.contains(currentUserId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: StreamBuilder<User?>(
        stream: userStream,
        builder: (context, userSnapshot) {
          final author = userSnapshot.data;
          if (author == null) {
            return const ListTile(
              leading: CircularProgressIndicator(),
              title: Text('טוען...'),
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
                  Text(post.content!),
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
                // Game link
                if (post.gameId != null)
                  InkWell(
                    onTap: () => context.push('/games/${post.gameId}'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.sports_soccer, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'צפה במשחק',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Actions
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: currentUserId != null
                          ? () {
                              if (isLiked) {
                                feedRepo.unlikePost(post.hubId, post.postId, currentUserId!);
                              } else {
                                feedRepo.likePost(post.hubId, post.postId, currentUserId!);
                              }
                            }
                          : null,
                    ),
                    Text('${post.likes.length}'),
                    const SizedBox(width: 16),
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
        return 'יצר משחק חדש';
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

