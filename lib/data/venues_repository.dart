import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/venue.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/utils/geohash_utils.dart';

/// Repository for Venue operations
class VenuesRepository {
  final FirebaseFirestore _firestore;

  VenuesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get venue by ID
  Future<Venue?> getVenue(String venueId) async {
    if (!Env.isFirebaseAvailable) return null;

    try {
      final doc = await _firestore.doc(FirestorePaths.venue(venueId)).get();
      if (!doc.exists) return null;
      return Venue.fromJson({...doc.data()!, 'venueId': venueId});
    } catch (e) {
      throw Exception('Failed to get venue: $e');
    }
  }

  /// Stream venue by ID
  Stream<Venue?> watchVenue(String venueId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value(null);
    }

    return _firestore
        .doc(FirestorePaths.venue(venueId))
        .snapshots()
        .map((doc) => doc.exists
            ? Venue.fromJson({...doc.data()!, 'venueId': doc.id})
            : null);
  }

  /// Get all venues for a hub
  Future<List<Venue>> getVenuesByHub(String hubId) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.venues())
          .where('hubId', isEqualTo: hubId)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => Venue.fromJson({...doc.data(), 'venueId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream venues for a hub
  Stream<List<Venue>> watchVenuesByHub(String hubId) {
    if (!Env.isFirebaseAvailable) {
      return Stream.value([]);
    }

    return _firestore
        .collection(FirestorePaths.venues())
        .where('hubId', isEqualTo: hubId)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Venue.fromJson({...doc.data(), 'venueId': doc.id}))
            .toList());
  }

  /// Create venue
  Future<String> createVenue(Venue venue) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = venue.toJson();
      data.remove('venueId'); // Remove venueId from data (it's the document ID)
      
      final docRef = venue.venueId.isNotEmpty
          ? _firestore.doc(FirestorePaths.venue(venue.venueId))
          : _firestore.collection(FirestorePaths.venues()).doc();
      
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create venue: $e');
    }
  }

  /// Update venue
  Future<void> updateVenue(String venueId, Map<String, dynamic> data) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.doc(FirestorePaths.venue(venueId)).update(data);
    } catch (e) {
      throw Exception('Failed to update venue: $e');
    }
  }

  /// Delete venue (soft delete by setting isActive to false)
  Future<void> deleteVenue(String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      await _firestore.doc(FirestorePaths.venue(venueId)).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete venue: $e');
    }
  }

  /// Find venues nearby
  Future<List<Venue>> findVenuesNearby({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      // Get geohash for the location
      final centerGeohash = GeohashUtils.encode(latitude, longitude, precision: 7);
      final neighbors = GeohashUtils.neighbors(centerGeohash);

      // Query venues in the geohash area
      final venues = <Venue>[];
      
      for (final geohash in [centerGeohash, ...neighbors]) {
        final snapshot = await _firestore
            .collection(FirestorePaths.venues())
            .where('geohash', isGreaterThanOrEqualTo: geohash)
            .where('geohash', isLessThanOrEqualTo: '${geohash}z')
            .where('isActive', isEqualTo: true)
            .get();

        for (final doc in snapshot.docs) {
          final venue = Venue.fromJson({...doc.data(), 'venueId': doc.id});
          
          // Calculate distance
          final distance = Geolocator.distanceBetween(
            latitude,
            longitude,
            venue.location.latitude,
            venue.location.longitude,
          ) / 1000; // Convert to km

          if (distance <= radiusKm) {
            venues.add(venue);
          }
        }
      }

      // Sort by distance
      venues.sort((a, b) {
        final distA = Geolocator.distanceBetween(
          latitude,
          longitude,
          a.location.latitude,
          a.location.longitude,
        );
        final distB = Geolocator.distanceBetween(
          latitude,
          longitude,
          b.location.latitude,
          b.location.longitude,
        );
        return distA.compareTo(distB);
      });

      return venues;
    } catch (e) {
      return [];
    }
  }
}

