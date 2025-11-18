import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/venue.dart';
import 'package:kickadoor/models/hub.dart';
import 'package:kickadoor/services/firestore_paths.dart';
import 'package:kickadoor/services/google_places_service.dart';
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

  /// Search for football venues using Google Places API
  /// 
  /// This function uses Google Places Text Search API to find football fields
  /// and converts the results to Venue objects.
  /// 
  /// [latitude] - Optional center latitude for location-based search
  /// [longitude] - Optional center longitude for location-based search
  /// [radius] - Search radius in meters (default 50km)
  /// 
  /// Returns a list of Venue objects mapped from Google Places API results.
  Future<List<Venue>> searchFootballVenuesFromGooglePlaces({
    double? latitude,
    double? longitude,
    int radius = 50000,
  }) async {
    try {
      // Initialize Google Places Service (uses API key from Env.googleMapsApiKey)
      final placesService = GooglePlacesService();
      
      // Call the search function
      final placeResults = await placesService.searchForFootballVenues(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );

      // Convert PlaceResult objects to Venue objects
      final venues = <Venue>[];
      for (final placeResult in placeResults) {
        try {
          // Create Venue object from PlaceResult
          final venue = Venue(
            venueId: '', // Will be generated when saved to Firestore
            hubId: '', // Not assigned to a hub yet - can be set later
            name: placeResult.name,
            description: placeResult.address,
            location: GeoPoint(placeResult.latitude, placeResult.longitude),
            address: placeResult.address,
            googlePlaceId: placeResult.placeId,
            amenities: placeResult.isSportsVenue ? ['outdoor'] : [],
            surfaceType: 'grass', // Default, can be updated later
            maxPlayers: 11, // Default 11v11
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: null, // Not created by a user, from Google Places
            isActive: true,
            isMain: false,
            hubCount: 0, // New venue, no hubs using it yet
            isPublic: true, // Default to public venue
          );

          venues.add(venue);
        } catch (e) {
          // Skip this venue if conversion fails
          continue;
        }
      }

      return venues;
    } catch (e) {
      throw Exception('Failed to search football venues from Google Places: $e');
    }
  }

  /// Get or create venue from Google Place
  /// 
  /// This function implements a "get or create" pattern:
  /// - If a venue with the same googlePlaceId exists, return it
  /// - Otherwise, create a new venue in Firestore and return it
  /// 
  /// [venueFromGoogle] - Venue object created from Google Places API result
  /// 
  /// Returns the existing or newly created Venue with its Firestore ID
  Future<Venue> getOrCreateVenueFromGooglePlace(Venue venueFromGoogle) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    // Validate that googlePlaceId exists
    if (venueFromGoogle.googlePlaceId == null || venueFromGoogle.googlePlaceId!.isEmpty) {
      throw Exception('Venue must have a googlePlaceId');
    }

    try {
      // Search for existing venue with the same googlePlaceId
      final snapshot = await _firestore
          .collection(FirestorePaths.venues())
          .where('googlePlaceId', isEqualTo: venueFromGoogle.googlePlaceId)
          .limit(1)
          .get();

      // If venue exists, return it
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return Venue.fromJson({...doc.data(), 'venueId': doc.id});
      }

      // If venue doesn't exist, create it
      final data = venueFromGoogle.toJson();
      data.remove('venueId'); // Remove venueId from data (it's the document ID)
      
      // Ensure required fields are set
      data['hubCount'] = venueFromGoogle.hubCount;
      data['isPublic'] = venueFromGoogle.isPublic;
      data['isActive'] = venueFromGoogle.isActive;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Add to Firestore collection
      final docRef = await _firestore.collection(FirestorePaths.venues()).add(data);
      
      // Return the newly created venue with its Firestore ID
      final createdData = await docRef.get();
      return Venue.fromJson({...createdData.data()!, 'venueId': docRef.id});
    } catch (e) {
      throw Exception('Failed to get or create venue from Google Place: $e');
    }
  }

  /// Link secondary venue to hub (not primary venue)
  /// 
  /// This function:
  /// - Adds the venueId to the hub's venueIds array
  /// - Increments the venue's hubCount by 1
  /// 
  /// Note: This function does NOT set the venue as primary.
  /// Use setHubPrimaryVenue in HubsRepository for primary venue.
  /// 
  /// [hubId] - ID of the hub to link the venue to
  /// [venueId] - ID of the venue to link
  Future<void> linkSecondaryVenueToHub(String hubId, String venueId) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Use transaction to ensure atomicity
      await _firestore.runTransaction((transaction) async {
        final hubRef = _firestore.doc(FirestorePaths.hub(hubId));
        final venueRef = _firestore.doc(FirestorePaths.venue(venueId));

        // Read both documents
        final hubDoc = await transaction.get(hubRef);
        final venueDoc = await transaction.get(venueRef);

        if (!hubDoc.exists) {
          throw Exception('Hub not found');
        }
        if (!venueDoc.exists) {
          throw Exception('Venue not found');
        }

        final hubData = hubDoc.data()!;

        // Check if venue is already linked to this hub
        final venueIds = List<String>.from(hubData['venueIds'] ?? []);
        if (venueIds.contains(venueId)) {
          return; // Already linked, no need to update
        }

        // Update hub - add venueId to venueIds array
        transaction.update(hubRef, {
          'venueIds': FieldValue.arrayUnion([venueId]),
        });

        // Update venue - increment hubCount
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to link secondary venue to hub: $e');
    }
  }

  /// Get all venues for map display
  /// 
  /// Returns a list of all active venues in the system.
  Future<List<Venue>> getVenuesForMap() async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.venues())
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => Venue.fromJson({...doc.data(), 'venueId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get all hubs with primary venue location for map display
  /// 
  /// Returns a list of all hubs that have a primaryVenueLocation set.
  Future<List<Hub>> getHubsForMap() async {
    if (!Env.isFirebaseAvailable) return [];

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.hubs())
          .where('primaryVenueLocation', isNotEqualTo: null)
          .get();

      return snapshot.docs
          .map((doc) => Hub.fromJson({...doc.data(), 'hubId': doc.id}))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Create manual venue (not from Google Places)
  /// 
  /// This function creates a new venue in Firestore with the provided data.
  /// The venue will NOT have a googlePlaceId (it's null).
  /// 
  /// [name] - Name of the venue (required)
  /// [address] - Human-readable address (optional)
  /// [location] - GeoPoint location (required)
  /// [isPublic] - Whether this is a public venue (default: true)
  /// 
  /// Returns the created Venue with its Firestore ID
  Future<Venue> createManualVenue({
    required String name,
    String? address,
    required GeoPoint location,
    bool isPublic = true,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Get current user ID (if available)
      String? createdBy;
      try {
        // Try to get current user from auth (if available in context)
        // Note: In a real implementation, you might want to pass userId as parameter
        // For now, we'll leave it null for manual venues
        createdBy = null;
      } catch (e) {
        // Ignore - createdBy can be null
      }

      // Create Venue object
      final venue = Venue(
        venueId: '', // Will be generated by Firestore
        hubId: '', // Not assigned to a hub yet - can be set later
        name: name,
        description: address,
        location: location,
        address: address,
        googlePlaceId: null, // Manual venue - no Google Place ID
        amenities: [],
        surfaceType: 'grass', // Default
        maxPlayers: 11, // Default 11v11
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: createdBy,
        isActive: true,
        isMain: false,
        hubCount: 0, // New venue, no hubs using it yet
        isPublic: isPublic,
      );

      // Convert to JSON and remove venueId (it's the document ID)
      final data = venue.toJson();
      data.remove('venueId');

      // Add to Firestore
      final docRef = await _firestore.collection(FirestorePaths.venues()).add(data);

      // Read the created document to get the full Venue with ID
      final createdDoc = await docRef.get();
      return Venue.fromJson({...createdDoc.data()!, 'venueId': docRef.id});
    } catch (e) {
      throw Exception('Failed to create manual venue: $e');
    }
  }
}

