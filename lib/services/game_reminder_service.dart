import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

/// Service for managing game reminders
class GameReminderService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize reminder service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));

      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
    } catch (e) {
      debugPrint('Failed to initialize game reminder service: $e');
    }
  }

  /// Schedule reminders for a game
  Future<void> scheduleGameReminders(Game game, String gameTitle) async {
    if (!_initialized) await initialize();
    if (!Env.isFirebaseAvailable) return;

    try {
      final gameDate = game.gameDate;
      final now = DateTime.now();

      // Don't schedule reminders for past games
      if (gameDate.isBefore(now)) return;

      // Schedule 24 hours before
      final reminder24h = gameDate.subtract(const Duration(hours: 24));
      if (reminder24h.isAfter(now)) {
        await _scheduleNotification(
          id: '${game.gameId}_24h'.hashCode,
          title: 'תזכורת משחק',
          body: 'המשחק "$gameTitle" מתחיל מחר ב-${_formatTime(gameDate)}',
          scheduledDate: reminder24h,
          payload: 'game:${game.gameId}',
        );
      }

      // Schedule 2 hours before
      final reminder2h = gameDate.subtract(const Duration(hours: 2));
      if (reminder2h.isAfter(now)) {
        await _scheduleNotification(
          id: '${game.gameId}_2h'.hashCode,
          title: 'תזכורת משחק',
          body: 'המשחק "$gameTitle" מתחיל בעוד שעתיים',
          scheduledDate: reminder2h,
          payload: 'game:${game.gameId}',
        );
      }

      // Schedule 30 minutes before
      final reminder30m = gameDate.subtract(const Duration(minutes: 30));
      if (reminder30m.isAfter(now)) {
        await _scheduleNotification(
          id: '${game.gameId}_30m'.hashCode,
          title: 'תזכורת משחק',
          body: 'המשחק "$gameTitle" מתחיל בעוד 30 דקות',
          scheduledDate: reminder30m,
          payload: 'game:${game.gameId}',
        );
      }
    } catch (e) {
      debugPrint('Failed to schedule game reminders: $e');
    }
  }

  /// Cancel reminders for a game
  Future<void> cancelGameReminders(String gameId) async {
    if (!_initialized) await initialize();

    try {
      await _localNotifications.cancel('${gameId}_24h'.hashCode);
      await _localNotifications.cancel('${gameId}_2h'.hashCode);
      await _localNotifications.cancel('${gameId}_30m'.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel game reminders: $e');
    }
  }

  /// Schedule a notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'game_reminders',
        'תזכורות משחקים',
        channelDescription: 'תזכורות לפני משחקים',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      // Handle deep link
      debugPrint('Notification tapped: ${response.payload}');
    }
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

