import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';

/// Notifications screen - shows all notifications for current user
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final notificationsStream = notificationsRepo.watchNotifications(currentUserId);
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
      body: StreamBuilder<List<Notification>>(
        stream: notificationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('שגיאה: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('אין התראות'),
                  const SizedBox(height: 8),
                  Text(
                    'כשיהיו התראות חדשות, הן יופיעו כאן',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
  final Notification notification;
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
    if (notification.read) {
      notificationsRepo.markAsRead(notification.userId, notification.notificationId);
    }

    // Navigate based on notification type
    if (notification.data != null) {
      if (notification.type == 'game' && notification.data!['gameId'] != null) {
        context.push('/games/${notification.data!['gameId']}');
      } else if (notification.type == 'message' && notification.data!['hubId'] != null) {
        context.push('/hubs/${notification.data!['hubId']}');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.read ? null : Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(notification.type).withOpacity(0.2),
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

