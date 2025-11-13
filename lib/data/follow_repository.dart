import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/data/users_repository.dart';

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
            .collection('users')
            .doc(followerId)
            .collection('following')
            .doc(followingId),
        {
          'createdAt': FieldValue.serverTimestamp(),
          'notificationEnabled': true,
        },
      );

      // Add to followers
      batch.set(
        _firestore
            .collection('users')
            .doc(followingId)
            .collection('followers')
            .doc(followerId),
        {
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      // Create notification (using push integration service)
      // This will be handled by the caller
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
            .collection('users')
            .doc(followerId)
            .collection('following')
            .doc(followingId),
      );

      // Remove from followers
      batch.delete(
        _firestore
            .collection('users')
            .doc(followingId)
            .collection('followers')
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
        .collection('users')
        .doc(followerId)
        .collection('following')
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
        .collection('users')
        .doc(userId)
        .collection('followers')
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
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Stream followers count
  Stream<int> watchFollowersCount(String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

