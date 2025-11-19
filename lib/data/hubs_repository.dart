import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/services/error_handler_service.dart';
import 'package:kickadoor/utils/geohash_utils.dart';

/// Repository for Hub operations
class HubsRepository {
  final FirebaseFirestore _firestore;

  HubsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get hub by ID
  Future<Hub?> getHub(String hubId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.doc(FirestorePaths.hub(hubId)).get();
      if (!doc.exists) return null;
      final data = doc.data();
      if (data == null) return null;
      return Hub.fromJson({...data, 'hubId': hubId});
    } catch (e) {
      throw Exception('Failed to get hub: $e');
    }
  }

  /// Stream hub by ID
  Stream<Hub?> watchHub(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.hub(hubId))
        .snapshots()
        .map((doc) {
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
      final docRef = hub.hubId.isNotEmpty
          ? _firestore.doc(FirestorePaths.hub(hub.hubId))
          : _firestore.collection(FirestorePaths.hubs()).doc();
      
      final data = hub.toJson();
      // Keep hubId in data for Firestore rules validation (it's also the document ID)
      data['hubId'] = docRef.id;
      
      // Ensure creator is in memberIds (required by Firestore rules)
      if (!hub.memberIds.contains(hub.createdBy)) {
        data['memberIds'] = [...hub.memberIds, hub.createdBy];
      }
      
      // Initialize memberJoinDates with creator's join date (always set for creator)
        final memberJoinDates = Map<String, dynamic>.from(data['memberJoinDates'] ?? {});
        memberJoinDates[hub.createdBy] = FieldValue.serverTimestamp();
        data['memberJoinDates'] = memberJoinDates;
      
      // CRITICAL: Ensure creator is ALWAYS set as manager in roles (required for permissions)
      // This guarantees the creator can perform all manager actions (create events, manage members, etc.)
      final roles = Map<String, String>.from(data['roles'] ?? {});
      roles[hub.createdBy] = 'manager';
      data['roles'] = roles;
      
      await docRef.set(data, SetOptions(merge: false));
      
      // Update user's hubIds (denormalized) - use transaction for atomicity
      try {
        await _firestore.runTransaction((transaction) async {
          final userRef = _firestore.doc(FirestorePaths.user(hub.createdBy));
          final userDoc = await transaction.get(userRef);
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              final userHubIds = List<String>.from(userData['hubIds'] ?? []);
              if (!userHubIds.contains(docRef.id)) {
                transaction.update(userRef, {
                  'hubIds': FieldValue.arrayUnion([docRef.id]),
                });
              }
            }
          }
        });
      } catch (e) {
        // Log but don't fail hub creation if user update fails
        // Error is logged silently - hub creation succeeds even if user update fails
        // This prevents cascading failures
      }
      
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
  Stream<List<Hub>> watchHubsByMember(String uid) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.hubs())
        .where('memberIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
            .toList());
  }

  /// Get hubs by member (non-streaming)
  Future<List<Hub>> getHubsByMember(String uid) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .where('memberIds', arrayContains: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Add member to hub (atomic operation)
  /// Updates both hub.memberIds and user.hubIds atomically
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
        
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final hubData = hubDoc.data();
        final userData = userDoc.data();
        if (hubData == null) throw Exception('Hub data is null');
        if (userData == null) throw Exception('User data is null');
        
        // Check if already a member
        final memberIds = List<String>.from(hubData['memberIds'] ?? []);
        if (memberIds.contains(uid)) {
          return; // Already a member
        }
        
        // Update hub - add member and record join date
        final now = FieldValue.serverTimestamp();
        final updates = <String, dynamic>{
          'memberIds': FieldValue.arrayUnion([uid]),
        };
        
        // Record join date
        final memberJoinDates = Map<String, dynamic>.from(hubData['memberJoinDates'] ?? {});
        memberJoinDates[uid] = now;
        updates['memberJoinDates'] = memberJoinDates;
        
        transaction.update(hubRef, updates);
        
        // Update user (denormalized)
        final userHubIds = List<String>.from(userData['hubIds'] ?? []);
        if (!userHubIds.contains(hubId)) {
          transaction.update(userRef, {
            'hubIds': FieldValue.arrayUnion([hubId]),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from hub (atomic operation)
  /// Updates both hub.memberIds, hub.roles, and user.hubIds atomically
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
        
        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!userDoc.exists) {
          throw Exception('User not found');
        }
        
        final hubData = hubDoc.data();
        final userData = userDoc.data();
        if (hubData == null) throw Exception('Hub data is null');
        if (userData == null) throw Exception('User data is null');
        
        // Remove from hub.memberIds
        final updates = <String, dynamic>{
          'memberIds': FieldValue.arrayRemove([uid]),
        };
        
        // Remove from hub.roles if exists
        final roles = Map<String, String>.from(hubData['roles'] ?? {});
        if (roles.containsKey(uid)) {
          final updatedRoles = Map<String, String>.from(roles);
          updatedRoles.remove(uid);
          updates['roles'] = updatedRoles;
        }
        
        // Remove join date
        final memberJoinDates = Map<String, dynamic>.from(hubData['memberJoinDates'] ?? {});
        if (memberJoinDates.containsKey(uid)) {
          final updatedJoinDates = Map<String, dynamic>.from(memberJoinDates);
          updatedJoinDates.remove(uid);
          updates['memberJoinDates'] = updatedJoinDates;
        }
        
        transaction.update(hubRef, updates);
        
        // Remove from user.hubIds (denormalized)
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
  Future<bool> isMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) return false;

    try {
      final hub = await getHub(hubId);
      return hub?.memberIds.contains(uid) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Find hubs within radius (km) using geohash
  /// This is an approximate search - results are filtered by actual distance
  /// Get all hubs (with limit for pagination)
  Future<List<Hub>> getAllHubs({int limit = 100}) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .limit(limit)
          .get();

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
            ) / 1000; // Convert to km
            return distance <= radiusKm;
          })
          .toList();

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
  /// Note: This creates a stream that queries periodically - not real-time
  Stream<List<Hub>> watchHubsNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    // For now, return a stream that queries every 30 seconds
    // In production, you might want to use a more efficient approach
    return Stream.periodic(const Duration(seconds: 30), (_) => null)
        .asyncMap((_) => findHubsNearby(
              latitude: latitude,
              longitude: longitude,
              radiusKm: radiusKm,
            ))
        .distinct();
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
            debugPrint('watchHubsByCreator: Found ${snapshot.docs.length} hubs for user $uid');
            return snapshot.docs
                .map((doc) {
                  try {
                    return Hub.fromJson({...doc.data(), 'hubId': doc.id});
                  } catch (e) {
                    debugPrint('Error parsing hub ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<Hub>()
                .toList();
          })
          .handleError((error) {
            debugPrint('Error in watchHubsByCreator: $error');
            // Return empty list on error instead of crashing
            return <Hub>[];
          });
    } catch (e) {
      debugPrint('Exception in watchHubsByCreator: $e');
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
          final oldVenueRef = _firestore.doc(FirestorePaths.venue(oldPrimaryVenueId));
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
}

