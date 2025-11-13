import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/users_repository.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/widgets/player_avatar.dart';

/// Game chat screen - real-time chat for a game
class GameChatScreen extends ConsumerStatefulWidget {
  final String gameId;

  const GameChatScreen({super.key, required this.gameId});

  @override
  ConsumerState<GameChatScreen> createState() => _GameChatScreenState();
}

class _GameChatScreenState extends ConsumerState<GameChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatRepo = ref.watch(chatRepositoryProvider);
    final usersRepo = ref.watch(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesStream = chatRepo.watchGameMessages(widget.gameId);

    return AppScaffold(
      title: 'צ\'אט משחק',
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('שגיאה: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('אין הודעות עדיין'),
                        const SizedBox(height: 8),
                        Text(
                          'היה הראשון לשלוח הודעה במשחק זה!',
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                    return _ChatMessageBubble(
                      message: message,
                      isMe: isMe,
                      usersRepo: usersRepo,
                    );
                  },
                );
              },
            ),
          ),
          _ChatInputField(
            messageController: _messageController,
            onSend: (text) async {
              if (text.trim().isEmpty || currentUserId == null) return;
              await chatRepo.sendGameMessage(widget.gameId, currentUserId, text.trim());
              _messageController.clear();
              _scrollController.animateTo(
                0.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;
  final UsersRepository usersRepo;

  const _ChatMessageBubble({
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
                        : Theme.of(context).colorScheme.surfaceVariant,
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
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          DateFormat('HH:mm').format(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe
                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
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
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
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

