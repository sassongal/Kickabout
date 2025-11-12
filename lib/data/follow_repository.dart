import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';
import 'package:kickabout/data/users_repository.dart';
import 'package:kickabout/data/notifications_repository.dart';

/// Repository for Follow operations
class FollowRepository {
  final FirebaseFirestore _firestore;

  FollowRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Follow a user
  Future<void> follow(String followerId, String followingId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    if (followerId == followingId) {
      throw Exception('Cannot follow yourself');
    }

    try {
      final batch = _firestore.batch();

      // Add to following
      batch.set(
        _firestore
            .collection(FirestorePaths.user(followerId))
            .doc('following')
            .collection('users')
            .doc(followingId),
        {
          'createdAt': FieldValue.serverTimestamp(),
          'notificationEnabled': true,
        },
      );

      // Add to followers
      batch.set(
        _firestore
            .collection(FirestorePaths.user(followingId))
            .doc('followers')
            .collection('users')
            .doc(followerId),
        {
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      // Create notification
      await _createFollowNotification(followerId, followingId);
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  /// Unfollow a user
  Future<void> unfollow(String followerId, String followingId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();

      // Remove from following
      batch.delete(
        _firestore
            .collection(FirestorePaths.user(followerId))
            .doc('following')
            .collection('users')
            .doc(followingId),
      );

      // Remove from followers
      batch.delete(
        _firestore
            .collection(FirestorePaths.user(followingId))
            .doc('followers')
            .collection('users')
            .doc(followerId),
      );

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  /// Check if user is following another user
  Stream<bool> watchIsFollowing(String followerId, String followingId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(false);
    }

    return _firestore
        .collection(FirestorePaths.user(followerId))
        .doc('following')
        .collection('users')
        .doc(followingId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  /// Stream following list
  Stream<List<User>> watchFollowing(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('following')
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toList();
          if (userIds.isEmpty) return [];

          final usersRepo = UsersRepository(firestore: _firestore);
          return await usersRepo.getUsers(userIds);
        });
  }

  /// Stream followers list
  Stream<List<User>> watchFollowers(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('followers')
        .collection('users')
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toList();
          if (userIds.isEmpty) return [];

          final usersRepo = UsersRepository(firestore: _firestore);
          return await usersRepo.getUsers(userIds);
        });
  }

  /// Stream following count
  Stream<int> watchFollowingCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('following')
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream followers count
  Stream<int> watchFollowersCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection(FirestorePaths.user(userId))
        .doc('followers')
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> _createFollowNotification(String followerId, String followingId) async {
    final usersRepo = UsersRepository(firestore: _firestore);
    final follower = await usersRepo.getUser(followerId);
    final notificationsRepo = NotificationsRepository(firestore: _firestore);

    await notificationsRepo.createNotification(
      Notification(
        notificationId: '',
        userId: followingId,
        type: 'follow',
        title: 'עוקב חדש!',
        body: '${follower?.name ?? 'מישהו'} התחיל לעקוב אחריך',
        data: {
          'followerId': followerId,
        },
        createdAt: DateTime.now(),
      ),
    );
  }
}

