import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Notification badge button widget
/// Shows notification icon with unread count badge
class NotificationsBadgeButton extends ConsumerWidget {
  const NotificationsBadgeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId == null) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifications'),
        tooltip: 'התראות',
      );
    }

    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider(currentUserId));

    return unreadCountAsync.when(
      data: (count) {
        if (count == 0) {
          return IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
            tooltip: 'התראות',
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.push('/notifications'),
              tooltip: 'התראות ($count)',
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: PremiumColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
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
        );
      },
      loading: () => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifications'),
        tooltip: 'התראות',
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => context.push('/notifications'),
        tooltip: 'התראות',
      ),
    );
  }
}

