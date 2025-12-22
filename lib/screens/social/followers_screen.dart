import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/player_avatar.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Followers screen - shows users that follow a user
class FollowersScreen extends ConsumerWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followRepo = ref.watch(followRepositoryProvider);
    final followersStream = followRepo.watchFollowers(userId);

    return AppScaffold(
      title: 'עוקבים',
      body: StreamBuilder<List<User>>(
        stream: followersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('שגיאה: ${snapshot.error}'),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('אין עוקבים'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final user = users[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: PremiumColors.border),
                  boxShadow: PremiumShadows.sm,
                ),
                child: Row(
                  children: [
                    PlayerAvatar(user: user, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: PremiumTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (user.city != null && user.city!.isNotEmpty)
                            Text(
                              user.city!,
                              style: PremiumTypography.bodySmall
                                  .copyWith(color: PremiumColors.textSecondary),
                            )
                          else
                            Text(
                              user.email,
                              style: PremiumTypography.bodySmall
                                  .copyWith(color: PremiumColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message_outlined),
                      tooltip: 'שלח הודעה',
                      onPressed: () => _startChat(context, ref, user),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => context.push('/profile/${user.uid}'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _startChat(
  BuildContext context,
  WidgetRef ref,
  User target,
) async {
  final currentUserId = ref.read(currentUserIdProvider);
  if (currentUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('נא להתחבר כדי לשלוח הודעה')),
    );
    return;
  }

  if (currentUserId == target.uid) {
    return;
  }

  try {
    final privateMessagesRepo = ref.read(privateMessagesRepositoryProvider);
    final conversationId =
        await privateMessagesRepo.getOrCreateConversation(
      currentUserId,
      target.uid,
    );
    if (context.mounted) {
      context.go('/messages/$conversationId');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('שגיאה בפתיחת שיחה: $e')),
      );
    }
  }
}
