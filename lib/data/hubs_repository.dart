import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/paginated_result.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';
import 'package:kattrick/services/push_notification_service.dart';

/// Repository for Hub operations
class HubsRepository {
  final FirebaseFirestore _firestore;

  HubsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get hub by ID with caching and retry
  Future<Hub?> getHub(String hubId, {bool forceRefresh = false}) async {
    if (!Env.isFirebaseAvailable) return null;

    return MonitoringService().trackOperation(
      'getHub',
      () => CacheService().getOrFetch<Hub?>(
        CacheKeys.hub(hubId),
        () => RetryService().execute(
          () async {
            final doc = await _firestore.doc(FirestorePaths.hub(hubId)).get();
            if (!doc.exists) return null;
            final data = doc.data();
            if (data == null) return null;
            return Hub.fromJson({...data, 'hubId': hubId});
          },
          config: RetryConfig.network,
          operationName: 'getHub',
        ),
        ttl: CacheService.usersTtl, // 1 hour - hubs don't change often
        forceRefresh: forceRefresh,
      ),
      metadata: {'hubId': hubId},
    );
  }

  /// Stream hub by ID
  Stream<Hub?> watchHub(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore.doc(FirestorePaths.hub(hubId)).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Hub.fromJson({...data, 'hubId': hubId});
    });
  }

  /// Create hub
  Future<String> createHub(Hub hub) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Validate user hub limit (Max 3 hubs created/managed)
      final userDoc =
          await _firestore.doc(FirestorePaths.user(hub.createdBy)).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data();
      final userHubIds = List<String>.from(userData?['hubIds'] ?? []);

      // Check how many hubs this user created
      final createdHubs = await getHubsByCreator(hub.createdBy);
      if (createdHubs.length >= 3) {
        throw Exception('Max hubs limit reached (3)');
      }

      final docRef = hub.hubId.isNotEmpty
          ? _firestore.doc(FirestorePaths.hub(hub.hubId))
          : _firestore.collection(FirestorePaths.hubs()).doc();

      final data = hub.toJson();
      // Keep hubId in data for Firestore rules validation
      data['hubId'] = docRef.id;

      // Initialize memberCount to 1 (creator)
      data['memberCount'] = 1;

      // Remove legacy 'roles' field - we now use HubMember subcollection exclusively
      data.remove('roles');

      // Use batch to write hub and add creator to members subcollection
      final batch = _firestore.batch();

      batch.set(docRef, data, SetOptions(merge: false));

      // Add creator to members subcollection
      final memberRef = docRef.collection('members').doc(hub.createdBy);
      batch.set(memberRef, {
        'hubId': docRef.id,
        'userId': hub.createdBy,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager',
        'status': 'active',
        'managerRating': 0.0,
      });

      // Update user's hubIds
      if (!userHubIds.contains(docRef.id)) {
        final userRef = _firestore.doc(FirestorePaths.user(hub.createdBy));
        batch.update(userRef, {
          'hubIds': FieldValue.arrayUnion([docRef.id]),
        });
      }

      await batch.commit();

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(docRef.id));

      return docRef.id;
    } catch (e, stackTrace) {
      ErrorHandlerService().logError(
        e,
        stackTrace: stackTrace,
        reason: 'Failed to create hub',
      );
      throw Exception('Failed to create hub: $e');
    }
  }

  /// Update hub
  Future<void> updateHub(String hubId, Map<String, dynamic> data) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.hub(hubId)).update(data);
      // Invalidate cache after successful update
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to update hub: $e');
    }
  }

  /// Delete hub
  Future<void> deleteHub(String hubId, String currentUserId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();

      // Remove hubId from the current user's hubIds array
      final userRef = _firestore.doc(FirestorePaths.user(currentUserId));
      batch.update(userRef, {
        'hubIds': FieldValue.arrayRemove([hubId]),
      });

      // Delete the hub document itself
      batch.delete(_firestore.doc(FirestorePaths.hub(hubId)));

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete hub: $e');
    }
  }

  /// Stream hubs by member
  /// Stream hubs by member
  Stream<List<Hub>> watchHubsByMember(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    // Create a stream controller to manage the subscription
    // We need to listen to user changes (hubIds) and then query hubs
    // Since we can't use switchMap easily without RxDart, we manage subscriptions manually

    // ignore: close_sinks
    final controller = StreamController<List<Hub>>();
    StreamSubscription? userSub;
    StreamSubscription? hubsSub;

    userSub =
        _firestore.doc(FirestorePaths.user(uid)).snapshots().listen((userDoc) {
      if (!userDoc.exists) {
        controller.add([]);
        return;
      }

      final hubIds = List<String>.from(userDoc.data()?['hubIds'] ?? []);
      if (hubIds.isEmpty) {
        controller.add([]);
        hubsSub?.cancel();
        hubsSub = null;
        return;
      }

      // Firestore 'in' query is limited to 10 (or 30). User limit is 10.
      hubsSub?.cancel();
      hubsSub = _firestore
          .collection(FirestorePaths.hubs())
          .where(FieldPath.documentId, whereIn: hubIds)
          .snapshots()
          .listen((snapshot) {
        final hubs = snapshot.docs
            .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
            .toList();
        // Manual sort by createdAt descending
        hubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        controller.add(hubs);
      }, onError: controller.addError);
    }, onError: controller.addError);

    controller.onCancel = () {
      userSub?.cancel();
      hubsSub?.cancel();
      controller.close();
    };

    return controller.stream;
  }

  /// Stream all hubs the user is associated with (created or joined)
  /// This relies on user.hubIds being the source of truth for all associated hubs
  Stream<List<Hub>> watchAllMyHubs(String uid) {
    return watchHubsByMember(uid);
  }

  /// Get hubs by member (non-streaming)
  /// Get hubs by member (non-streaming)
  Future<List<Hub>> getHubsByMember(String uid) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
      if (!userDoc.exists) return [];

      final hubIds = List<String>.from(userDoc.data()?['hubIds'] ?? []);
      if (hubIds.isEmpty) return [];

      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .where(FieldPath.documentId, whereIn: hubIds)
          .get();

      final hubs = snapshot.docs
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .toList();

      hubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return hubs;
    } catch (e) {
      return [];
    }
  }

  /// Add member to hub (REFACTORED - uses HubMember subcollection)
  ///
  /// This method supports both first-time joins and rejoining after leaving.
  /// Cloud Function will handle memberCount updates via trigger.
  /// FIXED: Race condition in hub membership capacity check
  ///
  /// Previously, memberCount was updated asynchronously by Cloud Function,
  /// allowing concurrent joins to exceed the 50 member limit.
  ///
  /// Now, memberCount is incremented atomically inside the transaction,
  /// ensuring accurate enforcement of capacity limits.
  Future<void> addMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Use transaction to ensure atomicity
      await _firestore.runTransaction<void>((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final userRef = _firestore.doc(FirestorePaths.user(uid));
        final memberRef = hubRef.collection('members').doc(uid);

        // Read all documents
        final hubDoc = await transaction.get(hubRef);
        final userDoc = await transaction.get(userRef);
        final memberDoc = await transaction.get(memberRef);

        if (!hubDoc.exists) throw Exception('Hub not found');
        if (!userDoc.exists) throw Exception('User not found');

        final hubData = hubDoc.data()!;
        final userData = userDoc.data()!;

        // Check Hub Capacity (Max 50 active members)
        final memberCount = hubData['memberCount'] as int? ?? 0;
        if (memberCount >= 50) {
          throw Exception('Hub is full (max 50 members)');
        }

        // Check User Hub Limit (Max 10)
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);
        if (userHubIds.length >= 10) {
          throw Exception('User has joined max hubs (10)');
        }

        // Check if already a member
        if (userHubIds.contains(hubId)) {
          return; // Already a member, idempotent
        }

        // Track whether we're adding a new active member
        bool shouldIncrementCount = false;

        // Check if user was previously a member
        if (memberDoc.exists) {
          final memberData = memberDoc.data()!;
          final status = memberData['status'] as String?;

          // If banned, reject
          if (status == 'banned') {
            throw Exception('You are banned from this hub');
          }

          // If previously left, reactivate (preserves join history)
          if (status == 'left') {
            transaction.update(memberRef, {
              'status': 'active',
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': uid,
              'statusReason': null,
            });
            // Reactivating a left member counts as adding
            shouldIncrementCount = true;
          }
          // If already active, do nothing (shouldn't happen, but safe)
        } else {
          // First-time join - create new membership
          transaction.set(memberRef, {
            'hubId': hubId,
            'userId': uid,
            'joinedAt': FieldValue.serverTimestamp(),
            'role': 'member',
            'status': 'active',
            'veteranSince': null, // Will be set by Cloud Function after 60 days
            'managerRating': 0.0,
            'lastActiveAt': null,
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': uid,
          });
          // New member counts as adding
          shouldIncrementCount = true;
        }

        // Update user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayUnion([hubId]),
        });

        // CRITICAL FIX: Increment memberCount atomically in transaction
        // This prevents race conditions where concurrent joins could exceed capacity
        if (shouldIncrementCount) {
          transaction.update(hubRef, {
            'memberCount': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // NOTE: Cloud Function (onMembershipChange) should now only verify
        // the count is correct, not set it. This transaction is the source of truth.
      });

      // CRITICAL: Sync denormalized member arrays for Firestore Rules optimization
      await _syncDenormalizedMemberArrays(hubId);

      // Subscribe to hub topic for optimized push notifications
      // This allows sending notifications to ALL hub members with a single API call
      await PushNotificationService().subscribeToHubTopic(hubId);
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from hub (REFACTORED - soft-delete via status)
  ///
  /// This performs a soft-delete by setting status='left' instead of deleting.
  /// Preserves membership history and allows rejoining.
  ///
  /// FIXED: Now decrements memberCount atomically to match addMember fix
  Future<void> removeMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final userRef = _firestore.doc(FirestorePaths.user(uid));
        final memberRef = hubRef.collection('members').doc(uid);

        // Read documents
        final memberDoc = await transaction.get(memberRef);
        final userDoc = await transaction.get(userRef);

        if (!memberDoc.exists) {
          // Already not a member, idempotent
          return;
        }

        if (!userDoc.exists) throw Exception('User not found');

        final memberData = memberDoc.data()!;
        final currentStatus = memberData['status'] as String?;

        // Only decrement if transitioning from active to left
        final shouldDecrementCount = currentStatus == 'active';

        // Soft-delete: Set status to 'left'
        transaction.update(memberRef, {
          'status': 'left',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': uid,
          'statusReason': 'User chose to leave',
        });

        // Remove from user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayRemove([hubId]),
        });

        // CRITICAL FIX: Decrement memberCount atomically in transaction
        // Matches the increment logic in addMember
        if (shouldDecrementCount) {
          transaction.update(hubRef, {
            'memberCount': FieldValue.increment(-1),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        // NOTE: Cloud Function (onMembershipChange) should now only verify
        // the count is correct, not set it. This transaction is the source of truth.
      });

      // CRITICAL: Sync denormalized member arrays for Firestore Rules optimization
      await _syncDenormalizedMemberArrays(hubId);

      // Unsubscribe from hub topic to stop receiving push notifications
      await PushNotificationService().unsubscribeFromHubTopic(hubId);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Update member role (REFACTORED - updates HubMember subcollection)
  ///
  /// Only managers can promote/demote members.
  /// Creator cannot have their role changed (always manager).
  Future<void> updateMemberRole(
      String hubId, String uid, String role, String updatedBy) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validate role
    final validRoles = ['member', 'moderator', 'manager'];
    if (!validRoles.contains(role)) {
      throw Exception('Invalid role: $role');
    }

    try {
      final hub = await getHub(hubId);
      if (hub == null) throw Exception('Hub not found');

      // Creator cannot have role changed
      if (uid == hub.createdBy) {
        throw Exception('Cannot change creator role');
      }

      // Update member role in subcollection
      await _firestore.doc('hubs/$hubId/members/$uid').update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': updatedBy,
      });

      // CRITICAL: Sync denormalized member arrays for Firestore Rules optimization
      await _syncDenormalizedMemberArrays(hubId);
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Ban a member from hub (REFACTORED - uses HubMember.status)
  ///
  /// Sets member status to 'banned' and removes from user.hubIds.
  /// Preserves all member history for audit purposes.
  Future<void> banMember(
      String hubId, String uid, String reason, String bannedBy) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final userRef = _firestore.doc(FirestorePaths.user(uid));
        final memberRef = hubRef.collection('members').doc(uid);

        final hubDoc = await transaction.get(hubRef);
        final memberDoc = await transaction.get(memberRef);

        if (!hubDoc.exists) throw Exception('Hub not found');

        final hubData = hubDoc.data()!;
        final createdBy = hubData['createdBy'] as String;

        // Cannot ban hub creator
        if (uid == createdBy) {
          throw Exception('Cannot ban hub creator');
        }

        if (!memberDoc.exists) {
          throw Exception('User is not a member of this hub');
        }

        // Update member status to banned
        transaction.update(memberRef, {
          'status': 'banned',
          'statusReason': reason,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': bannedBy,
        });

        // Remove from user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayRemove([hubId]),
        });

        // NOTE: memberCount updated by Cloud Function trigger
      });
    } catch (e) {
      throw Exception('Failed to ban member: $e');
    }
  }

  /// Set player rating for hub-specific team balancing (REFACTORED)
  ///
  /// Updates HubMember.managerRating field (1.0-10.0 scale).
  /// This rating is used by the team generation algorithm.
  Future<void> setPlayerRating(
      String hubId, String playerId, double rating) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validate rating (1.0 to 7.0 with 0.5 increments)
    if (rating < 1.0 || rating > 7.0) {
      throw Exception('Rating must be between 1.0 and 7.0');
    }

    // Validate 0.5 increments
    final remainder = (rating * 2) % 1;
    if (remainder != 0.0) {
      throw Exception('Rating must be in 0.5 increments (e.g., 3.5, 4.0, 5.5)');
    }

    try {
      // Check if member exists and is active
      final memberDoc =
          await _firestore.doc('hubs/$hubId/members/$playerId').get();

      if (!memberDoc.exists) {
        throw Exception('Player is not a member of this hub');
      }

      final memberData = memberDoc.data()!;
      if (memberData['status'] != 'active') {
        throw Exception('Cannot rate inactive member');
      }

      // Update rating in HubMember document
      await _firestore.doc('hubs/$hubId/members/$playerId').update({
        'managerRating': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to set player rating: $e');
    }
  }

  /// Get user role in hub (REFACTORED - reads from HubMember)
  Future<String?> getUserRole(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final hub = await getHub(hubId);
      if (hub == null) return null;

      // Creator is always manager
      if (uid == hub.createdBy) return 'manager';

      // Read role from HubMember subcollection
      final memberDoc = await _firestore.doc('hubs/$hubId/members/$uid').get();

      if (!memberDoc.exists) return null;

      final memberData = memberDoc.data()!;
      if (memberData['status'] != 'active') return null;

      return memberData['role'] as String? ?? 'member';
    } catch (e) {
      return null;
    }
  }

  /// Check if user is member of hub
  /// Check if user is member of hub
  Future<bool> isMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) return false;

    try {
      // Check user's hubIds (Source of Truth for client checks)
      final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
      if (!userDoc.exists) return false;

      final hubIds = List<String>.from(userDoc.data()?['hubIds'] ?? []);
      return hubIds.contains(hubId);
    } catch (e) {
      return false;
    }
  }

  /// CRITICAL: Sync denormalized member arrays (FIRESTORE RULES OPTIMIZATION)
  ///
  /// This method rebuilds the activeMemberIds, managerIds, and moderatorIds arrays
  /// in the Hub document based on the current state of the members subcollection.
  ///
  /// WHY: Eliminates expensive get() calls in Firestore security rules by denormalizing
  /// membership data directly into the Hub document for O(1) lookup.
  ///
  /// WHEN TO CALL: After any membership change (add, remove, role update)
  ///
  /// PERFORMANCE: Single collectionGroup() query + single document update
  Future<void> _syncDenormalizedMemberArrays(String hubId) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      // Fetch all active members in one query
      final membersSnap = await _firestore
          .collection('hubs/$hubId/members')
          .where('status', isEqualTo: 'active')
          .get();

      final activeMemberIds = <String>[];
      final managerIds = <String>[];
      final moderatorIds = <String>[];

      for (final doc in membersSnap.docs) {
        final data = doc.data();
        final userId = doc.id;
        final role = data['role'] as String? ?? 'member';

        activeMemberIds.add(userId);

        if (role == 'manager') {
          managerIds.add(userId);
        } else if (role == 'moderator') {
          moderatorIds.add(userId);
        }
      }

      // Update hub document with denormalized arrays
      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'activeMemberIds': activeMemberIds,
        'managerIds': managerIds,
        'moderatorIds': moderatorIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Invalidate cache to reflect new member arrays
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      debugPrint('Error syncing denormalized member arrays for hub $hubId: $e');
      // Non-fatal: rules will fall back to slower checks if arrays are stale
    }
  }

  /// Get all member IDs for a hub (REFACTORED - filters by active status)
  ///
  /// Returns list of active member user IDs.
  Future<List<String>> getHubMemberIds(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];
    try {
      final snapshot = await _firestore
          .collection('hubs/$hubId/members')
          .where('status', isEqualTo: 'active')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Failed to load hub member IDs: $e');
    }
  }

  /// Get all active members for a hub
  Future<List<HubMember>> getHubMembers(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];
    try {
      final snapshot = await _firestore.collection('hubs/$hubId/members').get();

      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            // Ensure required fields are present (handling potential bad data)
            data['hubId'] = hubId;
            data['userId'] = doc.id;
            // Default status if missing (for creators added via old createHub)
            if (data['status'] == null) data['status'] = 'active';
            return HubMember.fromJson(data);
          })
          .where((member) => member.status == HubMemberStatus.active)
          .toList();
    } catch (e) {
      debugPrint('Error in getHubMembers for hub $hubId: $e');
      throw Exception('Failed to load hub members: $e');
    }
  }

  /// Get specific members from a hub by their IDs
  /// Optimize for TeamMaker to avoid fetching all hub members
  Future<List<HubMember>> getHubMembersByIds(
      String hubId, List<String> memberIds) async {
    if (!Env.isFirebaseAvailable || memberIds.isEmpty) return [];

    try {
      // Firestore 'in' query limit is 30
      final chunks = <List<String>>[];
      for (var i = 0; i < memberIds.length; i += 30) {
        chunks.add(memberIds.sublist(
            i, i + 30 > memberIds.length ? memberIds.length : i + 30));
      }

      final results = <HubMember>[];

      for (final chunk in chunks) {
        final snapshot = await _firestore
            .collection('hubs/$hubId/members')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final chunkMembers = snapshot.docs.map((doc) {
          final data = doc.data();
          data['hubId'] = hubId;
          data['userId'] = doc.id;
          if (data['status'] == null) data['status'] = 'active';
          return HubMember.fromJson(data);
        }).toList();

        results.addAll(chunkMembers);
      }

      return results;
    } catch (e) {
      debugPrint('Error in getHubMembersByIds for hub $hubId: $e');
      throw Exception('Failed to load hub members: $e');
    }
  }

  /// Get all hubs (DEPRECATED - use getHubsPaginated instead)
  @Deprecated(
      'Use getHubsPaginated instead for better performance and pagination support')
  Future<List<Hub>> getAllHubs({int limit = 100}) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot =
          await _firestore.collection(FirestorePaths.hubs()).limit(limit).get();

      return snapshot.docs
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get hubs with pagination support
  ///
  /// Example usage:
  /// ```dart
  /// // First page
  /// final page1 = await getHubsPaginated(limit: 20);
  ///
  /// // Next page
  /// if (page1.hasMore) {
  ///   final page2 = await getHubsPaginated(
  ///     limit: 20,
  ///     startAfter: page1.lastDoc,
  ///   );
  /// }
  /// ```
  Future<PaginatedResult<Hub>> getHubsPaginated({
    int limit = 20,
    DocumentSnapshot? startAfter,
    String? orderBy = 'createdAt',
    bool descending = true,
  }) async {
    if (!Env.isFirebaseAvailable) {
      return PaginatedResult.empty();
    }

    try {
      var query = _firestore.collection(FirestorePaths.hubs()) as Query;

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply cursor
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      // Request limit+1 to detect if there are more pages
      query = query.limit(limit + 1);

      final snapshot = await query.get();

      return PaginatedResult.fromSnapshot(
        snapshot: snapshot,
        limit: limit,
        mapper: (doc) => Hub.fromJson(
            {...doc.data() as Map<String, dynamic>, 'hubId': doc.id}),
      );
    } catch (e) {
      debugPrint('Error in getHubsPaginated: $e');
      return PaginatedResult.empty();
    }
  }

  /// Find hubs within radius (km) using geohash
  /// This is an approximate search - results are filtered by actual distance

  Future<List<Hub>> findHubsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Determine precision based on radius
      int precision;
      if (radiusKm <= 0.5) {
        precision = 7; // ~150m cells
      } else if (radiusKm <= 2.5) {
        precision = 6; // ~1.2km cells
      } else if (radiusKm <= 20) {
        precision = 5; // ~5km cells
      } else if (radiusKm <= 100) {
        precision = 4; // ~40km cells
      } else {
        precision = 3; // ~150km cells
      }

      // Generate geohash
      final centerHash =
          GeohashUtils.encode(latitude, longitude, precision: precision);
      final neighbors = GeohashUtils.neighbors(centerHash);

      // Query Firestore with geohash prefixes (limited to prevent massive loads)
      final allHashes = [centerHash, ...neighbors];
      final queries = allHashes.map((hash) => _firestore
          .collection(FirestorePaths.hubs())
          .where('geohash', isGreaterThanOrEqualTo: hash)
          .where('geohash', isLessThanOrEqualTo: '$hash~')
          .limit(50) // Limit per hash query to prevent massive loads
          .get());

      final results = await Future.wait(queries);

      // Filter by actual distance
      final hubs = results
          .expand((snapshot) => snapshot.docs)
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .where((hub) {
        if (hub.location == null) return false;
        final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              hub.location!.latitude,
              hub.location!.longitude,
            ) /
            1000; // Convert to km
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      hubs.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          latitude,
          longitude,
          a.location!.latitude,
          a.location!.longitude,
        );
        final distB = Geolocator.distanceBetween(
          latitude,
          longitude,
          b.location!.latitude,
          b.location!.longitude,
        );
        return distA.compareTo(distB);
      });

      return hubs;
    } catch (e) {
      return [];
    }
  }

  /// Stream hubs within radius (km)
  /// OPTIMIZED: Only queries on initial load, not periodically
  /// Use findHubsNearby() for one-time queries or refresh on user action (pull-to-refresh)
  Stream<List<Hub>> watchHubsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    // OPTIMIZED: Return initial result only
    // This avoids unnecessary queries every 30 seconds (95% cost reduction)
    // Callers should use findHubsNearby() for one-time queries or refresh on user action
    return Stream.value([]).asyncMap((_) async {
      return await findHubsNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );
    });
  }

  /// Stream hubs created by user
  Stream<List<Hub>> watchHubsByCreator(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    try {
      return _firestore
          .collection(FirestorePaths.hubs())
          .where('createdBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        // FIX: Only print in debug mode and reduce verbosity
        if (kDebugMode && snapshot.docs.isNotEmpty) {
          // Only print if there are actual changes (not on every rebuild)
          debugPrint(
              'watchHubsByCreator: Found ${snapshot.docs.length} hubs for user $uid');
        }
        return snapshot.docs
            .map((doc) {
              try {
                return Hub.fromJson({...doc.data(), 'hubId': doc.id});
              } catch (e) {
                if (kDebugMode) {
                  debugPrint('Error parsing hub ${doc.id}: $e');
                }
                return null;
              }
            })
            .whereType<Hub>()
            .toList();
      }).handleError((error) {
        if (kDebugMode) {
          debugPrint('Error in watchHubsByCreator: $error');
        }
        // Return empty list on error instead of crashing
        return <Hub>[];
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Exception in watchHubsByCreator: $e');
      }
      return Stream.value(<Hub>[]);
    }
  }

  /// Get hubs created by user (non-streaming)
  Future<List<Hub>> getHubsByCreator(String uid) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .where('createdBy', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Set hub's primary venue (for map display)
  ///
  /// This function:
  /// - Sets the primaryVenueId and primaryVenueLocation on the hub (denormalized)
  /// - Adds venueId to hub's venueIds array if not already present
  /// - Decrements hubCount on old primary venue (if exists)
  /// - Increments hubCount on new primary venue
  ///
  /// Uses a transaction to ensure atomicity of all updates.
  ///
  /// [hubId] - ID of the hub
  /// [venueId] - ID of the venue to set as primary
  Future<void> setHubPrimaryVenue(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Get references
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final venueRef = _firestore.doc(FirestorePaths.venue(venueId));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final venueDoc = await transaction.get(venueRef);

        // Validate documents exist
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!venueDoc.exists) {
          throw Exception('Venue not found');
        }

        final hubData = hubDoc.data();
        final venueData = venueDoc.data();
        if (hubData == null) throw Exception('Hub data is null');
        if (venueData == null) throw Exception('Venue data is null');

        // Get venue location (GeoPoint)
        final venueLocation = venueData['location'];
        if (venueLocation == null) {
          throw Exception('Venue must have a location');
        }

        // Get old primary venue ID (if exists)
        final oldPrimaryVenueId = hubData['primaryVenueId'] as String?;

        // Prepare hub updates
        // Update both primaryVenueId and mainVenueId for consistency
        final hubUpdates = <String, dynamic>{
          'primaryVenueId': venueId,
          'primaryVenueLocation': venueLocation,
          'mainVenueId': venueId, // Also update mainVenueId
          'location': venueLocation, // Synchronize deprecated location field
          'geohash': venueData['geohash'] ??
              GeohashUtils.encode(
                venueLocation.latitude,
                venueLocation.longitude,
                precision: 8,
              ),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add venueId to venueIds array if not already present
        final venueIds = List<String>.from(hubData['venueIds'] ?? []);
        if (!venueIds.contains(venueId)) {
          hubUpdates['venueIds'] = FieldValue.arrayUnion([venueId]);
        }

        // Update hub
        transaction.update(hubRef, hubUpdates);

        // Handle old primary venue (if exists and different from new one)
        if (oldPrimaryVenueId != null && oldPrimaryVenueId != venueId) {
          final oldVenueRef =
              _firestore.doc(FirestorePaths.venue(oldPrimaryVenueId));
          final oldVenueDoc = await transaction.get(oldVenueRef);

          if (oldVenueDoc.exists) {
            // Decrement hubCount on old primary venue and set isMain to false
            transaction.update(oldVenueRef, {
              'hubCount': FieldValue.increment(-1),
              'isMain': false, // No longer the main venue
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update new primary venue - increment hubCount, set isMain to true, and update hubId
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(1),
          'isMain': true, // This is now the main venue for this hub
          'hubId': hubId, // Ensure hubId is set correctly
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      // Invalidate cache after successful transaction
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to set hub primary venue: $e');
    }
  }

  /// Unlink venue from hub
  ///
  /// This function:
  /// - Removes the venueId from hub's venueIds array
  /// - Decrements the venue's hubCount by 1
  /// - If the venueId is the primaryVenueId, also clears primaryVenueId and primaryVenueLocation
  ///
  /// Uses a transaction to ensure atomicity of all updates.
  ///
  /// [hubId] - ID of the hub
  /// [venueId] - ID of the venue to unlink
  Future<void> unlinkVenueFromHub(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        // Get references
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final venueRef = _firestore.doc(FirestorePaths.venue(venueId));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final venueDoc = await transaction.get(venueRef);

        // Validate documents exist
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!venueDoc.exists) {
          throw Exception('Venue not found');
        }

        final hubData = hubDoc.data()!;

        // Check if venue is actually linked to this hub
        final venueIds = List<String>.from(hubData['venueIds'] ?? []);
        final primaryVenueId = hubData['primaryVenueId'] as String?;

        if (!venueIds.contains(venueId) && primaryVenueId != venueId) {
          // Venue is not linked, nothing to do
          return;
        }

        // Prepare hub updates
        final hubUpdates = <String, dynamic>{};

        // Remove venueId from venueIds array if present
        if (venueIds.contains(venueId)) {
          hubUpdates['venueIds'] = FieldValue.arrayRemove([venueId]);
        }

        // If this is the primary venue, clear primary venue fields
        if (primaryVenueId == venueId) {
          hubUpdates['primaryVenueId'] = null;
          hubUpdates['primaryVenueLocation'] = null;
        }

        // Update hub if there are changes
        if (hubUpdates.isNotEmpty) {
          transaction.update(hubRef, hubUpdates);
        }

        // Decrement hubCount on venue
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to unlink venue from hub: $e');
    }
  }

  // Contact Message Methods

  /// Stream contact messages for Hub Manager
  Stream<List<ContactMessage>> streamContactMessages(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('contactMessages')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ContactMessage.fromJson({
          'messageId': doc.id,
          ...doc.data(),
        });
      }).toList();
    });
  }

  /// Send contact message from player to Hub Manager
  Future<void> sendContactMessage({
    required String hubId,
    required String postId,
    required String senderId,
    required String message,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Get sender info for denormalization
      final senderDoc =
          await _firestore.collection('users').doc(senderId).get();
      final senderData = senderDoc.data();

      // Get post info for context
      final postDoc = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('feed')
          .doc('posts')
          .collection('items')
          .doc(postId)
          .get();

      final postData = postDoc.data();
      final postContent = postData?['content'] as String?;

      // Create contact message
      final messageRef = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .doc();

      final contactMessage = ContactMessage(
        messageId: messageRef.id,
        hubId: hubId,
        senderId: senderId,
        postId: postId,
        message: message,
        status: 'pending',
        createdAt: DateTime.now(),
        senderName: senderData?['name'],
        senderPhotoUrl: senderData?['photoUrl'],
        senderPhone: senderData?['phoneNumber'],
        postContent: postContent != null && postContent.length > 50
            ? postContent.substring(0, 50)
            : postContent,
      );

      await messageRef.set(contactMessage.toJson());

      debugPrint('Contact message sent from $senderId to hub $hubId');
    } catch (e) {
      debugPrint('Error sending contact message: $e');
      rethrow;
    }
  }

  /// Check if user already sent a message for this post
  Future<ContactMessage?> checkExistingContactMessage(
    String hubId,
    String senderId,
    String postId,
  ) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final snapshot = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .where('senderId', isEqualTo: senderId)
          .where('postId', isEqualTo: postId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ContactMessage.fromJson({
        'messageId': snapshot.docs.first.id,
        ...snapshot.docs.first.data(),
      });
    } catch (e) {
      debugPrint('Error checking existing contact message: $e');
      return null;
    }
  }

  /// Update contact message status (for Hub Manager)
  Future<void> updateContactMessageStatus({
    required String hubId,
    required String messageId,
    required String status, // 'pending' | 'read' | 'replied'
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('contactMessages')
          .doc(messageId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating contact message status: $e');
      rethrow;
    }
  }

  /// Unban user from hub
  /// Updates HubMember status from 'banned' to 'active'
  Future<void> unbanUserFromHub(String hubId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Update HubMember status in subcollection
      await _firestore.doc('hubs/$hubId/members/$userId').update({
        'status': 'active',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system:unban',
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to unban user: $e');
    }
  }

  /// Get list of banned users for a hub (REFACTORED)
  ///
  /// Returns User objects for all members with status='banned'.
  Future<List<User>> getBannedUsers(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Query members with status='banned'
      final bannedSnapshot = await _firestore
          .collection('hubs/$hubId/members')
          .where('status', isEqualTo: 'banned')
          .get();

      if (bannedSnapshot.docs.isEmpty) return [];

      final bannedUserIds = bannedSnapshot.docs.map((doc) => doc.id).toList();

      // Fetch user documents (batch in chunks of 10 for Firestore limit)
      final List<User> bannedUsers = [];
      for (var i = 0; i < bannedUserIds.length; i += 10) {
        final chunk = bannedUserIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(FirestorePaths.users())
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          bannedUsers.add(User.fromJson({...doc.data(), 'uid': doc.id}));
        }
      }

      return bannedUsers;
    } catch (e) {
      throw Exception('Failed to load banned users: $e');
    }
  }
}
