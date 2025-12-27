import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';

/// Repository for Notifications operations
class NotificationsRepository {
  final FirebaseFirestore _firestore;

  NotificationsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream notifications for a user
  Stream<List<Notification>> watchNotifications(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Notification.fromJson({...doc.data(), 'notificationId': doc.id}))
            .toList());
  }

  /// Stream unread notifications count
  Stream<int> watchUnreadCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .doc(userId)
        .collection('items')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Create notification
  Future<String> createNotification(Notification notification) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = notification.toJson();
      data.remove('notificationId');

      final docRef = _firestore
          .collection('notifications')
          .doc(notification.userId)
          .collection('items')
          .doc();

      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String userId, String notificationId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final snapshot = await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all as read: $e');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(String userId, String notificationId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}

