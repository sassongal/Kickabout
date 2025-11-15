import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/skeleton_loader.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/player_avatar.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Private chat screen - one-on-one conversation
class PrivateChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const PrivateChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends ConsumerState<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _markAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markAsRead() async {
    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final privateMessagesRepo = ref.read(privateMessagesRepositoryProvider);
      await privateMessagesRepo.markAsRead(widget.conversationId, currentUserId);
    } catch (e) {
      debugPrint('Failed to mark as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final privateMessagesRepo = ref.watch(privateMessagesRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesStream = privateMessagesRepo.watchMessages(widget.conversationId);

    return AppScaffold(
      title: 'שיחה פרטית',
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<PrivateMessage>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SkeletonLoader(height: 60),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return FuturisticEmptyState(
                    icon: Icons.error_outline,
                    title: 'שגיאה בטעינת הודעות',
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

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return FuturisticEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'אין הודעות עדיין',
                    message: 'התחל שיחה!',
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.authorId == currentUserId;
                    return _PrivateMessageBubble(
                      message: message,
                      isMe: isMe,
                      usersRepo: usersRepo,
                    );
                  },
                );
              },
            ),
          ),
          if (currentUserId != null)
            _ChatInputField(
              messageController: _messageController,
              onSend: (text) async {
                if (text.trim().isEmpty) return;
                try {
                  final privateMessagesRepo = ref.read(privateMessagesRepositoryProvider);
                  await privateMessagesRepo.sendMessage(
                    widget.conversationId,
                    currentUserId,
                    text.trim(),
                  );
                  _messageController.clear();
                  if (!context.mounted) return;
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  SnackbarHelper.showError(context, 'שגיאה בשליחת הודעה: $e');
                }
              },
            ),
        ],
      ),
    );
  }
}

class _PrivateMessageBubble extends ConsumerWidget {
  final PrivateMessage message;
  final bool isMe;
  final UsersRepository usersRepo;

  const _PrivateMessageBubble({
    required this.message,
    required this.isMe,
    required this.usersRepo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStream = usersRepo.watchUser(message.authorId);

    return StreamBuilder<User?>(
      stream: userStream,
      builder: (context, userSnapshot) {
        final author = userSnapshot.data;
        if (author == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                PlayerAvatar(user: author, radius: 16),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!isMe)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            author.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isMe
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      Text(
                        message.text,
                        style: TextStyle(
                          color: isMe
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.createdAt),
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe
                                  ? Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7)
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                          if (isMe && message.read) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 12,
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                PlayerAvatar(user: author, radius: 16),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChatInputField extends StatelessWidget {
  final TextEditingController messageController;
  final ValueChanged<String> onSend;

  const _ChatInputField({
    required this.messageController,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              decoration: InputDecoration(
                hintText: 'הקלד הודעה...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onSubmitted: onSend,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: () => onSend(messageController.text),
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}

