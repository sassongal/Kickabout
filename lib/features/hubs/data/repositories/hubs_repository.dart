import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/shared/infrastructure/firestore/paginated_result.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/shared/infrastructure/logging/error_handler_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/shared/infrastructure/monitoring/monitoring_service.dart';
import 'package:kattrick/services/push_notification_service.dart';

/// Result of hub creation limit check
class HubCreationCheckResult {
  final bool canCreate;
  final HubCreationLimitReason? reason;
  final String? message;
  final int? currentCount;
  final int? maxCount;

  HubCreationCheckResult({
    required this.canCreate,
    this.reason,
    this.message,
    this.currentCount,
    this.maxCount,
  });
}

/// Reasons why hub creation might be limited
enum HubCreationLimitReason {
  limitReached,
  transientError,
  firebaseUnavailable,
}

/// Exception thrown when hub creation limit is reached
class HubCreationLimitException implements Exception {
  final String message;
  final int currentCount;
  final int maxCount;

  HubCreationLimitException({
    required this.message,
    required this.currentCount,
    required this.maxCount,
  });

  @override
  String toString() => message;
}

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
        () async {
          try {
            return await RetryService().execute(
              () async {
                final doc =
                    await _firestore.doc(FirestorePaths.hub(hubId)).get();
                if (!doc.exists) return null;
                final data = doc.data();
                if (data == null) return null;
                return Hub.fromJson({...data, 'hubId': hubId});
              },
              config: RetryConfig.network,
              operationName: 'getHub',
            );
          } catch (e) {
            // If permission denied, log and return null instead of crashing
            if (e.toString().contains('permission-denied')) {
              // 🔍 DIAGNOSTIC: Enhanced logging to track permission-denied errors
              final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
              debugPrint('⚠️ PERMISSION DENIED: getHub($hubId)');
              debugPrint('   User: uid=${currentUser?.uid ?? "NULL"}, email=${currentUser?.email ?? "N/A"}');
              debugPrint('   Error: $e');
              debugPrint('   Likely cause: User not in hub.activeMemberIds or denormalized array out of sync');
              debugPrint('   Check: Firestore Console → hubs/$hubId → activeMemberIds array');
              return null;
            }
            rethrow;
          }
        },
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
    }).handleError((error) {
      // If permission denied, log and return null instead of crashing
      if (error.toString().contains('permission-denied')) {
        // 🔍 DIAGNOSTIC: Enhanced logging to track permission-denied errors
        final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
        debugPrint('⚠️ PERMISSION DENIED: watchHub($hubId)');
        debugPrint('   User: uid=${currentUser?.uid ?? "NULL"}, email=${currentUser?.email ?? "N/A"}');
        debugPrint('   Error: $error');
        debugPrint('   Likely cause: User not in hub.activeMemberIds or denormalized array out of sync');
        return null;
      }
      // Re-throw other errors
      throw error;
    });
  }

  /// Create hub (pure data access - business logic moved to HubCreationService)
  ///
  /// This method only handles the data write operation.
  /// For business logic (validation, orchestration), use HubCreationService.createHub()
  Future<String> createHub(Hub hub) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final docRef = hub.hubId.isNotEmpty
          ? _firestore.doc(FirestorePaths.hub(hub.hubId))
          : _firestore.collection(FirestorePaths.hubs()).doc();

      final data = hub.toJson();
      data['hubId'] = docRef.id;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.set(data, SetOptions(merge: false));

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

    debugPrint('🗑️ Starting hub deletion: $hubId by user $currentUserId');

    try {
      // First, verify the hub exists and user has permission
      final hubDoc = await _firestore.doc(FirestorePaths.hub(hubId)).get();
      if (!hubDoc.exists) {
        debugPrint('⚠️ Hub $hubId does not exist, skipping deletion');
        return; // Hub already deleted, no error needed
      }

      final hubData = hubDoc.data();
      final createdBy = hubData?['createdBy'] as String?;

      if (createdBy != currentUserId) {
        debugPrint('❌ User $currentUserId is not the creator of hub $hubId');
        throw Exception('Only the hub creator can delete the hub');
      }

      debugPrint('📋 Handling hub-related data...');

      // 1. Handle games associated with this hub
      final gamesSnapshot = await _firestore
          .collection(FirestorePaths.games())
          .where('hubId', isEqualTo: hubId)
          .get();

      debugPrint('   Found ${gamesSnapshot.docs.length} games associated with hub');

      // Cancel future games and nullify hubId on all games
      for (final gameDoc in gamesSnapshot.docs) {
        final gameData = gameDoc.data();
        final status = gameData['status'] as String?;
        final gameDate = (gameData['gameDate'] as Timestamp?)?.toDate();

        final updates = <String, dynamic>{
          'hubId': null, // Orphan the game from the hub
        };

        // Cancel if game is not completed/cancelled and is in the future
        if (status != null &&
            status != 'completed' &&
            status != 'cancelled' &&
            gameDate != null &&
            gameDate.isAfter(DateTime.now())) {
          updates['status'] = 'cancelled';
          debugPrint('   Cancelling future game: ${gameDoc.id}');
        }

        await gameDoc.reference.update(updates);
      }

      debugPrint('📋 Deleting hub subcollections...');

      // 2. Delete all members subcollection documents and remove hubId from users
      final membersSnapshot = await _firestore
          .collection(FirestorePaths.hubMembers(hubId))
          .get();

      debugPrint('   Found ${membersSnapshot.docs.length} members to delete');

      // Firestore batch has a limit of 500 operations
      // We'll use multiple batches if needed
      var batch = _firestore.batch();
      var operationCount = 0;
      const maxBatchSize = 500;

      // Remove hubId from all members' user documents
      for (final memberDoc in membersSnapshot.docs) {
        final userId = memberDoc.id;

        // Remove hubId from user's hubIds array
        final userRef = _firestore.doc(FirestorePaths.user(userId));
        batch.update(userRef, {
          'hubIds': FieldValue.arrayRemove([hubId]),
        });
        operationCount++;

        // Delete the member document
        batch.delete(memberDoc.reference);
        operationCount++;

        if (operationCount >= maxBatchSize) {
          await batch.commit();
          debugPrint('   ✅ Committed batch of $operationCount operations');
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // 3. Delete all events subcollection documents
      final eventsSnapshot = await _firestore
          .collection(FirestorePaths.hubEvents(hubId))
          .get();

      debugPrint('   Found ${eventsSnapshot.docs.length} events to delete');

      for (final eventDoc in eventsSnapshot.docs) {
        batch.delete(eventDoc.reference);
        operationCount++;

        if (operationCount >= maxBatchSize) {
          await batch.commit();
          debugPrint('   ✅ Committed batch of $operationCount deletions');
          batch = _firestore.batch();
          operationCount = 0;
        }
      }

      // 4. Delete the hub document itself
      batch.delete(_firestore.doc(FirestorePaths.hub(hubId)));
      operationCount++;

      // Commit the final batch
      await batch.commit();
      debugPrint('   ✅ Committed final batch with hub document');

      debugPrint('✅ Hub $hubId and all subcollections successfully deleted');

      // Verify deletion
      final verifyDoc = await _firestore.doc(FirestorePaths.hub(hubId)).get();
      if (verifyDoc.exists) {
        debugPrint('❌ WARNING: Hub $hubId still exists after deletion!');
        throw Exception('Hub deletion verification failed');
      }

      debugPrint('✅ Hub deletion verified');

    } catch (e) {
      debugPrint('❌ Failed to delete hub $hubId: $e');
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

      // FIX: Use individual document reads instead of whereIn query
      // This prevents the entire query from failing if one hub has permission issues
      // Firestore 'in' query fails if ANY document doesn't pass rules
      hubsSub?.cancel();

      // Create individual streams for each hub
      final hubStreams = hubIds.map((hubId) {
        return _firestore.doc(FirestorePaths.hub(hubId)).snapshots().map((doc) {
          if (!doc.exists) return null;
          try {
            return Hub.fromJson({...doc.data()!, 'hubId': doc.id});
          } catch (e) {
            debugPrint('Error parsing hub $hubId: $e');
            return null;
          }
        }).handleError((error) {
          // Silently skip hubs that fail permission checks
          // 🔍 DIAGNOSTIC: Enhanced logging for permission errors in stream
          if (error.toString().contains('permission-denied')) {
            final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
            debugPrint('⚠️ PERMISSION DENIED: watchHubsByMember stream for hub $hubId');
            debugPrint('   User: uid=${currentUser?.uid ?? "NULL"}');
            debugPrint('   Likely cause: User not in hub.activeMemberIds');
          } else {
            debugPrint('⚠️ Cannot read hub $hubId: $error');
          }
          return null;
        });
      }).toList();

      // Use RxDart to combine all streams
      // This allows us to get all hubs that pass permission checks
      // even if some fail
      hubsSub = Rx.combineLatest(
        hubStreams,
        (List<Hub?> hubs) {
          final validHubs = hubs.whereType<Hub>().toList();
          // Manual sort by createdAt descending
          validHubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return validHubs;
        },
      ).listen(
        (hubs) => controller.add(hubs),
        onError: (error) {
          debugPrint('Error in watchHubsByMember: $error');
          controller.addError(error);
        },
      );
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
  /// FIX: Uses individual document reads to avoid all-or-nothing whereIn failures
  Future<List<Hub>> getHubsByMember(String uid) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final userDoc = await _firestore.doc(FirestorePaths.user(uid)).get();
      if (!userDoc.exists) return [];

      final hubIds = List<String>.from(userDoc.data()?['hubIds'] ?? []);
      if (hubIds.isEmpty) return [];

      // 🔍 DIAGNOSTIC: Log hubIds being queried
      debugPrint('📊 getHubsByMember: Fetching ${hubIds.length} hubs for user $uid');

      // FIX: Use individual document reads instead of whereIn query
      // Firestore whereIn queries fail ENTIRELY if ANY document fails permission check
      // This approach gracefully skips permission-denied hubs instead of failing completely
      final hubs = <Hub>[];
      int successCount = 0;
      int permissionDeniedCount = 0;
      int errorCount = 0;

      for (final hubId in hubIds) {
        try {
          final hub = await getHub(hubId);
          if (hub != null) {
            hubs.add(hub);
            successCount++;
          } else {
            // getHub returns null on permission-denied
            permissionDeniedCount++;
          }
        } catch (e) {
          // 🔍 DIAGNOSTIC: Log individual hub fetch failures
          debugPrint('⚠️ Failed to fetch hub $hubId: $e');
          errorCount++;
        }
      }

      // 🔍 DIAGNOSTIC: Log results summary
      debugPrint('📊 getHubsByMember results: $successCount success, $permissionDeniedCount denied, $errorCount errors out of ${hubIds.length} total');
      if (permissionDeniedCount > 0) {
        debugPrint('   ⚠️ $permissionDeniedCount hubs failed permission check - check activeMemberIds sync');
      }

      hubs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return hubs;
    } catch (e) {
      // 🔍 DIAGNOSTIC: Log complete failures
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      debugPrint('⚠️ getHubsByMember FAILED for user $uid');
      debugPrint('   Current user: uid=${currentUser?.uid ?? "NULL"}');
      debugPrint('   Error: $e');
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

        // Check Hub Capacity (respects hub.settings.maxMembers, default 50)
        final memberCount = hubData['memberCount'] as int? ?? 0;
        final settings = hubData['settings'] as Map<String, dynamic>? ?? {};
        final maxMembers = settings['maxMembers'] as int? ?? 50;

        if (maxMembers > 0 && memberCount >= maxMembers) {
          throw Exception('Hub is full (max $maxMembers members)');
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

      // ARCHITECTURAL FIX: Cloud Function now handles denormalized array sync automatically
      // The onMembershipChange trigger (functions/src/triggers/membershipCounters.js)
      // syncs activeMemberIds, managerIds, moderatorIds whenever a HubMember is written.
      // This eliminates the race condition where client-side sync could fail after transaction.
      //
      // REMOVED: await syncDenormalizedMemberArrays(hubId);
      // Cloud Function handles this atomically via triggers.

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

      // ARCHITECTURAL FIX: Cloud Function handles denormalized array sync
      // REMOVED: await syncDenormalizedMemberArrays(hubId);

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

      // ARCHITECTURAL FIX: Cloud Function handles denormalized array sync
      // REMOVED: await syncDenormalizedMemberArrays(hubId);
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

  /// Stream membership for a user in a hub (data access)
  Stream<HubMember?> watchMembership(String hubId, String userId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore.doc('hubs/$hubId/members/$userId').snapshots().map((doc) {
      if (!doc.exists) return null;

      try {
        final data = doc.data()!;
        return HubMember.fromJson({
          ...data,
          'hubId': hubId,
          'userId': userId,
        });
      } catch (e) {
        debugPrint('Error parsing HubMember: $e');
        return null;
      }
    });
  }

  /// Get membership once (data access)
  Future<HubMember?> getMembership(String hubId, String userId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.doc('hubs/$hubId/members/$userId').get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      return HubMember.fromJson({
        ...data,
        'hubId': hubId,
        'userId': userId,
      });
    } catch (e) {
      debugPrint('Error getting HubMember: $e');
      return null;
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
  /// Sync denormalized member arrays (public for services to use)
  Future<void> syncDenormalizedMemberArrays(String hubId) async {
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

  /// Get hub members with pagination support
  ///
  /// Returns active members only, ordered by joinedAt (newest first)
  ///
  /// Usage:
  /// ```dart
  /// final page1 = await getHubMembersPaginated(hubId: 'hub123', limit: 20);
  /// // If page1.hasMore:
  /// final page2 = await getHubMembersPaginated(
  ///   hubId: 'hub123',
  ///   limit: 20,
  ///   startAfter: page1.lastDoc,
  /// );
  /// ```
  Future<PaginatedResult<HubMember>> getHubMembersPaginated({
    required String hubId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (!Env.isFirebaseAvailable) {
      return PaginatedResult.empty();
    }

    try {
      // Request limit+1 to detect if there are more pages
      Query query = _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('members')
          .where('status', isEqualTo: 'active')
          .orderBy('joinedAt', descending: true)
          .limit(limit + 1);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      return PaginatedResult.fromSnapshot(
        snapshot: snapshot,
        limit: limit,
        mapper: (doc) {
          final data = doc.data() as Map<String, dynamic>;
          return HubMember.fromJson({
            ...data,
            'userId': doc.id,
            'hubId': hubId,
          });
        },
      );
    } catch (e) {
      debugPrint('Error in getHubMembersPaginated for hub $hubId: $e');
      return PaginatedResult.empty();
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
      final queries = allHashes.map((hash) async {
        try {
          final snapshot = await _firestore
              .collection(FirestorePaths.hubs())
              .where('geohash', isGreaterThanOrEqualTo: hash)
              .where('geohash', isLessThanOrEqualTo: '$hash~')
              .limit(50) // Limit per hash query to prevent massive loads
              .get();
          return snapshot.docs;
        } catch (e) {
          // If query fails (e.g., permission denied), return empty list
          debugPrint('⚠️ Geohash query failed for $hash: $e');
          return <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        }
      });

      final results = await Future.wait(queries);

      // Filter by actual distance
      // Use primaryVenueLocation (preferred) or fallback to location (deprecated)
      final hubs = results
          .expand((docs) => docs)
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .where((hub) {
        final hubLocation = hub.primaryVenueLocation ?? hub.location;
        if (hubLocation == null) return false;
        final distance = Geolocator.distanceBetween(
              latitude,
              longitude,
              hubLocation.latitude,
              hubLocation.longitude,
            ) /
            1000; // Convert to km
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      hubs.sort((a, b) {
        final locA = a.primaryVenueLocation ?? a.location;
        final locB = b.primaryVenueLocation ?? b.location;
        if (locA == null || locB == null) return 0;

        final distA = Geolocator.distanceBetween(
          latitude,
          longitude,
          locA.latitude,
          locA.longitude,
        );
        final distB = Geolocator.distanceBetween(
          latitude,
          longitude,
          locB.latitude,
          locB.longitude,
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

  /// Check if user can create a new hub (based on ownership, not membership)
  /// Returns true if user has created fewer than 3 hubs
  /// Check if user can create a hub
  /// Returns a result object with status and message
  Future<HubCreationCheckResult> canCreateHub(String userId) async {
    if (!Env.isFirebaseAvailable) {
      return HubCreationCheckResult(
        canCreate: false,
        reason: HubCreationLimitReason.firebaseUnavailable,
        message: 'Firebase לא זמין',
      );
    }

    try {
      const maxHubsAsOwner = 3;

      // Fetch actual hub documents to verify they exist (not just count)
      // This is more expensive but ensures accuracy after deletions
      final querySnapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .where('createdBy', isEqualTo: userId)
          .get();

      final count = querySnapshot.docs.length;

      // Debug logging to help diagnose issues
      if (count >= maxHubsAsOwner) {
        debugPrint('🔴 Hub creation limit reached for user $userId');
        debugPrint('   Found $count hubs (max: $maxHubsAsOwner):');
        for (final doc in querySnapshot.docs) {
          final hubName = doc.data()['name'] ?? 'Unknown';
          debugPrint('   - Hub ${doc.id}: $hubName');
        }
      }

      if (count >= maxHubsAsOwner) {
        return HubCreationCheckResult(
          canCreate: false,
          reason: HubCreationLimitReason.limitReached,
          message: 'הגעת למגבלת יצירת הובים (${maxHubsAsOwner}). '
              'אפשר לעזוב או להעביר בעלות על הוב קיים כדי ליצור חדש.',
          currentCount: count,
          maxCount: maxHubsAsOwner,
        );
      }

      return HubCreationCheckResult(
        canCreate: true,
        reason: null,
        message: null,
        currentCount: count,
        maxCount: maxHubsAsOwner,
      );
    } catch (e) {
      debugPrint('Error checking hub creation limit: $e');
      return HubCreationCheckResult(
        canCreate: false,
        reason: HubCreationLimitReason.transientError,
        message: 'שגיאה זמנית בבדיקת המגבלה. נסה שוב בעוד רגע.',
      );
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
  @Deprecated('Use HubVenuesRepository.setHubPrimaryVenue instead')
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
  @Deprecated('Use HubVenuesRepository.unlinkVenueFromHub instead')
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
  @Deprecated('Use HubContactRepository.streamContactMessages instead')
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
  @Deprecated('Use HubContactRepository.sendContactMessage instead')
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
  @Deprecated('Use HubContactRepository.checkExistingContactMessage instead')
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
  @Deprecated('Use HubContactRepository.updateContactMessageStatus instead')
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

  /// Find hub by invitation code
  ///
  /// Note: Firestore doesn't support queries on nested map fields like settings.invitationCode.
  /// This method queries a limited set of hubs and filters client-side.
  /// For better scalability, consider denormalizing invitationCode to a top-level field.
  ///
  /// [invitationCode] - The invitation code to search for (case-insensitive)
  /// Returns the matching hub or null if not found
  Future<Hub?> getHubByInvitationCode(String invitationCode) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      // Query with reasonable limit (much better than 1000)
      // In the future, consider adding invitationCode as a top-level field for direct querying
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .limit(
              200) // Reasonable limit - most hubs won't have invitation codes
          .get();

      final normalizedCode = invitationCode.toUpperCase().trim();

      // Search in settings.invitationCode
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final settings = data['settings'] as Map<String, dynamic>?;
        if (settings != null) {
          final code = settings['invitationCode'] as String?;
          if (code != null && code.toUpperCase().trim() == normalizedCode) {
            return Hub.fromJson({...data, 'hubId': doc.id});
          }
        }

        // Fallback: check if hubId prefix matches (for backward compatibility)
        if (doc.id.length >= 8 &&
            doc.id.substring(0, 8).toUpperCase() == normalizedCode) {
          return Hub.fromJson({...data, 'hubId': doc.id});
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error in getHubByInvitationCode: $e');
      return null;
    }
  }

  /// Get DocumentReference for a hub (for transactions)
  DocumentReference getHubRef(String hubId) {
    return _firestore.doc(FirestorePaths.hub(hubId));
  }

  /// Get DocumentReference for a hub member (for transactions)
  DocumentReference getHubMemberRef(String hubId, String userId) {
    return _firestore.doc('hubs/$hubId/members/$userId');
  }

  /// Watch pending join requests count for a hub
  ///
  /// Returns a stream of the number of pending join requests.
  /// Used by HubCommandCenter to display notification badge.
  ///
  /// Note: For detailed request data, use watchPendingJoinRequests() instead.
  @Deprecated('Use HubJoinRequestsRepository.watchPendingJoinRequestsCount instead')
  Stream<int> watchPendingJoinRequestsCount(String hubId) {
    if (!Env.isFirebaseAvailable) return Stream.value(0);

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.length)
        .handleError((error) {
      debugPrint('Error watching pending join requests count: $error');
      return 0;
    });
  }

  /// Watch pending join requests for a hub (full data)
  ///
  /// Returns a stream of QuerySnapshot for all pending join requests.
  /// Useful when you need full request documents, not just the count.
  @Deprecated('Use HubJoinRequestsRepository.watchPendingJoinRequests instead')
  Stream<QuerySnapshot> watchPendingJoinRequests(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(
        _EmptyQuerySnapshot() as QuerySnapshot,
      );
    }

    return _firestore
        .collection('hubs')
        .doc(hubId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .handleError((error) {
      debugPrint('Error watching pending join requests: $error');
      return _EmptyQuerySnapshot() as QuerySnapshot;
    });
  }

  /// Approve a join request and add user to hub
  ///
  /// Performs atomic transaction:
  /// 1. Checks hub capacity (max 50 members)
  /// 2. Checks if user is already a member
  /// 3. Adds user to members subcollection
  /// 4. Increments memberCount
  /// 5. Updates user's hubIds array
  /// 6. Updates request status to 'approved'
  ///
  /// Data-access only - no business validation beyond capacity check
  /// Returns the hub name for notification purposes
  @Deprecated('Use HubJoinRequestsRepository.approveJoinRequest instead')
  Future<String> approveJoinRequest({
    required String hubId,
    required String requestId,
    required String userId,
    required String processedBy,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      String hubName = '';

      await _firestore.runTransaction((transaction) async {
        // 1. Get hub document
        final hubRef = _firestore.collection('hubs').doc(hubId);
        final hubDoc = await transaction.get(hubRef);

        if (!hubDoc.exists) {
          throw Exception('Hub לא נמצא');
        }

        final hubData = hubDoc.data()!;
        hubName = hubData['name'] as String? ?? 'האב';
        final memberCount = hubData['memberCount'] as int? ?? 0;

        // Check capacity
        if (memberCount >= 50) {
          throw Exception('ההאב מלא (מקסימום 50 חברים)');
        }

        // Check user
        final userRef = _firestore.collection('users').doc(userId);
        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) throw Exception('משתמש לא נמצא');

        final userData = userDoc.data()!;
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);

        // Check if user is already a member
        if (userHubIds.contains(hubId)) {
          // User already a member, just update request status
          final requestRef = hubRef.collection('requests').doc(requestId);
          transaction.update(requestRef, {
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': processedBy,
          });
          return;
        }

        // 2. Add to members subcollection
        final memberRef = hubRef.collection('members').doc(userId);
        transaction.set(memberRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'player',
        });

        // 3. Increment memberCount
        transaction.update(hubRef, {
          'memberCount': FieldValue.increment(1),
        });

        // 4. Update user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayUnion([hubId]),
        });

        // 5. Update request status
        final requestRef = hubRef.collection('requests').doc(requestId);
        transaction.update(requestRef, {
          'status': 'approved',
          'processedAt': FieldValue.serverTimestamp(),
          'processedBy': processedBy,
        });
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));

      return hubName;
    } catch (e) {
      throw Exception('Failed to approve join request: $e');
    }
  }

  /// Reject a join request
  ///
  /// Updates request status to 'rejected' with timestamp and processor ID
  ///
  /// Data-access only - no business validation
  @Deprecated('Use HubJoinRequestsRepository.rejectJoinRequest instead')
  Future<void> rejectJoinRequest({
    required String hubId,
    required String requestId,
    required String processedBy,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': processedBy,
      });

      // Note: No cache invalidation needed for rejecting requests
    } catch (e) {
      throw Exception('Failed to reject join request: $e');
    }
  }

  /// Create hub with manager member and update user in batch
  ///
  /// Data-access only - no business validation
  /// Use HubCreationService for business logic
  Future<String> createHubWithMemberBatch({
    required Map<String, dynamic> hubData,
    required String hubId,
    required String creatorId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();

      // Create hub document
      final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
      batch.set(hubRef, hubData, SetOptions(merge: false));

      // Add creator as manager member
      final memberRef = hubRef.collection('members').doc(creatorId);
      batch.set(memberRef, {
        'hubId': hubId,
        'userId': creatorId,
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager',
        'status': 'active',
        'veteranSince': null,
        'managerRating': 0.0,
        'lastActiveAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': creatorId,
        'statusReason': null,
      });

      // Update user's hubIds (only if not already present)
      final userRef = _firestore.doc(FirestorePaths.user(creatorId));
      batch.update(userRef, {
        'hubIds': FieldValue.arrayUnion([hubId]),
      });

      await batch.commit();

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));

      return hubId;
    } catch (e) {
      throw Exception('Failed to create hub with member: $e');
    }
  }

  /// Get user data for validation
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final userDoc = await _firestore.doc(FirestorePaths.user(userId)).get();
      return userDoc.data();
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Generate new hub ID
  String generateHubId() {
    return _firestore.collection(FirestorePaths.hubs()).doc().id;
  }

  /// Update hub member field
  ///
  /// Updates a single field for a hub member
  ///
  /// Data-access only - no business validation
  Future<void> updateMemberField({
    required String hubId,
    required String userId,
    required String field,
    required dynamic value,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc('hubs/$hubId/members/$userId').update({
        field: value,
      });
    } catch (e) {
      throw Exception('Failed to update member field: $e');
    }
  }

  /// Update hub member statistics from match result
  ///
  /// Updates goals, assists, MVPs, and games played for players in a match
  ///
  /// Data-access only - batch updates to member subcollection
  Future<void> updateMemberStatsFromMatch({
    required String hubId,
    required List<String> scorerIds,
    required List<String> assistIds,
    required String? mvpId,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final batch = _firestore.batch();

      // Count goals and assists per player
      final Map<String, int> playerGoals = {};
      final Map<String, int> playerAssists = {};

      for (final scorerId in scorerIds) {
        playerGoals[scorerId] = (playerGoals[scorerId] ?? 0) + 1;
      }

      for (final assistId in assistIds) {
        playerAssists[assistId] = (playerAssists[assistId] ?? 0) + 1;
      }

      // Update each player's stats in hub members
      for (final playerId in {
        ...playerGoals.keys,
        ...playerAssists.keys,
        if (mvpId != null) mvpId
      }) {
        final memberRef = _firestore
            .collection('hubs')
            .doc(hubId)
            .collection('members')
            .doc(playerId);

        final memberDoc = await memberRef.get();
        if (!memberDoc.exists) continue;

        final updates = <String, dynamic>{};

        // Update goals
        final goalsCount = playerGoals[playerId] ?? 0;
        if (goalsCount > 0) {
          updates['totalGoals'] = FieldValue.increment(goalsCount);
        }

        // Update assists
        final assistsCount = playerAssists[playerId] ?? 0;
        if (assistsCount > 0) {
          updates['totalAssists'] = FieldValue.increment(assistsCount);
        }

        // Update MVP count
        if (playerId == mvpId) {
          updates['totalMvps'] = FieldValue.increment(1);
        }

        // Update games played
        updates['gamesPlayed'] = FieldValue.increment(1);

        if (updates.isNotEmpty) {
          batch.update(memberRef, updates);
        }
      }

      // Commit batch
      await batch.commit();
    } catch (e) {
      debugPrint('⚠️ Failed to update member stats: $e');
      // Don't throw - stats update failure shouldn't block the match
    }
  }

  /// Get hub members by status
  Future<List<HubMember>> getHubMembersByStatus({
    required String hubId,
    required HubMemberStatus status,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubMembers(hubId))
          .where('status', isEqualTo: status.name)
          .orderBy('updatedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => HubMember.fromJson({...doc.data(), 'userId': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('Error getting members by status: $e');
      return [];
    }
  }

  /// Update member status
  Future<void> updateMemberStatus(
    String hubId,
    String userId,
    HubMemberStatus newStatus, {
    String? reason,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final currentUserId = firebase_auth.FirebaseAuth.instance.currentUser?.uid;

      await _firestore.doc(FirestorePaths.hubMember(hubId, userId)).update({
        'status': newStatus.name,
        'statusReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentUserId ?? 'system',
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to update member status: $e');
    }
  }

  /// Get all memberships for a user (across all hubs)
  Future<List<HubMember>> getUserMemberships(String userId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collectionGroup('members')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs.map((doc) => HubMember.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting user memberships: $e');
      return [];
    }
  }

  /// Transfer membership from one user to another
  Future<void> transferMembership({
    required String fromUserId,
    required String toUserId,
    required String hubId,
    bool preserveRating = true,
  }) async {
    if (!Env.isFirebaseAvailable) return;

    try {
      final batch = _firestore.batch();

      // Get source membership
      final fromMemberRef =
          _firestore.doc(FirestorePaths.hubMember(hubId, fromUserId));
      final fromMemberDoc = await fromMemberRef.get();

      if (!fromMemberDoc.exists) {
        throw Exception('Source membership not found');
      }

      final fromData = fromMemberDoc.data()!;

      // Create new membership for target user
      final toMemberRef =
          _firestore.doc(FirestorePaths.hubMember(hubId, toUserId));

      final newMemberData = {
        'hubId': hubId,
        'userId': toUserId,
        'joinedAt': fromData['joinedAt'],
        'role': fromData['role'] ?? 'member',
        'status': 'active',
        'managerRating':
            preserveRating ? fromData['managerRating'] ?? 0.0 : 0.0,
        'veteranSince': fromData['veteranSince'],
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': 'system:merge',
        'statusReason': 'Merged from fictitious player',
      };

      batch.set(toMemberRef, newMemberData);

      // Delete old membership
      batch.delete(fromMemberRef);

      // Update user's hubIds array
      final toUserRef = _firestore.doc(FirestorePaths.user(toUserId));
      batch.update(toUserRef, {
        'hubIds': FieldValue.arrayUnion([hubId]),
      });

      final fromUserRef = _firestore.doc(FirestorePaths.user(fromUserId));
      batch.update(fromUserRef, {
        'hubIds': FieldValue.arrayRemove([hubId]),
      });

      await batch.commit();

      // Invalidate caches
      CacheService().clear(CacheKeys.hub(hubId));
      CacheService().clear(CacheKeys.user(fromUserId));
      CacheService().clear(CacheKeys.user(toUserId));
    } catch (e) {
      throw Exception('Failed to transfer membership: $e');
    }
  }
}

/// Empty QuerySnapshot for error fallback
class _EmptyQuerySnapshot {
  List<QueryDocumentSnapshot> get docs => [];
  int get size => 0;
}
