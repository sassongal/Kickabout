import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kattrick/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kattrick/widgets/futuristic/futuristic_card.dart';
import 'package:kattrick/widgets/futuristic/loading_state.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/futuristic_theme.dart';

/// Notification Settings Screen - Manage notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  final String userId;

  const NotificationSettingsScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _isLoading = false;
  // ignore: unused_field
  bool _isSaving = false;
  User? _currentUser;
  Map<String, bool> _notificationPreferences = {};

  // Notification categories
  final Map<String, List<NotificationItem>> _notificationCategories = {
    'משחקים': [
      NotificationItem(
        key: 'game_reminder',
        title: 'תזכורות משחקים',
        description: 'קבל תזכורות לפני משחקים קרובים',
        icon: Icons.sports_soccer,
      ),
      NotificationItem(
        key: 'signup',
        title: 'הרשמה למשחק',
        description: 'התראות כשמישהו נרשם למשחק שלך',
        icon: Icons.person_add,
      ),
      NotificationItem(
        key: 'new_game',
        title: 'משחקים חדשים',
        description: 'התראות על משחקים חדשים בהובים שלך',
        icon: Icons.event,
      ),
    ],
    'חברתי': [
      NotificationItem(
        key: 'like',
        title: 'לייקים',
        description: 'התראות כשמישהו אוהב את הפוסטים שלך',
        icon: Icons.favorite,
      ),
      NotificationItem(
        key: 'comment',
        title: 'תגובות',
        description: 'התראות על תגובות לפוסטים שלך',
        icon: Icons.comment,
      ),
      NotificationItem(
        key: 'new_comment',
        title: 'תגובות חדשות',
        description: 'התראות על תגובות חדשות בדיונים',
        icon: Icons.comment_outlined,
      ),
      NotificationItem(
        key: 'new_follower',
        title: 'עוקבים חדשים',
        description: 'התראות כשמישהו מתחיל לעקוב אחריך',
        icon: Icons.person_add_alt_1,
      ),
    ],
    'תקשורת': [
      NotificationItem(
        key: 'message',
        title: 'הודעות פרטיות',
        description: 'התראות על הודעות פרטיות חדשות',
        icon: Icons.message,
      ),
      NotificationItem(
        key: 'hub_chat',
        title: 'צ\'אט הוב',
        description: 'התראות על הודעות חדשות בצ\'אט ההוב',
        icon: Icons.chat_bubble,
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final user = await usersRepo.getUser(widget.userId);
      if (user != null && mounted) {
        setState(() {
          _currentUser = user;
          _notificationPreferences =
              Map<String, bool>.from(user.notificationPreferences);
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveNotificationPreferences() async {
    if (_currentUser == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      final updatedUser = _currentUser!.copyWith(
        notificationPreferences:
            Map<String, bool>.from(_notificationPreferences),
      );

      await usersRepo.setUser(updatedUser);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context,
          'העדפות ההתראות עודכנו בהצלחה!',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorFromException(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _updateNotificationPreference(String key, bool value) {
    setState(() {
      _notificationPreferences[key] = value;
    });
    // Auto-save on change
    _saveNotificationPreferences();
  }

  void _toggleAllNotifications(bool enabled) {
    setState(() {
      for (final category in _notificationCategories.values) {
        for (final item in category) {
          _notificationPreferences[item.key] = enabled;
        }
      }
    });
    // Auto-save on change
    _saveNotificationPreferences();
  }

  bool _areAllNotificationsEnabled() {
    for (final category in _notificationCategories.values) {
      for (final item in category) {
        if (!(_notificationPreferences[item.key] ?? true)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _areAllNotificationsDisabled() {
    for (final category in _notificationCategories.values) {
      for (final item in category) {
        if (_notificationPreferences[item.key] ?? false) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _currentUser == null) {
      return FuturisticScaffold(
        title: 'ניהול התראות',
        body: const FuturisticLoadingState(message: 'טוען העדפות...'),
      );
    }

    final allEnabled = _areAllNotificationsEnabled();
    final allDisabled = _areAllNotificationsDisabled();

    return FuturisticScaffold(
      title: 'ניהול התראות',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Quick Actions
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    onPressed: allEnabled
                        ? null
                        : () => _toggleAllNotifications(true),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('הפעל הכל'),
                    style: TextButton.styleFrom(
                      foregroundColor: FuturisticColors.primary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: allDisabled
                        ? null
                        : () => _toggleAllNotifications(false),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('כבה הכל'),
                    style: TextButton.styleFrom(
                      foregroundColor: FuturisticColors.error,
                    ),
                  ),
                ],
              ),
            ),

            // Notification Categories
            ..._notificationCategories.entries.map((entry) {
              final categoryName = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(categoryName),
                  const SizedBox(height: 8),
                  FuturisticCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        ...items.asMap().entries.map((itemEntry) {
                          final index = itemEntry.key;
                          final item = itemEntry.value;
                          final isLast = index == items.length - 1;

                          return Column(
                            children: [
                              _buildNotificationTile(item),
                              if (!isLast)
                                const Divider(
                                  height: 1,
                                  color: FuturisticColors.surfaceVariant,
                                ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              );
            }),

            // Info Card
            FuturisticCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: FuturisticColors.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ההעדפות נשמרות אוטומטית. תוכל לשנות אותן בכל עת.',
                      style: FuturisticTypography.bodySmall.copyWith(
                        color: FuturisticColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: FuturisticTypography.labelLarge.copyWith(
          color: FuturisticColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    final isEnabled = _notificationPreferences[item.key] ?? true;

    return SwitchListTile(
      value: isEnabled,
      onChanged: (value) => _updateNotificationPreference(item.key, value),
      title: Text(
        item.title,
        style: FuturisticTypography.labelLarge.copyWith(
          color: FuturisticColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        item.description,
        style: FuturisticTypography.bodySmall.copyWith(
          color: FuturisticColors.textSecondary,
        ),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: FuturisticColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          item.icon,
          color: FuturisticColors.primary,
          size: 24,
        ),
      ),
      activeThumbColor: FuturisticColors.primary,
    );
  }
}

/// Notification item model
class NotificationItem {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const NotificationItem({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}
