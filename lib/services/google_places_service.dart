import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/config/env.dart';
import 'package:kickadoor/models/venue.dart';

/// Google Places API result model
class PlaceResult {
  final String placeId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final double? rating;
  final int? userRatingsTotal;
  final List<String> types; // e.g., ["sports_complex", "stadium", "establishment"]
  final String? website;
  final bool isPublic; // Public vs rental
  final Map<String, dynamic>? additionalData;

  PlaceResult({
    required this.placeId,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.rating,
    this.userRatingsTotal,
    required this.types,
    this.website,
    this.isPublic = true,
    this.additionalData,
  });

  /// Check if this is a football/sports venue
  bool get isSportsVenue {
    return types.any((type) => [
      'stadium',
      'sports_complex',
      'gym',
      'park',
      'establishment',
    ].contains(type));
  }

  /// Convert to Venue model
  Venue toVenue({
    required String hubId,
    String? createdBy,
  }) {
    return Venue(
      venueId: '', // Will be generated
      hubId: hubId,
      name: name,
      description: address,
      location: GeoPoint(latitude, longitude),
      address: address,
      googlePlaceId: placeId,
      amenities: _extractAmenities(),
      surfaceType: _detectSurfaceType(),
      maxPlayers: 11, // Default
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
      isActive: true,
    );
  }

  List<String> _extractAmenities() {
    final amenities = <String>[];
    // Extract from types and additional data
    if (types.contains('park')) amenities.add('outdoor');
    if (additionalData?['has_parking'] == true) amenities.add('parking');
    if (additionalData?['has_lights'] == true) amenities.add('lights');
    return amenities;
  }

  String _detectSurfaceType() {
    // Try to detect from name or types
    final nameLower = name.toLowerCase();
    if (nameLower.contains('synthetic') || nameLower.contains('artificial')) {
      return 'artificial';
    }
    if (nameLower.contains('concrete') || nameLower.contains('hard')) {
      return 'concrete';
    }
    return 'grass'; // Default
  }
}

/// Service for Google Places API integration
class GooglePlacesService {
  final String apiKey;
  final http.Client _httpClient;

  GooglePlacesService({String? apiKey, http.Client? httpClient})
      : apiKey = apiKey ?? Env.googleMapsApiKey ?? '',
        _httpClient = httpClient ?? http.Client();

  /// Search for venues near a location
  /// 
  /// [query] - Search query (e.g., "football field", "מגרש כדורגל")
  /// [latitude] - Center latitude
  /// [longitude] - Center longitude
  /// [radius] - Search radius in meters (default 5000 = 5km)
  /// [includeRentals] - Include venues available for rent
  Future<List<PlaceResult>> searchVenues({
    String? query,
    required double latitude,
    required double longitude,
    int radius = 5000,
    bool includeRentals = true,
  }) async {
    if (apiKey.isEmpty) {
      throw Exception('Google Maps API key not configured');
    }

    try {
      // Search for sports venues
      final results = <PlaceResult>[];

      // 1. Text search for football fields
      if (query != null && query.isNotEmpty) {
        final textSearchResults = await _textSearch(
          query: query,
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );
        results.addAll(textSearchResults);
      }

      // 2. Nearby search for sports complexes
      final nearbyResults = await _nearbySearch(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
      );
      results.addAll(nearbyResults);

      // 3. If includeRentals, search for rental venues
      if (includeRentals) {
        final rentalResults = await _searchRentals(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );
        results.addAll(rentalResults);
      }

      // Remove duplicates and sort by distance
      final uniqueResults = <String, PlaceResult>{};
      for (final result in results) {
        if (!uniqueResults.containsKey(result.placeId)) {
          uniqueResults[result.placeId] = result;
        }
      }

      // Sort by distance
      final sortedResults = uniqueResults.values.toList();
      sortedResults.sort((a, b) {
        final distA = _calculateDistance(latitude, longitude, a.latitude, a.longitude);
        final distB = _calculateDistance(latitude, longitude, b.latitude, b.longitude);
        return distA.compareTo(distB);
      });

      return sortedResults;
    } catch (e) {
      throw Exception('Failed to search venues: $e');
    }
  }

