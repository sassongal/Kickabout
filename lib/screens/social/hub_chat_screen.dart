import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/users_repository.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/services/error_handler_service.dart';

/// Hub chat screen - real-time chat for a hub
class HubChatScreen extends ConsumerStatefulWidget {
  final String hubId;

  const HubChatScreen({super.key, required this.hubId});

  @override
  ConsumerState<HubChatScreen> createState() => _HubChatScreenState();
}

class _HubChatScreenState extends ConsumerState<HubChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null) return;

    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      final hubsRepo = ref.read(hubsRepositoryProvider);

      await chatRepo.sendMessage(
        widget.hubId,
        currentUserId,
        text,
      );

      // Send notification to other members
      try {
        final pushIntegration =
            ref.read(pushNotificationIntegrationServiceProvider);
        final usersRepo = ref.read(usersRepositoryProvider);
        final currentUser = await usersRepo.getUser(currentUserId);
        final memberIds = await hubsRepo.getHubMemberIds(widget.hubId);

        await pushIntegration.notifyNewMessage(
          hubId: widget.hubId,
          senderName: currentUser?.name ?? 'מישהו',
          message: text,
          memberIds: memberIds,
          excludeUserId: currentUserId,
        );
      } catch (e) {
        debugPrint('Failed to send message notification: $e');
      }
      
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בשליחת הודעה: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use ref.read for repositories - they don't change, so no need to watch
    final chatRepo = ref.read(chatRepositoryProvider);
    final usersRepo = ref.read(usersRepositoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider);
    final messagesStream = chatRepo.watchMessages(widget.hubId);

    return AppScaffold(
      title: 'צ\'אט',
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
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
                  return PremiumEmptyState(
                    icon: Icons.error_outline,
                    title: 'שגיאה בטעינת הודעות',
                    message: ErrorHandlerService().handleException(
                      snapshot.error,
                      context: 'Hub chat screen',
                    ),
                    action: ElevatedButton.icon(
                      onPressed: () {
                        // Retry by rebuilding
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('נסה שוב'),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return PremiumEmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'אין הודעות עדיין',
                    message: 'היה הראשון לשלוח הודעה!',
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.authorId == currentUserId;

                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                      usersRepo: usersRepo,
                    );
                  },
                );
              },
            ),
          ),
          // Input field
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'הקלד הודעה...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final bool isMe;
  final UsersRepository usersRepo;

  const _MessageBubble({
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
                PlayerAvatar(
                  user: author,
                  radius: 16,
                ),
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
                      Text(
                        DateFormat('HH:mm').format(message.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: (isMe
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.onSurfaceVariant)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 8),
                PlayerAvatar(
                  user: author,
                  radius: 16,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
