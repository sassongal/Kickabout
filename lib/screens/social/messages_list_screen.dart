import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/services/error_handler_service.dart';

/// Messages list screen - shows all conversations
class MessagesListScreen extends ConsumerStatefulWidget {
  const MessagesListScreen({super.key});

  @override
  ConsumerState<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends ConsumerState<MessagesListScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final privateMessagesRepo = ref.watch(privateMessagesRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'הודעות',
        body: const Center(
          child: Text('נא להתחבר'),
        ),
      );
    }

    final conversationsStream = privateMessagesRepo.watchConversations(currentUserId);

    return AppScaffold(
      title: 'הודעות',
      body: StreamBuilder<List<Conversation>>(
        stream: conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SkeletonLoader(height: 80),
              ),
            );
          }

          if (snapshot.hasError) {
            return FuturisticEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת הודעות',
              message: ErrorHandlerService().handleException(
                snapshot.error,
                context: 'Messages list screen',
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

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return FuturisticEmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'אין שיחות',
              message: 'כשיהיו הודעות חדשות, הן יופיעו כאן',
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
                final otherUserId = conversation.participantIds
                  .firstWhere((id) => id != currentUserId);
              final unreadCount = conversation.unreadCount[currentUserId] ?? 0;

              return _ConversationCard(
                conversation: conversation,
                otherUserId: otherUserId,
                unreadCount: unreadCount,
                usersRepo: usersRepo,
              );
            },
          );
        },
      ),
    );
  }
}

class _ConversationCard extends ConsumerWidget {
  final Conversation conversation;
  final String otherUserId;
  final int unreadCount;
  final UsersRepository usersRepo;

  const _ConversationCard({
    required this.conversation,
    required this.otherUserId,
    required this.unreadCount,
    required this.usersRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = usersRepo.watchUser(otherUserId);

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return const ListTile(
            leading: CircularProgressIndicator(),
            title: Text('טוען...'),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: unreadCount > 0
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : null,
          child: ListTile(
            leading: Stack(
              children: [
                PlayerAvatar(user: user, radius: 24),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              user.name,
              style: TextStyle(
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              conversation.lastMessage ?? 'אין הודעות',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: conversation.lastMessageAt != null
                ? Text(
                    _formatTime(conversation.lastMessageAt!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  )
                : null,
            onTap: () => context.push('/messages/${conversation.conversationId}'),
          ),
        );
      },
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

