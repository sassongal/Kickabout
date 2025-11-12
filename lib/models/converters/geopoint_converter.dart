import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// GeoPoint converter for Firestore
class GeoPointConverter implements JsonConverter<GeoPoint?, Object?> {
  const GeoPointConverter();

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

