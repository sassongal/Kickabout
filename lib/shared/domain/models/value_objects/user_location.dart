import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/geographic_point_firestore_converter.dart';
import 'package:kattrick/utils/geohash_utils.dart';

part 'user_location.freezed.dart';
part 'user_location.g.dart';

/// User location value object
///
/// Extracted from User model to follow Single Responsibility Principle.
/// Encapsulates location data with automatic geohash calculation.
@freezed
class UserLocation with _$UserLocation {
  const factory UserLocation({
    @NullableGeographicPointFirestoreConverter() GeographicPoint? location,
    String? geohash,
    String? city,
    String? region,
  }) = _UserLocation;

  factory UserLocation.fromJson(Map<String, dynamic> json) =>
      _$UserLocationFromJson(json);

  /// Create from coordinates with automatic geohash calculation
  factory UserLocation.fromCoordinates({
    required double latitude,
    required double longitude,
    String? city,
    String? region,
  }) {
    final location = GeographicPoint(latitude: latitude, longitude: longitude);
    final geohash = GeohashUtils.encode(latitude, longitude, precision: 8);

    return UserLocation(
      location: location,
      geohash: geohash,
      city: city,
      region: region,
    );
  }
}
