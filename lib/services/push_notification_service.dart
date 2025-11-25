import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kickadoor/config/env.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/services/deep_link_service.dart';

/// Service for handling push notifications
class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  final List<StreamSubscription> _subscriptions = [];

  /// Initialize push notifications
  Future<void> initialize() async {
    if (!Env.isFirebaseAvailable || _initialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Initialize local notifications
        await _initializeLocalNotifications();

        // Setup message handlers
        _setupMessageHandlers();

        // Get and save FCM token
        final token = await getFCMToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
        }

        _initialized = true;
      }
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
    }
  }

  /// Dispose service
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _initialized = false;
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
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
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    _subscriptions.add(FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    }));

    // Background messages (when app is in background)
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    }));

    // App opened from terminated state
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });
  }

  /// Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'kickabout_channel',
      'Kickabout Notifications',
      channelDescription: 'Notifications for games, messages, and activities',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    if (data.isNotEmpty) {
      DeepLinkService().handleDeepLink(data);
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        // Parse payload as JSON-like string
        final data = <String, dynamic>{};
        final parts = response.payload!.split(',');
        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            data[keyValue[0].trim()] = keyValue[1].trim();
          }
        }
        DeepLinkService().handleDeepLink(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }
      return token;
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('fcm_tokens')
          .doc('tokens')
          .set({
        'tokens': FieldValue.arrayUnion([token]),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteFCMToken() async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('fcm_tokens')
          .doc('tokens')
          .update({
        'tokens': FieldValue.arrayRemove([token]),
      });

      await _messaging.deleteToken();
    } catch (e) {
      debugPrint('Failed to delete FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

