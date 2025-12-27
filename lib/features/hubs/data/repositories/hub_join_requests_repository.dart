import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/shared/infrastructure/cache/cache_service.dart';

/// Repository for managing hub join requests
///
/// Extracted from HubsRepository to follow Single Responsibility Principle.
/// Handles join request approval/rejection workflow.
///
/// ⚠️ CRITICAL: Uses transactions for atomic operations!
class HubJoinRequestsRepository {
  final FirebaseFirestore _firestore;

  HubJoinRequestsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Watch pending join requests count for a hub
  ///
  /// Returns a stream of the number of pending join requests.
  /// Used by HubCommandCenter to display notification badge.
  ///
  /// Extracted from HubsRepository lines 1739-1753
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
  ///
  /// Extracted from HubsRepository lines 1759-1776
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
  /// ⚠️ CRITICAL: Uses transaction for atomic operations!
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
  ///
  /// Extracted from HubsRepository lines 1790-1874
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
  ///
  /// Extracted from HubsRepository lines 1881-1906
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
}

/// Empty QuerySnapshot for error fallback
class _EmptyQuerySnapshot {
  List<QueryDocumentSnapshot> get docs => [];
  int get size => 0;
}
