import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';

part 'geographic_point.freezed.dart';
part 'geographic_point.g.dart';

/// Geographic point value object - infrastructure-agnostic location representation
///
/// Replaces direct usage of Firestore's GeoPoint in domain models.
/// Encapsulates latitude/longitude with business logic for distance calculations
/// and validation.
@freezed
class GeographicPoint with _$GeographicPoint {
  const factory GeographicPoint({
    required double latitude,
    required double longitude,
  }) = _GeographicPoint;

  const GeographicPoint._();

  factory GeographicPoint.fromJson(Map<String, dynamic> json) =>
      _$GeographicPointFromJson(json);

  /// Create from validated coordinates
  factory GeographicPoint.fromCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }
    return GeographicPoint(latitude: latitude, longitude: longitude);
  }

  // ============================================================================
  // BUSINESS LOGIC
  // ============================================================================

  /// Calculate distance to another point in kilometers using Haversine formula
  double distanceToKm(GeographicPoint other) {
    const earthRadiusKm = 6371.0;

    final lat1Rad = _degreesToRadians(latitude);
    final lat2Rad = _degreesToRadians(other.latitude);
    final deltaLat = _degreesToRadians(other.latitude - latitude);
    final deltaLon = _degreesToRadians(other.longitude - longitude);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLon / 2) *
            math.sin(deltaLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  /// Calculate distance to another point in meters
  double distanceToMeters(GeographicPoint other) {
    return distanceToKm(other) * 1000;
  }

  /// Check if this point is within radius (km) of another point
  bool isWithinRadius(GeographicPoint center, double radiusKm) {
    return distanceToKm(center) <= radiusKm;
  }

  /// Calculate bearing to another point in degrees (0-360)
  double bearingTo(GeographicPoint other) {
    final lat1Rad = _degreesToRadians(latitude);
    final lat2Rad = _degreesToRadians(other.latitude);
    final deltaLon = _degreesToRadians(other.longitude - longitude);

    final y = math.sin(deltaLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(deltaLon);

    final bearingRad = math.atan2(y, x);
    final bearingDeg = _radiansToDegrees(bearingRad);

    return (bearingDeg + 360) % 360;
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  /// Check if coordinates are valid
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
  double _radiansToDegrees(double radians) => radians * 180 / math.pi;
}
