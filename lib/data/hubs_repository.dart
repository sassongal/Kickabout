import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickabout/config/env.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/firestore_paths.dart';
import 'package:kickabout/utils/geohash_utils.dart';

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
      return Hub.fromJson({...doc.data()!, 'hubId': hubId});
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
        .map((doc) => doc.exists
            ? Hub.fromJson({...doc.data()!, 'hubId': hubId})
            : null);
  }

  /// Create hub
  Future<String> createHub(Hub hub) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = hub.toJson();
      data.remove('hubId'); // Remove hubId from data (it's the document ID)
      
      final docRef = hub.hubId.isNotEmpty
          ? _firestore.doc(FirestorePaths.hub(hub.hubId))
          : _firestore.collection(FirestorePaths.hubs()).doc();
      
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
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

  /// Add member to hub
  Future<void> addMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'memberIds': FieldValue.arrayUnion([uid]),
      });
    } catch (e) {
      throw Exception('Failed to add member: $e');
    }
  }

  /// Remove member from hub
  Future<void> removeMember(String hubId, String uid) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final hub = await getHub(hubId);
      if (hub == null) throw Exception('Hub not found');
      
      // Remove from memberIds
      await _firestore.doc(FirestorePaths.hub(hubId)).update({
        'memberIds': FieldValue.arrayRemove([uid]),
      });
      
      // Remove from roles if exists
      if (hub.roles.containsKey(uid)) {
        final updatedRoles = Map<String, String>.from(hub.roles);
        updatedRoles.remove(uid);
        await _firestore.doc(FirestorePaths.hub(hubId)).update({
          'roles': updatedRoles,
        });
      }
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
          .where('geohash', isLessThan: hash + '~')
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

    return _firestore
        .collection(FirestorePaths.hubs())
        .where('createdBy', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
            .toList());
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
}