  /// Text search using Google Places API
  Future<List<PlaceResult>> _textSearch({
    required String query,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent(query)}'
      '&location=$latitude,$longitude'
      '&radius=$radius'
      '&type=stadium|gym|park|establishment'
      '&key=$apiKey'
      '&language=he',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      throw Exception('Google Places API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      throw Exception('Google Places API error: ${data['status']}');
    }

    final results = <PlaceResult>[];
    for (final place in data['results'] ?? []) {
      final location = place['geometry']?['location'];
      if (location != null) {
        results.add(PlaceResult(
          placeId: place['place_id'],
          name: place['name'],
          address: place['formatted_address'],
          latitude: location['lat']?.toDouble() ?? 0.0,
          longitude: location['lng']?.toDouble() ?? 0.0,
          phoneNumber: place['formatted_phone_number'],
          rating: place['rating']?.toDouble(),
          userRatingsTotal: place['user_ratings_total'],
          types: List<String>.from(place['types'] ?? []),
          website: place['website'],
          isPublic: true,
        ));
      }
    }

    return results;
  }

  /// Nearby search for sports venues
  Future<List<PlaceResult>> _nearbySearch({
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$latitude,$longitude'
      '&radius=$radius'
      '&type=stadium|gym|park|establishment'
      '&keyword=${Uri.encodeComponent("מגרש כדורגל|football field|soccer field")}'
      '&key=$apiKey'
      '&language=he',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      throw Exception('Google Places API error: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      throw Exception('Google Places API error: ${data['status']}');
    }

    final results = <PlaceResult>[];
    for (final place in data['results'] ?? []) {
      final location = place['geometry']?['location'];
      if (location != null) {
        results.add(PlaceResult(
          placeId: place['place_id'],
          name: place['name'],
          address: place['vicinity'] ?? place['formatted_address'],
          latitude: location['lat']?.toDouble() ?? 0.0,
          longitude: location['lng']?.toDouble() ?? 0.0,
          phoneNumber: place['formatted_phone_number'],
          rating: place['rating']?.toDouble(),
          userRatingsTotal: place['user_ratings_total'],
          types: List<String>.from(place['types'] ?? []),
          website: place['website'],
          isPublic: true,
        ));
      }
    }

    return results;
  }

  /// Search for rental venues (using custom API or additional search)
  Future<List<PlaceResult>> _searchRentals({
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    // This can be extended to use your custom API
    // For now, search for venues that might be available for rent
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?location=$latitude,$longitude'
      '&radius=$radius'
      '&type=establishment'
      '&keyword=${Uri.encodeComponent("השכרת מגרש|field rental|sports rental")}'
      '&key=$apiKey'
      '&language=he',
    );

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      return []; // Return empty if fails
    }

    final data = json.decode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      return [];
    }

    final results = <PlaceResult>[];
    for (final place in data['results'] ?? []) {
      final location = place['geometry']?['location'];
      if (location != null) {
        results.add(PlaceResult(
          placeId: place['place_id'],
          name: place['name'],
          address: place['vicinity'] ?? place['formatted_address'],
          latitude: location['lat']?.toDouble() ?? 0.0,
          longitude: location['lng']?.toDouble() ?? 0.0,
          phoneNumber: place['formatted_phone_number'],
          rating: place['rating']?.toDouble(),
          userRatingsTotal: place['user_ratings_total'],
          types: List<String>.from(place['types'] ?? []),
          website: place['website'],
          isPublic: false, // Rental venues
        ));
      }
    }

    return results;
  }

  /// Get place details by place ID
  Future<PlaceResult?> getPlaceDetails(String placeId) async {
    if (apiKey.isEmpty) {
      throw Exception('Google Maps API key not configured');
    }

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=$placeId'
        '&fields=name,formatted_address,geometry,formatted_phone_number,rating,user_ratings_total,types,website,opening_hours'
        '&key=$apiKey'
        '&language=he',
      );

      final response = await _httpClient.get(url);
      if (response.statusCode != 200) {
        throw Exception('Google Places API error: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['status'] != 'OK') {
        return null;
      }

      final place = data['result'];
      final location = place['geometry']?['location'];
      if (location == null) return null;

      return PlaceResult(
        placeId: place['place_id'],
        name: place['name'],
        address: place['formatted_address'],
        latitude: location['lat']?.toDouble() ?? 0.0,
        longitude: location['lng']?.toDouble() ?? 0.0,
        phoneNumber: place['formatted_phone_number'],
        rating: place['rating']?.toDouble(),
        userRatingsTotal: place['user_ratings_total'],
        types: List<String>.from(place['types'] ?? []),
        website: place['website'],
        isPublic: true,
        additionalData: {
          'opening_hours': place['opening_hours'],
        },
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = (lat2 - lat1).toRadians();
    final dLon = (lon2 - lon1).toRadians();

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1.toRadians()) *
            math.cos(lat2.toRadians()) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}

extension MathExtensions on double {
  double toRadians() => this * (math.pi / 180);
}

