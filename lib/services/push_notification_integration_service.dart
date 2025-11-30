import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:flutter/foundation.dart';

/// Service for integrating push notifications with app events
class PushNotificationIntegrationService {
  final FirebaseFirestore _firestore;

  PushNotificationIntegrationService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Send notification for new game
  Future<void> notifyNewGame({
    required String gameId,
    required String hubId,
    required String creatorName,
    required String hubName,
    required List<String> memberIds,
    required String excludeUserId,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      // Get FCM tokens for all members except creator
      final tokens = await _getFCMTokens(memberIds, excludeUserId);

      if (tokens.isEmpty) return;

      // Send notification via FCM
      // Note: In production, you'd use Firebase Cloud Functions for this
      // For now, we'll create in-app notifications
      for (final memberId in memberIds) {
        if (memberId == excludeUserId) continue;

        try {
          final notification = Notification(
            notificationId: '',
            userId: memberId,
            type: 'new_game',
            title: 'משחק חדש!',
            body: '$creatorName יצר משחק חדש ב-$hubName',
            data: {
              'gameId': gameId,
              'hubId': hubId,
              'type': 'new_game',
            },
            entityId: gameId, // ID of related entity (gameId)
            hubId: hubId, // Hub ID for hub-related notifications
            createdAt: DateTime.now(),
          );

          // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
          await _firestore
              .collection('notifications')
              .doc(notification.userId)
              .collection('items')
              .doc()
              .set(notification.toJson());

          // Also send push notification if token exists
          final token = await _getUserFCMToken(memberId);
          if (token != null) {
            // In production, use Firebase Cloud Functions to send FCM
            debugPrint('Would send FCM to $memberId: $token');
          }
        } catch (e) {
          debugPrint('Failed to notify user $memberId: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to send new game notifications: $e');
    }
  }

  /// Send notification for new event
  Future<void> notifyNewEvent({
    required String eventId,
    required String hubId,
    required String creatorName,
    required String hubName,
    required List<String> memberIds,
    required String excludeUserId,
    required String eventTitle,
    required DateTime eventDate,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      // Get FCM tokens for all members except creator
      final tokens = await _getFCMTokens(memberIds, excludeUserId);

      if (tokens.isEmpty) return;

      // Send notification via FCM
      // Note: In production, you'd use Firebase Cloud Functions for this
      // For now, we'll create in-app notifications
      for (final memberId in memberIds) {
        if (memberId == excludeUserId) continue;

        try {
          final notification = Notification(
            notificationId: '',
            userId: memberId,
            type: 'new_event',
            title: 'אירוע חדש!',
            body: '$creatorName יצר אירוע חדש ב-$hubName: $eventTitle',
            data: {
              'eventId': eventId,
              'hubId': hubId,
              'type': 'new_event',
              'eventDate': eventDate.toIso8601String(),
            },
            entityId: eventId, // ID of related entity (eventId)
            hubId: hubId, // Hub ID for hub-related notifications
            createdAt: DateTime.now(),
          );

          // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
          await _firestore
              .collection('notifications')
              .doc(notification.userId)
              .collection('items')
              .doc()
              .set(notification.toJson());

          // Also send push notification if token exists
          final token = await _getUserFCMToken(memberId);
          if (token != null) {
            // In production, use Firebase Cloud Functions to send FCM
            debugPrint('Would send FCM to $memberId: $token');
          }
        } catch (e) {
          debugPrint('Failed to notify user $memberId: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to send new event notifications: $e');
    }
  }

  /// Send notification for new message
  Future<void> notifyNewMessage({
    required String hubId,
    required String senderName,
    required String message,
    required List<String> memberIds,
    required String excludeUserId,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      for (final memberId in memberIds) {
        if (memberId == excludeUserId) continue;

        try {
          final notification = Notification(
            notificationId: '',
            userId: memberId,
            type: 'hub_chat',
            title: 'הודעה חדשה',
            body: '$senderName: $message',
            data: {
              'hubId': hubId,
              'type': 'hub_chat',
            },
            hubId: hubId, // Hub ID for hub-related notifications
            createdAt: DateTime.now(),
          );

          // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
          await _firestore
              .collection('notifications')
              .doc(notification.userId)
              .collection('items')
              .doc()
              .set(notification.toJson());
        } catch (e) {
          debugPrint('Failed to notify user $memberId: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to send message notifications: $e');
    }
  }

  /// Send notification for new comment
  Future<void> notifyNewComment({
    required String postId,
    required String hubId,
    required String commenterName,
    required String postAuthorId,
  }) async {
    if (!Env.isFirebaseAvailable) return;
    if (postAuthorId.isEmpty) return;

    try {
      final notification = Notification(
        notificationId: '',
        userId: postAuthorId,
        type: 'new_comment',
        title: 'תגובה חדשה',
        body: '$commenterName הגיב על הפוסט שלך',
        data: {
          'postId': postId,
          'hubId': hubId,
          'type': 'new_comment',
        },
        entityId: postId, // ID of related entity (postId)
        hubId: hubId, // Hub ID for hub-related notifications
        createdAt: DateTime.now(),
      );

      // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
      await _firestore
          .collection('notifications')
          .doc(notification.userId)
          .collection('items')
          .doc()
          .set(notification.toJson());
    } catch (e) {
      debugPrint('Failed to send comment notification: $e');
    }
  }

  /// Send notification for new follow
  Future<void> notifyNewFollow({
    required String followerName,
    required String followingId,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final notification = Notification(
        notificationId: '',
        userId: followingId,
        type: 'new_follower',
        title: 'עוקב חדש',
        body: '$followerName התחיל לעקוב אחריך',
        data: {
          'type': 'new_follower',
        },
        createdAt: DateTime.now(),
      );

      // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
      await _firestore
          .collection('notifications')
          .doc(notification.userId)
          .collection('items')
          .doc()
          .set(notification.toJson());
    } catch (e) {
      debugPrint('Failed to send follow notification: $e');
    }
  }

  /// Send notification for game reminder
  Future<void> notifyGameReminder({
    required String gameId,
    required String hubId,
    required String gameTitle,
    required DateTime gameDate,
    required List<String> signedUpPlayerIds,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      for (final playerId in signedUpPlayerIds) {
        try {
          final notification = Notification(
            notificationId: '',
            userId: playerId,
            type: 'game_reminder',
            title: 'תזכורת משחק',
            body: 'המשחק "$gameTitle" מתחיל ב-${_formatDateTime(gameDate)}',
            data: {
              'gameId': gameId,
              'hubId': hubId,
              'type': 'game_reminder',
            },
            entityId: gameId, // ID of related entity (gameId)
            hubId: hubId, // Hub ID for hub-related notifications
            createdAt: DateTime.now(),
          );

          // Use NotificationsRepository structure: notifications/{userId}/items/{notificationId}
          await _firestore
              .collection('notifications')
              .doc(notification.userId)
              .collection('items')
              .doc()
              .set(notification.toJson());
        } catch (e) {
          debugPrint('Failed to notify player $playerId: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to send game reminder notifications: $e');
    }
  }

  /// Get FCM tokens for users
  Future<List<String>> _getFCMTokens(List<String> userIds, String excludeUserId) async {
    final tokens = <String>[];

    for (final userId in userIds) {
      if (userId == excludeUserId) continue;

      final token = await _getUserFCMToken(userId);
      if (token != null) {
        tokens.add(token);
      }
    }

    return tokens;
  }

  /// Get FCM token for a user
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcm_tokens')
          .doc('tokens')
          .get();

      if (!doc.exists) return null;

      final data = doc.data();
      final tokens = data?['tokens'] as List<dynamic>?;
      if (tokens == null || tokens.isEmpty) return null;

      return tokens.first as String;
    } catch (e) {
      debugPrint('Failed to get FCM token for $userId: $e');
      return null;
    }
  }

  /// Format date time for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
