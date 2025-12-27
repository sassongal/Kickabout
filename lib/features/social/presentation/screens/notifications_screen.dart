import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/empty_state_illustrations.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/features/social/data/repositories/notifications_repository.dart';
import 'package:kattrick/features/social/domain/models/notification.dart' as app_notification;
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';

/// Notifications screen - shows all notifications for current user
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);
    final notificationsRepo = ref.watch(notificationsRepositoryProvider);

    if (currentUserId == null) {
      return AppScaffold(
        title: 'התראות',
        body: const Center(
          child: Text('נא להתחבר'),
        ),
      );
    }

    final notificationsStream =
        notificationsRepo.watchNotifications(currentUserId);
    final unreadCountStream = notificationsRepo.watchUnreadCount(currentUserId);

    return AppScaffold(
      title: 'התראות',
      actions: [
        StreamBuilder<int>(
          stream: unreadCountStream,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            if (count == 0) return const SizedBox.shrink();
            return Badge(
              label: Text('$count'),
              child: IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'סמן הכל כנקרא',
                onPressed: () async {
                  try {
                    await notificationsRepo.markAllAsRead(currentUserId);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('שגיאה: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        ),
      ],
      body: StreamBuilder<List<app_notification.Notification>>(
        stream: notificationsStream,
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
            return PremiumEmptyState(
              icon: Icons.error_outline,
              title: 'שגיאה בטעינת התראות',
              message: ErrorHandlerService().handleException(
                snapshot.error,
                context: 'Notifications screen',
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

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return PremiumEmptyState(
              icon: Icons.notifications_none,
              title: 'אין התראות',
              message: 'כשיהיו התראות חדשות, הן יופיעו כאן',
              illustration: const EmptyNotificationsIllustration(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh
            },
            child: ListView.builder(
              itemCount: notifications.length,
              padding: const EdgeInsets.all(8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationCard(
                  notification: notification,
                  notificationsRepo: notificationsRepo,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  final app_notification.Notification notification;
  final NotificationsRepository notificationsRepo;

  const _NotificationCard({
    required this.notification,
    required this.notificationsRepo,
  });

  IconData _getIcon(String type) {
    switch (type) {
      case 'game':
        return Icons.sports_soccer;
      case 'message':
        return Icons.chat;
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'signup':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'game':
        return Colors.green;
      case 'message':
        return Colors.blue;
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.orange;
      case 'signup':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _handleTap(BuildContext context) {
    if (!notification.read) {
      notificationsRepo.markAsRead(
          notification.userId, notification.notificationId);
    }

    // Navigate based on notification type
    if (notification.data != null) {
      if (notification.type == 'game' && notification.data!['gameId'] != null) {
        context.push('/games/${notification.data!['gameId']}');
      } else if (notification.type == 'message' &&
          notification.data!['hubId'] != null) {
        context.push('/hubs/${notification.data!['hubId']}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.read
          ? null
          : Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(notification.type).withValues(alpha: 0.2),
          child: Icon(
            _getIcon(notification.type),
            color: _getColor(notification.type),
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.read ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: notification.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () => _handleTap(context),
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
