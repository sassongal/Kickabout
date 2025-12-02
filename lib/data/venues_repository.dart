import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/models/venue.dart';
import 'package:kattrick/models/hub.dart';
import 'package:kattrick/services/firestore_paths.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/utils/geohash_utils.dart';

import 'package:kattrick/models/venue_edit_request.dart';

/// Repository for Venue operations
class VenuesRepository {
  final FirebaseFirestore _firestore;

  VenuesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Submit a venue edit request for moderation
  Future<void> submitEditRequest(VenueEditRequest request) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      final data = request.toJson();
      // Use requestId as document ID
      await _firestore
          .collection('venue_edit_requests')
          .doc(request.requestId)
          .set(data);
    } catch (e) {
      throw Exception('Failed to submit edit request: $e');
    }
  }

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

    return _firestore.doc(FirestorePaths.venue(venueId)).snapshots().map(
        (doc) => doc.exists
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
      final centerGeohash =
          GeohashUtils.encode(latitude, longitude, precision: 7);
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
              ) /
              1000; // Convert to km

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
      throw Exception(
          'Failed to search football venues from Google Places: $e');
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
    if (venueFromGoogle.googlePlaceId == null ||
        venueFromGoogle.googlePlaceId!.isEmpty) {
      throw Exception('Venue must have a googlePlaceId');
    }

    try {
      // Search for existing venue with the same googlePlaceId
      final snapshot = await _firestore
          .collection(FirestorePaths.venues())
          .where('googlePlaceId', isEqualTo: venueFromGoogle.googlePlaceId)
          .limit(1)
          .get();

      // If venue exists, return it (but update hubId if it's empty and new venue has hubId)
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final existingData = doc.data();
        final existingHubId = existingData['hubId'] as String? ?? '';
        final newHubId = venueFromGoogle.hubId;

        // If existing venue has empty hubId and new venue has hubId, update it
        if ((existingHubId.isEmpty || existingHubId == '') &&
            newHubId.isNotEmpty) {
          debugPrint(
              '📝 Updating existing venue ${doc.id} with hubId: $newHubId');
          await doc.reference.update({
            'hubId': newHubId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          existingData['hubId'] = newHubId;
        }

        return Venue.fromJson({...existingData, 'venueId': doc.id});
      }

      // If venue doesn't exist, create it
      final data = venueFromGoogle.toJson();
      data.remove('venueId'); // Remove venueId from data (it's the document ID)

      data['geohash'] = GeohashUtils.encode(
        venueFromGoogle.location.latitude,
        venueFromGoogle.location.longitude,
      );
      // Ensure required fields are set
      data['hubCount'] = venueFromGoogle.hubCount;
      data['isPublic'] = venueFromGoogle.isPublic;
      data['isActive'] = venueFromGoogle.isActive;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Add to Firestore collection
      final docRef =
          await _firestore.collection(FirestorePaths.venues()).add(data);

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

        // Update venue - increment hubCount and set hubId
        // Note: If venue is already linked to another hub, this will overwrite hubId
        // This is intentional - venue.hubId represents the "primary" hub it belongs to
        transaction.update(venueRef, {
          'hubCount': FieldValue.increment(1),
          'hubId':
              hubId, // Set hubId so venue appears in getVenuesByHub queries
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

      debugPrint(
          '📊 Loading venues for map: ${snapshot.docs.length} documents found');

      final venues = <Venue>[];
      int skipped = 0;

      for (final doc in snapshot.docs) {
        try {
          final normalized = _normalizeVenueData(doc.data(), doc.id);
          final venue = Venue.fromJson(normalized);
          venues.add(venue);
        } catch (e, stackTrace) {
          skipped++;
          debugPrint('⚠️ Skipping venue ${doc.id}: $e');
          debugPrint('   Stack trace: $stackTrace');
          // Try to get more details about the error
          try {
            final data = doc.data();
            debugPrint('   Venue data keys: ${data.keys.toList()}');
            debugPrint('   createdAt type: ${data['createdAt']?.runtimeType}');
            debugPrint('   updatedAt type: ${data['updatedAt']?.runtimeType}');
            if (data['createdAt'] is String) {
              debugPrint('   createdAt value: ${data['createdAt']}');
            }
            if (data['updatedAt'] is String) {
              debugPrint('   updatedAt value: ${data['updatedAt']}');
            }
          } catch (debugError) {
            debugPrint('   Could not debug venue data: $debugError');
          }
        }
      }

      debugPrint(
          '✅ Successfully loaded ${venues.length} venues (skipped $skipped)');
      return venues;
    } catch (e) {
      debugPrint('❌ Error loading venues for map: $e');
      return [];
    }
  }

  /// Normalize and clean venue data from Firestore
  /// Ensures all fields have correct types and default values
  Map<String, dynamic> _normalizeVenueData(
      Map<String, dynamic> data, String venueId) {
    final normalized = <String, dynamic>{...data, 'venueId': venueId};

    // Required String fields
    normalized['hubId'] = _normalizeStringField(data, 'hubId', '');
    normalized['name'] = _normalizeStringField(data, 'name', 'מגרש ללא שם');

    // Optional String fields
    normalized['description'] = _normalizeOptionalString(data, 'description');
    normalized['address'] = _normalizeOptionalString(data, 'address');
    normalized['googlePlaceId'] =
        _normalizeOptionalString(data, 'googlePlaceId');
    normalized['externalId'] = _normalizeOptionalString(data, 'externalId');
    normalized['createdBy'] = _normalizeOptionalString(data, 'createdBy');

    // List fields
    normalized['amenities'] =
        _normalizeListField(data, 'amenities', <String>[]);

    // String with defaults
    normalized['surfaceType'] = _normalizeStringField(
      data,
      'surfaceType',
      'grass',
      allowedValues: ['grass', 'artificial', 'concrete', 'unknown'],
    );
    normalized['source'] = _normalizeStringField(
      data,
      'source',
      'manual',
      allowedValues: ['manual', 'osm', 'google'],
    );

    // Int fields with defaults
    normalized['maxPlayers'] =
        _normalizeIntField(data, 'maxPlayers', 11, min: 5, max: 22);
    normalized['hubCount'] = _normalizeIntField(data, 'hubCount', 0, min: 0);
    normalized['venueNumber'] =
        _normalizeIntField(data, 'venueNumber', 0, min: 0);

    // Bool fields with defaults
    normalized['isActive'] = _normalizeBoolField(data, 'isActive', true);
    normalized['isMain'] = _normalizeBoolField(data, 'isMain', false);
    normalized['isPublic'] = _normalizeBoolField(data, 'isPublic', true);

    // DateTime fields - keep as Timestamp for Venue.fromJson (which uses @TimestampConverter)
    // The converter will handle the conversion from Timestamp to DateTime
    try {
      final createdAtValue = data['createdAt'];
      if (createdAtValue == null) {
        normalized['createdAt'] = Timestamp.now();
      } else if (createdAtValue is Timestamp) {
        normalized['createdAt'] = createdAtValue;
      } else if (createdAtValue is String) {
        // Parse string and convert to Timestamp
        final dateTime = _normalizeDateTimeField(data, 'createdAt');
        normalized['createdAt'] = Timestamp.fromDate(dateTime);
      } else if (createdAtValue is DateTime) {
        normalized['createdAt'] = Timestamp.fromDate(createdAtValue);
      } else {
        normalized['createdAt'] = Timestamp.now();
      }
    } catch (e) {
      debugPrint(
          '⚠️ Could not parse createdAt for venue $venueId: $e, using now()');
      normalized['createdAt'] = Timestamp.now();
    }

    try {
      final updatedAtValue = data['updatedAt'];
      if (updatedAtValue == null) {
        normalized['updatedAt'] = Timestamp.now();
      } else if (updatedAtValue is Timestamp) {
        normalized['updatedAt'] = updatedAtValue;
      } else if (updatedAtValue is String) {
        // Parse string and convert to Timestamp
        final dateTime =
            _normalizeDateTimeField(data, 'updatedAt', fallbackToNow: true);
        normalized['updatedAt'] = Timestamp.fromDate(dateTime);
      } else if (updatedAtValue is DateTime) {
        normalized['updatedAt'] = Timestamp.fromDate(updatedAtValue);
      } else {
        normalized['updatedAt'] = Timestamp.now();
      }
    } catch (e) {
      debugPrint(
          '⚠️ Could not parse updatedAt for venue $venueId: $e, using now()');
      normalized['updatedAt'] = Timestamp.now();
    }

    // Required GeoPoint
    if (!normalized.containsKey('location') || normalized['location'] == null) {
      throw Exception('Venue $venueId is missing required location field');
    }

    // Ensure geohash exists for location-based queries
    if (!normalized.containsKey('geohash') || normalized['geohash'] == null) {
      try {
        final location = normalized['location'] as GeoPoint;
        normalized['geohash'] = GeohashUtils.encode(
          location.latitude,
          location.longitude,
        );
      } catch (e) {
        debugPrint('⚠️ Could not generate geohash for venue $venueId: $e');
      }
    }

    return normalized;
  }

  String _normalizeStringField(
    Map<String, dynamic> data,
    String key,
    String defaultValue, {
    List<String>? allowedValues,
  }) {
    if (!data.containsKey(key) || data[key] == null) {
      return defaultValue;
    }
    final value = data[key];
    if (value is! String) {
      return defaultValue;
    }
    if (value.isEmpty) {
      return defaultValue;
    }
    if (allowedValues != null && !allowedValues.contains(value)) {
      debugPrint(
          '⚠️ Invalid value for $key: $value, using default: $defaultValue');
      return defaultValue;
    }
    return value;
  }

  String? _normalizeOptionalString(Map<String, dynamic> data, String key) {
    if (!data.containsKey(key) || data[key] == null) {
      return null;
    }
    final value = data[key];
    if (value is! String) {
      return null;
    }
    return value.isEmpty ? null : value;
  }

  List<T> _normalizeListField<T>(
      Map<String, dynamic> data, String key, List<T> defaultValue) {
    if (!data.containsKey(key) || data[key] == null) {
      return defaultValue;
    }
    final value = data[key];
    if (value is! List) {
      return defaultValue;
    }
    try {
      return List<T>.from(value);
    } catch (e) {
      debugPrint('⚠️ Could not convert $key to List<$T>: $e');
      return defaultValue;
    }
  }

  int _normalizeIntField(
    Map<String, dynamic> data,
    String key,
    int defaultValue, {
    int? min,
    int? max,
  }) {
    if (!data.containsKey(key) || data[key] == null) {
      return defaultValue;
    }
    final value = data[key];
    if (value is! int) {
      // Try to convert from double
      if (value is double) {
        return value.round();
      }
      return defaultValue;
    }
    if (min != null && value < min) {
      return min;
    }
    if (max != null && value > max) {
      return max;
    }
    return value;
  }

  bool _normalizeBoolField(
      Map<String, dynamic> data, String key, bool defaultValue) {
    if (!data.containsKey(key) || data[key] == null) {
      return defaultValue;
    }
    final value = data[key];
    if (value is! bool) {
      return defaultValue;
    }
    return value;
  }

  DateTime _normalizeDateTimeField(
    Map<String, dynamic> data,
    String key, {
    bool fallbackToNow = false,
  }) {
    if (!data.containsKey(key) || data[key] == null) {
      return fallbackToNow
          ? DateTime.now()
          : throw Exception('Missing required field: $key');
    }
    final value = data[key];

    // Handle DateTime object
    if (value is DateTime) {
      return value;
    }

    // Handle Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // Handle string format: "2025-11-29 02:57:49.459" or ISO format
    if (value is String) {
      try {
        // Try ISO format first (e.g., "2025-11-29T02:57:49.459Z")
        if (value.contains('T') || value.contains('Z')) {
          // If contains T but not Z or timezone offset, try adding Z
          if (value.contains('T') &&
              !value.contains('Z') &&
              !value.contains('+')) {
            // Check if there's a timezone offset after T (look for pattern like -HH:MM or +HH:MM)
            final tIndex = value.indexOf('T');
            final afterT = value.substring(tIndex + 1);
            // Check if there's a timezone offset pattern (starts with + or - followed by digits)
            final hasTimezoneOffset =
                RegExp(r'[+-]\d{2}:?\d{2}').hasMatch(afterT);
            if (!hasTimezoneOffset) {
              return DateTime.parse('${value}Z');
            }
          }
          return DateTime.parse(value);
        }
        // Try format: "2025-11-29 02:57:49.459"
        if (value.contains(' ')) {
          // Replace space with T and add Z for UTC timezone
          final isoString = value.replaceFirst(' ', 'T');
          // Handle milliseconds - ensure proper format
          if (isoString.contains('.')) {
            // Format: "2025-11-29T02:57:49.459" -> "2025-11-29T02:57:49.459Z"
            return DateTime.parse('${isoString}Z');
          } else {
            // Format: "2025-11-29T02:57:49" -> "2025-11-29T02:57:49Z"
            return DateTime.parse('${isoString}Z');
          }
        }
        // Try simple date format
        try {
          return DateTime.parse(value);
        } catch (e) {
          // If simple parse fails, try adding Z for UTC
          if (!value.contains('Z') &&
              !value.contains('+') &&
              !value.contains('-', 10)) {
            return DateTime.parse('${value}Z');
          }
          rethrow;
        }
      } catch (e) {
        debugPrint(
            '⚠️ Could not parse DateTime string "$value" for field $key: $e');
        if (fallbackToNow) {
          return DateTime.now();
        }
        throw Exception(
            'Invalid DateTime string format for field: $key (value: $value)');
      }
    }

    // Handle int/double as milliseconds since epoch
    if (value is int || value is double) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } catch (e) {
        debugPrint(
            '⚠️ Could not parse DateTime from milliseconds $value for field $key: $e');
        if (fallbackToNow) {
          return DateTime.now();
        }
        throw Exception('Invalid DateTime milliseconds for field: $key');
      }
    }

    // Fallback
    if (fallbackToNow) {
      debugPrint(
          '⚠️ Unknown DateTime format for field $key: ${value.runtimeType}, using now()');
      return DateTime.now();
    }
    throw Exception(
        'Invalid DateTime format for field: $key (type: ${value.runtimeType})');
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
  /// [hubId] - Hub ID to associate with (optional)
  /// [createdBy] - User ID who created this venue (optional)
  /// [isPublic] - Whether this is a public venue (default: true)
  ///
  /// Returns the created Venue with its Firestore ID
  Future<Venue> createManualVenue({
    required String name,
    String? address,
    required GeoPoint location,
    String? hubId,
    String? createdBy,
    bool isPublic = true,
  }) async {
    if (!Env.isFirebaseAvailable) {
      throw Exception('Firebase not available');
    }

    try {
      // Create Venue object
      final venue = Venue(
        venueId: '', // Will be generated by Firestore
        hubId: hubId ?? '', // Use provided hubId or empty string
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
        hubCount: hubId != null ? 1 : 0, // If assigned to hub, count = 1
        isPublic: isPublic,
      );

      // Convert to JSON and remove venueId (it's the document ID)
      final data = venue.toJson();
      data.remove('venueId');

      data['geohash'] = GeohashUtils.encode(
        location.latitude,
        location.longitude,
      );

      // Add to Firestore
      final docRef =
          await _firestore.collection(FirestorePaths.venues()).add(data);

      // Read the created document to get the full Venue with ID
      final createdDoc = await docRef.get();
      return Venue.fromJson({...createdDoc.data()!, 'venueId': docRef.id});
    } catch (e) {
      throw Exception('Failed to create manual venue: $e');
    }
  }

  /// Search venues from both Firestore and Google Places
  ///
  /// This method performs a hybrid search:
  /// 1. Searches Firestore for existing venues matching the name
  /// 2. Searches Google Places for venues
  /// 3. Merges results, prioritizing verified Firestore venues
  /// 4. Dedupes based on googlePlaceId
  Future<List<Venue>> searchVenuesCombined(String query) async {
    if (query.length < 2) return [];

    try {
      // Get current location for better relevance
      double lat = 32.0853; // Default to Tel Aviv
      double lng = 34.7818;

      try {
        // Try to get current location, but don't block if it fails or takes too long
        final position = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 2));
        lat = position.latitude;
        lng = position.longitude;
      } catch (e) {
        // Ignore location errors, use default
        debugPrint('⚠️ Could not get current location, using default: $e');
      }

      // 1. Search Firestore (concurrently)
      // Note: This requires an index on 'name'
      // We use the startAt/endAt pattern for prefix search
      final firestoreFuture = _firestore
          .collection(FirestorePaths.venues())
          .where('isActive', isEqualTo: true)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      // 2. Search Google Places via Cloud Function (concurrently)
      // Use Cloud Function to avoid API key restrictions
      // Check authentication first
      Future<List<PlaceResult>> googleFuture;

      try {
        // Check if user is authenticated before calling Cloud Function
        final auth = FirebaseAuth.instance;
        final currentUser = auth.currentUser;
        if (currentUser == null) {
          debugPrint(
              '⚠️ User not authenticated - skipping Google Places search (will only search Firestore)');
          googleFuture = Future.value(<PlaceResult>[]);
        } else {
          debugPrint(
              '✅ User authenticated (${currentUser.uid}) - will search Google Places');
          final functions =
              FirebaseFunctions.instanceFor(region: 'us-central1');
          googleFuture = functions.httpsCallable('searchVenues').call({
            'query': query,
            'lat': lat,
            'lng': lng,
          }).then((result) {
            final data = result.data as Map<String, dynamic>?;
            if (data == null) {
              debugPrint('⚠️ searchVenues returned null data');
              return <PlaceResult>[];
            }

            final results = data['results'] as List<dynamic>? ?? [];
            debugPrint(
                '✅ Found ${results.length} Google Places results for "$query"');

            return results
                .map((place) {
                  try {
                    final geometry = place['geometry'] as Map<String, dynamic>?;
                    final location =
                        geometry?['location'] as Map<String, dynamic>?;
                    return PlaceResult(
                      placeId: place['place_id'] as String? ?? '',
                      name: place['name'] as String? ?? '',
                      address: place['formatted_address'] as String?,
                      latitude: (location?['lat'] as num?)?.toDouble() ?? 0.0,
                      longitude: (location?['lng'] as num?)?.toDouble() ?? 0.0,
                      types: List<String>.from(place['types'] ?? []),
                      isPublic: true,
                    );
                  } catch (e) {
                    debugPrint('⚠️ Error parsing place result: $e');
                    return null;
                  }
                })
                .whereType<PlaceResult>()
                .toList();
          }).catchError((error) {
            // Better error handling - don't show error to user, just skip Google Places
            if (error is FirebaseFunctionsException) {
              if (error.code == 'unauthenticated') {
                debugPrint(
                    '⚠️ User not authenticated - skipping Google Places search (this is OK)');
              } else if (error.code == 'resource-exhausted') {
                debugPrint(
                    '⚠️ Rate limit exceeded for venue search - skipping Google Places');
              } else {
                debugPrint(
                    '⚠️ Firebase Functions error: ${error.code} - ${error.message} - skipping Google Places');
              }
            } else {
              debugPrint(
                  '⚠️ Google Places search error: $error - skipping Google Places');
            }
            return <PlaceResult>[]; // Return empty list on error - user can still search Firestore
          });
        }
      } catch (e) {
        debugPrint('❌ Error setting up Google Places search: $e');
        googleFuture = Future.value(<PlaceResult>[]);
      }

      // Wait for both results
      final results = await Future.wait([
        firestoreFuture,
        googleFuture,
      ]);

      final firestoreSnapshot = results[0] as QuerySnapshot;
      final googleResults = results[1] as List<PlaceResult>;

      debugPrint(
          '📊 Search results: ${firestoreSnapshot.docs.length} from Firestore, ${googleResults.length} from Google');

      final venues = <Venue>[];
      final existingGooglePlaceIds = <String>{};

      // Process Firestore results first (Priority)
      for (final doc in firestoreSnapshot.docs) {
        try {
          final venue = Venue.fromJson(
              {...doc.data() as Map<String, dynamic>, 'venueId': doc.id});
          venues.add(venue);
          if (venue.googlePlaceId != null && venue.googlePlaceId!.isNotEmpty) {
            existingGooglePlaceIds.add(venue.googlePlaceId!);
          }
        } catch (e) {
          debugPrint('⚠️ Error parsing Firestore venue: $e');
          // Skip invalid documents
        }
      }

      // Process Google results
      for (final place in googleResults) {
        // Skip if we already have this venue from Firestore
        if (existingGooglePlaceIds.contains(place.placeId)) {
          continue;
        }

        // Convert to temporary Venue object
        // Note: These venues have empty venueId until saved
        venues.add(place.toVenue(hubId: ''));
      }

      debugPrint('✅ Returning ${venues.length} total venues for "$query"');
      return venues;
    } catch (e, stackTrace) {
      debugPrint('❌ Error in searchVenuesCombined: $e');
      debugPrint('Stack trace: $stackTrace');
      // If everything fails, return empty list
      return [];
    }
  }

  /// Validate venue data before saving
  // ignore: unused_element
  void _validateVenueData(Map<String, dynamic> data) {
    // Validate required fields
    final name = data['name'] as String?;
    if (name == null || name.isEmpty) {
      throw Exception('Venue name is required');
    }

    if (!data.containsKey('location') || data['location'] == null) {
      throw Exception('Venue location is required');
    }

    // Validate location coordinates
    final location = data['location'] as GeoPoint;
    if (location.latitude < -90 || location.latitude > 90) {
      throw Exception('Invalid latitude: ${location.latitude}');
    }
    if (location.longitude < -180 || location.longitude > 180) {
      throw Exception('Invalid longitude: ${location.longitude}');
    }

    // Validate surfaceType
    final surfaceType = data['surfaceType'] as String? ?? 'grass';
    if (!['grass', 'artificial', 'concrete', 'unknown'].contains(surfaceType)) {
      throw Exception('Invalid surfaceType: $surfaceType');
    }

    // Validate maxPlayers
    final maxPlayers = data['maxPlayers'] as int? ?? 11;
    if (maxPlayers < 5 || maxPlayers > 22) {
      throw Exception('maxPlayers must be between 5 and 22');
    }
  }

  /// Batch update venues to ensure data quality
  /// This should be run periodically or via Cloud Function
  Future<int> normalizeExistingVenues({int? limit}) async {
    if (!Env.isFirebaseAvailable) return 0;

    try {
      final snapshot = await _firestore
          .collection(FirestorePaths.venues())
          .limit(limit ?? 100)
          .get();

      int updated = 0;
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        try {
          final normalized = _normalizeVenueData(doc.data(), doc.id);

          // Check if update is needed
          bool needsUpdate = false;
          for (final key in normalized.keys) {
            if (key == 'venueId') continue;
            if (!doc.data().containsKey(key) ||
                doc.data()[key] != normalized[key]) {
              needsUpdate = true;
              break;
            }
          }

          if (needsUpdate) {
            normalized['updatedAt'] = FieldValue.serverTimestamp();
            batch.update(doc.reference, normalized);
            updated++;
          }
        } catch (e) {
          debugPrint('⚠️ Error normalizing venue ${doc.id}: $e');
        }
      }

      if (updated > 0) {
        await batch.commit();
        debugPrint('✅ Updated $updated venues');
      }

      return updated;
    } catch (e) {
      debugPrint('❌ Error normalizing venues: $e');
      return 0;
    }
  }

  // ignore: unused_element
  String _normalizeSurfaceType(dynamic value) {
    if (value is! String) return 'grass';

    final normalized = value.toLowerCase().trim();

    // Map common variations to standard values
    final surfaceMap = {
      'artificial_turf': 'artificial',
      'artificial': 'artificial',
      'synthetic': 'artificial',
      'turf': 'artificial',
      'grass': 'grass',
      'natural': 'grass',
      'concrete': 'concrete',
      'asphalt': 'concrete',
      'hard': 'concrete',
      'unknown': 'unknown',
      '': 'unknown',
    };

    return surfaceMap[normalized] ?? 'unknown';
  }
}
