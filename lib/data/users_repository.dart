import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:flutter/foundation.dart';

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

  /// Check if phone number is already in use by another user
  Future<bool> isPhoneNumberTaken(String phoneNumber, String excludeUserId) async {
    if (!Env.isFirebaseAvailable) return false;
    if (phoneNumber.trim().isEmpty) return false;

    try {
      final query = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber.trim())
          .limit(1)
          .get();

      // If no results, phone is available
      if (query.docs.isEmpty) return false;

      // If the only result is the current user, phone is available
      if (query.docs.length == 1 && query.docs.first.id == excludeUserId) {
        return false;
      }

      // Phone is taken by another user
      return true;
    } catch (e) {
      throw Exception('Failed to check phone number: $e');
    }
  }

  /// Create or update user
  Future<void> setUser(User user) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate phone number uniqueness if provided
      if (user.phoneNumber != null && user.phoneNumber!.trim().isNotEmpty) {
        final isTaken = await isPhoneNumberTaken(user.phoneNumber!, user.uid);
        if (isTaken) {
          throw Exception('מספר הטלפון כבר בשימוש על ידי משתמש אחר');
        }
      }

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
      
      // For users not found in Firestore, create placeholder users
      // so they still appear in the list (they might be manual players or users without profiles)
      final foundIds = docs.docs.map((d) => d.id).toSet();
      final missingIds = batch.where((id) => !foundIds.contains(id)).toList();
      
      for (final missingId in missingIds) {
        // Create a placeholder user so it shows in the list
        users.add(User(
          uid: missingId,
          name: 'משתמש לא ידוע',
          email: 'unknown@example.com',
          createdAt: DateTime.now(),
        ));
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

  /// Get all users (with limit for pagination)
  Future<List<User>> getAllUsers({int limit = 100}) async {
    if (!Env.isFirebaseAvailable) return <User>[];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.users())
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();
    } catch (e) {
      return <User>[];
    }
  }

  /// Find available players nearby
  Future<List<User>> findAvailablePlayersNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String excludeUserId = '',
    int limit = 5,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Query users with availability status 'available' or 'busy'
      final query = _firestore
          .collection(FirestorePaths.users())
          .where('availabilityStatus', whereIn: ['available', 'busy'])
          .limit(50); // Get more to filter by distance

      final snapshot = await query.get();

      // Filter by distance and exclude current user
      final users = snapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
          .where((user) => user.uid != excludeUserId && user.location != null)
          .map((user) {
            final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              user.location!.latitude,
              user.location!.longitude,
            ) / 1000; // Convert to km
            return MapEntry(user, distance);
          })
          .where((entry) => entry.value <= radiusKm)
          .toList();

      // Sort by distance and availability (available first)
      users.sort((a, b) {
        final aAvailable = a.key.availabilityStatus == 'available' ? 0 : 1;
        final bAvailable = b.key.availabilityStatus == 'available' ? 0 : 1;
        if (aAvailable != bAvailable) return aAvailable.compareTo(bAvailable);
        return a.value.compareTo(b.value);
      });

      return users.take(limit).map((entry) => entry.key).toList();
    } catch (e) {
      return [];
    }
  }

  /// Get recommended players (available, nearby, good rating)
  Future<List<User>> getRecommendedPlayers({
    required double latitude,
    required double longitude,
    String excludeUserId = '',
    int limit = 3,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Get available players within 10km
      final nearbyPlayers = await findAvailablePlayersNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: 10.0,
        excludeUserId: excludeUserId,
        limit: 20, // Get more to filter by rating
      );

      // Sort by rating (higher is better) and take top players
      nearbyPlayers.sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore));

      return nearbyPlayers.take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}

