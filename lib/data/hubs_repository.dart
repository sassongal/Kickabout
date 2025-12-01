import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';
import 'package:kattrick/services/cache_service.dart';
import 'package:kattrick/services/retry_service.dart';
import 'package:kattrick/services/monitoring_service.dart';

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

      // Ensure creator is ALWAYS set as manager in roles
      final roles = Map<String, String>.from(data['roles'] ?? {});
      roles[hub.createdBy] = 'manager';
      data['roles'] = roles;

      // Use batch to write hub and add creator to members subcollection
      final batch = _firestore.batch();

      batch.set(docRef, data, SetOptions(merge: false));

      // Add creator to members subcollection
      final memberRef = docRef.collection('members').doc(hub.createdBy);
      batch.set(memberRef, {
        'joinedAt': FieldValue.serverTimestamp(),
        'role': 'manager', // Creator is manager
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
    } catch (e) {
      throw Exception('Failed to update hub: $e');
    }
  }

  /// Delete hub
  Future<void> deleteHub(String hubId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.hub(hubId)).delete();
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

  /// Add member to hub (atomic operation)
  /// Updates both hub.memberIds and user.hubIds atomically
  /// Add member to hub (atomic operation)
  /// Updates hub.memberCount, adds to members subcollection, and updates user.hubIds
  Future<void> addMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final userRef = _firestore.doc(FirestorePaths.user(uid));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final userDoc = await transaction.get(userRef);

        if (!hubDoc.exists) throw Exception('Hub not found');
        if (!userDoc.exists) throw Exception('User not found');

        final hubData = hubDoc.data();
        final userData = userDoc.data();
        if (hubData == null || userData == null)
          throw Exception('Data is null');

        // Check Hub Capacity (Max 50)
        final memberCount = hubData['memberCount'] as int? ?? 0;
        if (memberCount >= 50) {
          throw Exception('Hub is full (max 50 members)');
        }

        // Check User Hub Limit (Max 10)
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);
        if (userHubIds.length >= 10) {
          throw Exception('User has joined max hubs (10)');
        }

        // Check if already a member (check subcollection existence would be extra read,
        // but checking user.hubIds is free since we read user)
        if (userHubIds.contains(hubId)) {
          return; // Already a member
        }

        // Add to members subcollection
        final memberRef = hubRef.collection('members').doc(uid);
        transaction.set(memberRef, {
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member',
        });

        // Increment memberCount
        transaction.update(hubRef, {
          'memberCount': FieldValue.increment(1),
        });

        // Update user.hubIds
        transaction.update(userRef, {
          'hubIds': FieldValue.arrayUnion([hubId]),
        });
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from hub (atomic operation)
  /// Updates both hub.memberIds, hub.roles, and user.hubIds atomically
  /// Remove member from hub (atomic operation)
  /// Updates hub.memberCount, removes from members subcollection, and updates user.hubIds
  Future<void> removeMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final userRef = _firestore.doc(FirestorePaths.user(uid));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final userDoc = await transaction.get(userRef);

        if (!hubDoc.exists) throw Exception('Hub not found');
        if (!userDoc.exists) throw Exception('User not found');

        final hubData = hubDoc.data();
        final userData = userDoc.data();
        if (hubData == null || userData == null)
          throw Exception('Data is null');

        // Remove from members subcollection
        final memberRef = hubRef.collection('members').doc(uid);
        transaction.delete(memberRef);

        // Decrement memberCount (prevent negative)
        final memberCount = hubData['memberCount'] as int? ?? 0;
        if (memberCount > 0) {
          transaction.update(hubRef, {
            'memberCount': FieldValue.increment(-1),
          });
        }

        // Remove from roles if exists
        final roles = Map<String, String>.from(hubData['roles'] ?? {});
        if (roles.containsKey(uid)) {
          final updatedRoles = Map<String, String>.from(roles);
          updatedRoles.remove(uid);
          transaction.update(hubRef, {'roles': updatedRoles});
        }

        // Remove from user.hubIds
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);
        if (userHubIds.contains(hubId)) {
          transaction.update(userRef, {
            'hubIds': FieldValue.arrayRemove([hubId]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  /// Update member role
  Future<void> updateMemberRole(String hubId, String uid, String role) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final hub = await getHub(hubId);
      if (hub == null) throw Exception('Hub not found');

      // Creator cannot change role
      if (uid == hub.createdBy) {
        throw Exception('Cannot change creator role');
      }

      // Update roles
      final updatedRoles = Map<String, String>.from(hub.roles);
      updatedRoles[uid] = role;

      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'roles': updatedRoles,
      });
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  /// Set player rating for hub-specific team balancing
  /// This rating is used by the team generation algorithm
  /// Set player rating for hub-specific team balancing
  /// This rating is used by the team generation algorithm
  Future<void> setPlayerRating(
      String hubId, String playerId, double rating) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validate rating (1.0 to 10.0)
    if (rating < 1.0 || rating > 10.0) {
      throw Exception('Rating must be between 1.0 and 10.0');
    }

    try {
      final hub = await getHub(hubId);
      if (hub == null) throw Exception('Hub not found');

      // Check hub membership via subcollection
      final memberDoc = await _firestore
          .collection('hubs')
          .doc(hubId)
          .collection('members')
          .doc(playerId)
          .get();

      if (!memberDoc.exists) {
        throw Exception('Player is not a member of this hub');
      }

      // Update managerRatings map
      final updatedRatings = Map<String, double>.from(hub.managerRatings);
      updatedRatings[playerId] = rating;

      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'managerRatings': updatedRatings,
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to set player rating: $e');
    }
  }

  /// Get user role in hub
  Future<String?> getUserRole(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final hub = await getHub(hubId);
      if (hub == null) return null;

      // Creator is always manager
      if (uid == hub.createdBy) return 'manager';

      // Check roles map
      return hub.roles[uid] ?? 'member';
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

  /// Get all member IDs for a hub
  Future<List<String>> getHubMemberIds(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];
    try {
      final snapshot = await _firestore
          .doc(FirestorePaths.hub(hubId))
          .collection('members')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      return [];
    }
  }

  /// Find hubs within radius (km) using geohash
  /// This is an approximate search - results are filtered by actual distance
  /// Get all hubs (with limit for pagination)
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

  Future<List<Hub>> findHubsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Generate geohash (precision 7 = ~150m)
      final centerHash = GeohashUtils.encode(latitude, longitude, precision: 7);
      final neighbors = GeohashUtils.neighbors(centerHash);

      // Query Firestore with geohash prefixes
      final allHashes = [centerHash, ...neighbors];
      final queries = allHashes.map((hash) => _firestore
          .collection(FirestorePaths.hubs())
          .where('geohash', isGreaterThanOrEqualTo: hash)
          .where('geohash', isLessThan: '$hash~')
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
        if (kDebugMode && snapshot.docs.length > 0) {
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
        final hubUpdates = <String, dynamic>{
          'primaryVenueId': venueId,
          'primaryVenueLocation': venueLocation,
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
            // Decrement hubCount on old primary venue
            transaction.update(oldVenueRef, {
              'hubCount': FieldValue.increment(-1),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        // Update new primary venue - increment hubCount
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
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
  /// Removes user ID from hub's bannedUserIds array
  Future<void> unbanUserFromHub(String hubId, String userId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'bannedUserIds': FieldValue.arrayRemove([userId]),
      });

      // Invalidate cache
      CacheService().clear(CacheKeys.hub(hubId));
    } catch (e) {
      throw Exception('Failed to unban user: $e');
    }
  }

  /// Get list of banned users for a hub
  /// Returns list of User objects for users in hub's bannedUserIds
  Future<List<User>> getBannedUsers(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final hub = await getHub(hubId);
      if (hub == null || hub.bannedUserIds.isEmpty) return [];

      // Fetch user documents for all banned user IDs
      // Firestore 'in' query is limited to 10 items, but banned users should be rare
      final bannedUserIds = hub.bannedUserIds;
      if (bannedUserIds.isEmpty) return [];

      // Split into chunks of 10 to handle Firestore limit
      final List<User> bannedUsers = [];
      for (var i = 0; i < bannedUserIds.length; i += 10) {
        final chunk = bannedUserIds.skip(i).take(10).toList();
        final snapshot = await _firestore
            .collection(FirestorePaths.users())
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        final users = snapshot.docs
            .map((doc) => User.fromJson({...doc.data(), 'uid': doc.id}))
            .toList();
        bannedUsers.addAll(users);
      }

      return bannedUsers;
    } catch (e) {
      debugPrint('Error getting banned users: $e');
      return [];
    }
  }
}
