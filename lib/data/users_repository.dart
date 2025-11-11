import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';

/// Repository for User operations
class UsersRepository {
  final FirebaseFirestore _firestore;

  UsersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user by ID
  Future<User?> getUser(String uid) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.doc(FirestorePaths.user(uid)).get();
      if (!doc.exists) return null;
      return User.fromJson({...doc.data()!, 'uid': uid});
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Stream user by ID
  Stream<User?> watchUser(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.user(uid))
        .snapshots()
        .map((doc) => doc.exists
            ? User.fromJson({...doc.data()!, 'uid': uid})
            : null);
  }

  /// Create or update user
  Future<void> setUser(User user) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = user.toJson();
      data.remove('uid'); // Remove uid from data (it's the document ID)
      await _firestore.doc(FirestorePaths.user(user.uid)).set(data);
    } catch (e) {
      throw Exception('Failed to set user: $e');
    }
  }

  /// Update user
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.user(uid)).update(data);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.user(uid)).delete();
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get multiple users by IDs
  Future<List<User>> getUsers(List<String> uids) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      if (uids.isEmpty) return [];
      
      // Firestore 'in' query limit is 10, so we need to batch
      final List<User> users = [];
      for (var i = 0; i < uids.length; i += 10) {
        final batch = uids.skip(i).take(10).toList();
        final docs = await _firestore
            .collection(FirestorePaths.users())
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        
        for (var doc in docs.docs) {
          users.add(User.fromJson({...doc.data(), 'uid': doc.id}));
        }
      }
      return users;
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Stream users by hub membership
  Stream<List<User>> watchUsersByHub(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.users())
        .where('hubIds', arrayContains: hubId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
            .toList());
  }
}

