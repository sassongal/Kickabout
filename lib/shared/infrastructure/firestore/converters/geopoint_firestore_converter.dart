import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// DEPRECATED: Use GeographicPointFirestoreConverter instead
///
/// Legacy GeoPoint converter for Firestore.
/// Supports both nullable (GeoPoint?) and non-nullable (GeoPoint) fields.
///
/// This converter is deprecated and will be removed in a future version.
/// Use GeographicPoint and GeographicPointFirestoreConverter instead.
class GeoPointConverter implements JsonConverter<GeoPoint, Object?> {
  const GeoPointConverter();

  @override
  GeoPoint fromJson(Object? json) {
    if (json == null) {
      throw ArgumentError('GeoPoint cannot be null for required fields');
    }
    if (json is GeoPoint) return json;
    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    throw ArgumentError('Invalid GeoPoint format: $json');
  }

  @override
  Object? toJson(GeoPoint object) => object;
}

/// DEPRECATED: Use NullableGeographicPointFirestoreConverter instead
///
/// Nullable GeoPoint converter for optional fields.
class NullableGeoPointConverter implements JsonConverter<GeoPoint?, Object?> {
  const NullableGeoPointConverter();

  @override
  GeoPoint? fromJson(Object? json) {
    if (json == null) return null;
    if (json is GeoPoint) return json;
    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat != null && lng != null) {
        return GeoPoint(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  @override
  Object? toJson(GeoPoint? object) => object;
}
