import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/comments_repository.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Post detail screen - shows post with comments
class PostDetailScreen extends ConsumerStatefulWidget {
  final String hubId;
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.hubId,
    required this.postId,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) {
      if (mounted) {
        SnackbarHelper.showError(context, 'נא להתחבר');
      }
      return;
    }

    try {
      final commentsRepo = ref.read(commentsRepositoryProvider);
      await commentsRepo.createComment(
        widget.hubId,
        widget.postId,
        currentUserId,
        text,
      );
      _commentController.clear();

      // Create notification for post author (using push integration service)
      try {
        final feedRepo = ref.read(feedRepositoryProvider);
        final post = await feedRepo.getPost(widget.hubId, widget.postId);
        if (post != null && post.authorId != currentUserId) {
          final pushIntegration = ref.read(pushNotificationIntegrationServiceProvider);
          final usersRepo = ref.read(usersRepositoryProvider);
          final currentUser = await usersRepo.getUser(currentUserId);
          
          await pushIntegration.notifyNewComment(
            postId: widget.postId,
            hubId: widget.hubId,
            commenterName: currentUser?.name ?? 'מישהו',
            postAuthorId: post.authorId,
          );
        }
      } catch (e) {
        debugPrint('Failed to send comment notification: $e');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בהוספת תגובה: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.read for repositories - they don't change, so no need to watch
    final feedRepo = ref.read(feedRepositoryProvider);
    final commentsRepo = ref.read(commentsRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    
    final postStream = feedRepo.watchPost(widget.hubId, widget.postId);
    final commentsStream = commentsRepo.watchComments(widget.hubId, widget.postId);

    return AppScaffold(
      title: 'פוסט',
      body: StreamBuilder<FeedPost?>(
        stream: postStream,
        builder: (context, postSnapshot) {
          if (postSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final post = postSnapshot.data;
          if (post == null) {
            return const Center(child: Text('פוסט לא נמצא'));
          }

          return Column(
            children: [
              // Post content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PostHeader(post: post, usersRepo: usersRepo),
                      const SizedBox(height: 16),
                      if (post.content != null) ...[
                        Text(
                          post.content!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (post.gameId != null)
                        InkWell(
                          onTap: () => context.push('/games/${post.gameId}'),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.sports_soccer, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
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
                      const Divider(height: 32),
                      // Comments section
                      Text(
                        'תגובות (${post.commentsCount})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Comment>>(
                        stream: commentsStream,
                        builder: (context, commentsSnapshot) {
                          if (commentsSnapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final comments = commentsSnapshot.data ?? [];

                          if (comments.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'אין תגובות עדיין',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return _CommentCard(
                                comment: comment,
                                currentUserId: currentUserId,
                                commentsRepo: commentsRepo,
                                usersRepo: usersRepo,
                                hubId: widget.hubId,
                                postId: widget.postId,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Comment input
              if (currentUserId != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: const InputDecoration(
                            hintText: 'הוסף תגובה...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _addComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _addComment,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PostHeader extends ConsumerWidget {
  final FeedPost post;
  final UsersRepository usersRepo;

  const _PostHeader({
    required this.post,
    required this.usersRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = usersRepo.watchUser(post.authorId);
    final feedRepo = ref.watch(feedRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final isLiked = currentUserId != null && post.likes.contains(currentUserId);

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        final author = userSnapshot.data;
        if (author == null) {
          return const CircularProgressIndicator();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PlayerAvatar(user: author, radius: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        _getPostTypeText(post.type),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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
            const SizedBox(height: 16),
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
                            feedRepo.unlikePost(post.hubId, post.postId, currentUserId);
                          } else {
                            feedRepo.likePost(post.hubId, post.postId, currentUserId);
                          }
                        }
                      : null,
                ),
                Text('${post.likes.length}'),
                const SizedBox(width: 16),
                const Icon(Icons.comment_outlined),
                const SizedBox(width: 8),
                Text('${post.commentsCount}'),
              ],
            ),
          ],
        );
      },
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

class _CommentCard extends ConsumerWidget {
  final Comment comment;
  final String? currentUserId;
  final CommentsRepository commentsRepo;
  final UsersRepository usersRepo;
  final String hubId;
  final String postId;

  const _CommentCard({
    required this.comment,
    required this.currentUserId,
    required this.commentsRepo,
    required this.usersRepo,
    required this.hubId,
    required this.postId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = usersRepo.watchUser(comment.authorId);
    final isLiked = currentUserId != null && comment.likes.contains(currentUserId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<User?>(
        stream: userStream,
        builder: (context, userSnapshot) {
          final author = userSnapshot.data;
          if (author == null) {
            return const SizedBox.shrink();
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlayerAvatar(user: author, radius: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatTime(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : Colors.grey,
                          ),
                          onPressed: currentUserId != null
                              ? () {
                                  if (isLiked) {
                                    commentsRepo.unlikeComment(
                                      hubId,
                                      postId,
                                      comment.commentId,
                                      currentUserId!,
                                    );
                                  } else {
                                    commentsRepo.likeComment(
                                      hubId,
                                      postId,
                                      comment.commentId,
                                      currentUserId!,
                                    );
                                  }
                                }
                              : null,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text(
                          '${comment.likes.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
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

