import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';

/// Firestore converter for GeographicPoint - infrastructure layer only
///
/// Converts between domain GeographicPoint and Firestore GeoPoint.
/// This keeps Firestore types isolated to the infrastructure layer.
class GeographicPointFirestoreConverter
    implements JsonConverter<GeographicPoint, Object?> {
  const GeographicPointFirestoreConverter();

  @override
  GeographicPoint fromJson(Object? json) {
    if (json == null) {
      throw ArgumentError('GeographicPoint cannot be null for required fields');
    }

    if (json is GeoPoint) {
      return GeographicPoint(
        latitude: json.latitude,
        longitude: json.longitude,
      );
    }

    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat != null && lng != null) {
        return GeographicPoint(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
        );
      }
    }

    throw ArgumentError('Invalid GeographicPoint format: $json');
  }

  @override
  Object toJson(GeographicPoint object) {
    return GeoPoint(object.latitude, object.longitude);
  }
}

/// Nullable GeographicPoint converter for optional location fields
class NullableGeographicPointFirestoreConverter
    implements JsonConverter<GeographicPoint?, Object?> {
  const NullableGeographicPointFirestoreConverter();

  @override
  GeographicPoint? fromJson(Object? json) {
    if (json == null) return null;

    if (json is GeoPoint) {
      return GeographicPoint(
        latitude: json.latitude,
        longitude: json.longitude,
      );
    }

    if (json is Map) {
      final lat = json['latitude'] as num?;
      final lng = json['longitude'] as num?;
      if (lat != null && lng != null) {
        return GeographicPoint(
          latitude: lat.toDouble(),
          longitude: lng.toDouble(),
        );
      }
    }

    return null;
  }

  @override
  Object? toJson(GeographicPoint? object) {
    if (object == null) return null;
    return GeoPoint(object.latitude, object.longitude);
  }
}
