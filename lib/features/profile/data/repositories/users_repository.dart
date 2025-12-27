import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/shared/infrastructure/monitoring/monitoring_service.dart';

/// Repository for User operations
class UsersRepository {
  final FirebaseFirestore _firestore;

  UsersRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user by ID with caching and retry
  Future<User?> getUser(String uid, {bool forceRefresh = false}) async {
    if (!Env.isFirebaseAvailable) return null;

    return MonitoringService().trackOperation(
      'getUser',
      () => CacheService().getOrFetch<User?>(
        CacheKeys.user(uid),
        () => RetryService().execute(
          () async {
            final doc = await _firestore.doc(FirestorePaths.user(uid)).get();
            if (!doc.exists) return null;
            return User.fromJson({...doc.data()!, 'uid': uid});
          },
          config: RetryConfig.network,
          operationName: 'getUser',
        ),
        ttl: CacheService.usersTtl, // 1 hour
        forceRefresh: forceRefresh,
      ),
      metadata: {'uid': uid},
    );
  }

  /// Stream user by ID
  Stream<User?> watchUser(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore.doc(FirestorePaths.user(uid)).snapshots().map((doc) =>
        doc.exists ? User.fromJson({...doc.data()!, 'uid': uid}) : null);
  }

  /// Check if phone number is already in use by another user
  Future<bool> isPhoneNumberTaken(
      String phoneNumber, String excludeUserId) async {
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

      // Phase 4: Use dual-write pattern to write BOTH old and new formats
      final dualWriteData = _prepareDualWriteUserData(user);
      await _firestore.doc(FirestorePaths.user(user.uid)).set(dualWriteData);

      // Invalidate cache for this user
      CacheService().clear(CacheKeys.user(user.uid));
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

      // Invalidate cache for this user
      CacheService().clear(CacheKeys.user(uid));
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

      // Clear cache
      CacheService().clear(CacheKeys.user(uid));
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get DocumentReference for a user (for transactions)
  DocumentReference getUserRef(String uid) {
    return _firestore.doc(FirestorePaths.user(uid));
  }

  /// Update user within a transaction
  /// 
  /// This is a helper for services that need to update users in transactions.
  /// The service should handle business logic, this just performs the data update.
  void updateUserInTransaction(
    Transaction transaction,
    String uid,
    Map<String, dynamic> data,
  ) {
    final userRef = getUserRef(uid);
    transaction.update(userRef, data);
  }

  /// Get multiple users by IDs
  Future<List<User>> getUsers(List<String> uids) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      if (uids.isEmpty) return [];

      final List<User> users = [];
      final List<String> missingIds = [];

      // 1. Check Cache first
      for (final uid in uids) {
        final cachedUser =
            CacheService().get<User>(CacheKeys.user(uid)); // Check memory only
        if (cachedUser != null) {
          users.add(cachedUser);
        } else {
          missingIds.add(uid);
        }
      }

      if (missingIds.isEmpty) {
        return users;
      }

      // 2. Fetch missing users from Firestore
      // OPTIMIZED: Batch queries in parallel
      final batches = <Future<QuerySnapshot>>[];

      for (var i = 0; i < missingIds.length; i += 10) {
        final batch = missingIds.skip(i).take(10).toList();
        batches.add(
          _firestore
              .collection(FirestorePaths.users())
              .where(FieldPath.documentId, whereIn: batch)
              .get(),
        );
      }

      final results = await Future.wait(batches);

      // Process results
      for (final snapshot in results) {
        for (var doc in snapshot.docs) {
          final docData = doc.data() as Map<String, dynamic>?;
          if (docData != null) {
            final userData = Map<String, dynamic>.from(docData);
            userData['uid'] = doc.id;
            final user = User.fromJson(userData);
            users.add(user);

            // Cache the fetched user
            CacheService().set(CacheKeys.user(user.uid), user,
                ttl: CacheService.usersTtl);
          }
        }
      }

      // For users not found in Firestore, create placeholder users
      final foundIds = users.map((u) => u.uid).toSet();
      final reallyMissingIds =
          uids.where((id) => !foundIds.contains(id)).toList();

      for (final missingId in reallyMissingIds) {
        // Create a placeholder user so it shows in the list
        users.add(User(
          uid: missingId,
          name: 'משתמש לא ידוע',
          email: 'unknown@example.com',
          birthDate: DateTime(2000, 1, 1),
          createdAt: DateTime.now(),
        ));
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
        .map((snapshot) => snapshot.docs.map((doc) {
              final docData = doc.data();
              return User.fromJson({...docData, 'uid': doc.id});
            }).toList());
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
      // Query users with availability status 'available' only
      final query = _firestore
          .collection(FirestorePaths.users())
          .where('availabilityStatus', isEqualTo: 'available')
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
                ) /
                1000; // Convert to km
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
      nearbyPlayers
          .sort((a, b) => b.currentRankScore.compareTo(a.currentRankScore));

      return nearbyPlayers.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search for users by name, email, or phone.
  /// This is a basic implementation and can be slow on large datasets.
  /// For production, consider using a dedicated search service like Algolia or Typesense.
  Future<List<User>> searchUsers(String query, {int limit = 10}) async {
    if (!Env.isFirebaseAvailable || query.trim().isEmpty) {
      return [];
    }

    final lowerCaseQuery = query.toLowerCase();

    try {
      // Since Firestore doesn't support full-text search on multiple fields,
      // we perform a few separate queries and merge the results.

      // Query by name (prefix search)
      final nameQuery = _firestore
          .collection(FirestorePaths.users())
          .where('name', isGreaterThanOrEqualTo: lowerCaseQuery)
          .where('name', isLessThanOrEqualTo: '$lowerCaseQuery\uf8ff')
          .limit(limit);

      // Query by email (exact match)
      final emailQuery = _firestore
          .collection(FirestorePaths.users())
          .where('email', isEqualTo: lowerCaseQuery)
          .limit(1);

      // Execute queries in parallel
      final results = await Future.wait([nameQuery.get(), emailQuery.get()]);

      final users = <String, User>{}; // Use a map to avoid duplicates
      for (final snapshot in results) {
        for (final doc in snapshot.docs) {
          users[doc.id] = User.fromJson({...doc.data(), 'uid': doc.id});
        }
      }
      return users.values.toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      return [];
    }
  }

  /// Block a user
  Future<void> blockUser(String currentUserId, String userToBlockId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    try {
      await _firestore
          .collection(FirestorePaths.users())
          .doc(currentUserId)
          .update({
        'blockedUserIds': FieldValue.arrayUnion([userToBlockId]),
      });
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String currentUserId, String userToUnblockId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }
    try {
      await _firestore
          .collection(FirestorePaths.users())
          .doc(currentUserId)
          .update({
        'blockedUserIds': FieldValue.arrayRemove([userToUnblockId]),
      });
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }

  /// Get blocked users for a given user
  Future<List<User>> getBlockedUsers(String userId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final user = await getUser(userId);
      if (user == null || user.blockedUserIds.isEmpty) {
        return [];
      }

      return await getUsers(user.blockedUserIds);
    } catch (e) {
      debugPrint('Error getting blocked users: $e');
      return [];
    }
  }

  /// Check if a user is blocked by another user
  Future<bool> isUserBlocked(String currentUserId, String targetUserId) async {
    if (!Env.isFirebaseAvailable) return false;

    try {
      final user = await getUser(currentUserId);
      if (user == null) return false;
      return user.blockedUserIds.contains(targetUserId);
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// Get users by phone number
  Future<List<User>> getUsersByPhone(
    String phoneNumber, {
    bool fictitiousOnly = false,
  }) async {
    if (!Env.isFirebaseAvailable) return [];
    if (phoneNumber.trim().isEmpty) return [];

    try {
      var query = _firestore
          .collection(FirestorePaths.users())
          .where('phoneNumber', isEqualTo: phoneNumber.trim());

      if (fictitiousOnly) {
        query = query.where('isFictitious', isEqualTo: true);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting users by phone: $e');
      return [];
    }
  }

  /// Generate a unique user ID
  /// Used by presentation layer to create new fictitious/manual players
  String generateUserId() {
    return _firestore.collection('users').doc().id;
  }

  /// **Phase 4 Dual-Write Helper**: Prepare user data with BOTH old and new formats
  ///
  /// This critical method ensures backward compatibility during migration by:
  /// 1. Writing to new value object fields (privacy, notifications, userLocation)
  /// 2. Writing to old map/flat fields (privacySettings, notificationPreferences, location/geohash/city/region)
  /// 3. Allowing gradual migration without breaking existing code
  ///
  /// ⚠️ DUAL-WRITE PATTERN: Remove this after migration is complete (Phase 4.6.4)
  Map<String, dynamic> _prepareDualWriteUserData(User user) {
    final json = user.toJson();

    // Get effective values (from new value objects or old maps)
    final effectivePrivacy = user.effectivePrivacy;
    final effectiveNotifications = user.effectiveNotifications;
    final effectiveLocation = user.effectiveLocation;

    // Write to BOTH formats for backward compatibility
    return {
      ...json,
      // OLD format: Maps (for existing code that reads from privacySettings/notificationPreferences)
      'privacySettings': {
        'hideFromSearch': effectivePrivacy.hideFromSearch,
        'hideEmail': effectivePrivacy.hideEmail,
        'hidePhone': effectivePrivacy.hidePhone,
        'hideCity': effectivePrivacy.hideCity,
        'hideStats': effectivePrivacy.hideStats,
        'hideRatings': effectivePrivacy.hideRatings,
        'allowHubInvites': effectivePrivacy.allowHubInvites,
      },
      'notificationPreferences': {
        'game_reminder': effectiveNotifications.gameReminder,
        'message': effectiveNotifications.message,
        'like': effectiveNotifications.like,
        'comment': effectiveNotifications.comment,
        'signup': effectiveNotifications.signup,
        'new_follower': effectiveNotifications.newFollower,
        'hub_chat': effectiveNotifications.hubChat,
        'new_comment': effectiveNotifications.newComment,
        'new_game': effectiveNotifications.newGame,
      },
      // OLD format: Flat location fields (for existing code that reads from location/geohash/city/region)
      'location': effectiveLocation?.location,
      'geohash': effectiveLocation?.geohash,
      'city': effectiveLocation?.city,
      'region': effectiveLocation?.region,
      // NEW format: Value objects (for new code using user.effectivePrivacy/effectiveNotifications/effectiveLocation)
      'privacy': effectivePrivacy.toJson(),
      'notifications': effectiveNotifications.toJson(),
      'userLocation': effectiveLocation?.toJson(),
    };
  }
}
