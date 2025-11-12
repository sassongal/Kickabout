import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/data/private_messages_repository.dart';
import 'package:kickabout/data/users_repository.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/widgets/player_avatar.dart';

/// Messages list screen - shows all conversations
class MessagesListScreen extends ConsumerWidget {
  const MessagesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('שגיאה: ${snapshot.error}'),
            );
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('אין שיחות'),
                  const SizedBox(height: 8),
                  Text(
                    'כשיהיו הודעות חדשות, הן יופיעו כאן',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUserId = conversation.participants
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
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
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

