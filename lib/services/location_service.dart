import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/config/env.dart';
import 'package:kattrick/utils/geohash_utils.dart';

/// Service for handling location-related operations
class LocationService {
  /// Get current location
  /// Returns null if permission denied or location unavailable
  Future<Position?> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.medium,
  }) async {
    if (Env.limitedMode) {
      return null;
    }

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // Get current position with timeout (10 seconds)
      // This prevents the app from hanging if location services are slow
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      return null;
    }
  }

  /// Convert address to coordinates (Geocoding)
  Future<Position?> addressToCoordinates(String address) async {
    if (Env.limitedMode) {
      return null;
    }

    try {
      final locations = await locationFromAddress(address);
      if (locations.isEmpty) return null;

      return Position(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get location from address string (alias for addressToCoordinates)
  /// Returns Position if geocoding succeeds, null otherwise
  Future<Position?> getLocationFromAddress(String address) async {
    return addressToCoordinates(address);
  }

  /// Get current location with fallback to manual entry
  /// Returns null if both GPS and manual entry fail
  Future<Position?> getCurrentLocationWithFallback({
    LocationAccuracy accuracy = LocationAccuracy.medium,
    String? manualCity,
  }) async {
    // Try GPS first
    final gpsLocation = await getCurrentLocation(accuracy: accuracy);
    if (gpsLocation != null) return gpsLocation;

    // If GPS fails and manual city provided, try geocoding
    if (manualCity != null && manualCity.isNotEmpty) {
      return await getLocationFromAddress(manualCity);
    }

    return null;
  }

  /// Convert coordinates to address (Reverse Geocoding)
  Future<String?> coordinatesToAddress(double lat, double lng) async {
    if (Env.limitedMode) {
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[];
      if (place.street != null) parts.add(place.street!);
      if (place.subThoroughfare != null) parts.add(place.subThoroughfare!);
      if (place.locality != null) parts.add(place.locality!);
      if (place.country != null) parts.add(place.country!);

      return parts.isEmpty ? null : parts.join(', ');
    } catch (e) {
      return null;
    }
  }

  /// Generate geohash from coordinates
  /// Precision: 7 = ~150m, 8 = ~20m, 9 = ~5m
  String generateGeohash(double lat, double lng, {int precision = 8}) {
    return GeohashUtils.encode(lat, lng, precision: precision);
  }

  /// Convert Position to Firestore GeoPoint
  GeoPoint positionToGeoPoint(Position position) {
    return GeoPoint(position.latitude, position.longitude);
  }

  /// Convert Firestore GeoPoint to Position
  Position? geoPointToPosition(GeoPoint? geoPoint) {
    if (geoPoint == null) return null;
    return Position(
      latitude: geoPoint.latitude,
      longitude: geoPoint.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  /// Calculate distance between two points in kilometers
  double distanceInKm(double lat1, double lng1, double lat2, double lng2) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  /// Calculate distance between two GeoPoints in kilometers
  double distanceBetweenGeoPoints(GeoPoint point1, GeoPoint point2) {
    return distanceInKm(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    );
  }
}

