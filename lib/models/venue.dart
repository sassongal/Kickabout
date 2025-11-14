import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

/// Venue/Field model - represents a physical football field/venue
/// A Hub can have multiple venues where they play
@freezed
class Venue with _$Venue {
  const factory Venue({
    required String venueId,
    required String hubId, // Which hub this venue belongs to
    required String name, // e.g., "גן דניאל - מגרש 1"
    String? description,
    @JsonKey(fromJson: _geoPointFromJson, toJson: _geoPointToJson) required GeoPoint location, // Exact location from Google Maps
    String? address, // Human-readable address
    String? googlePlaceId, // Google Places API ID for real venues
    @Default([]) List<String> amenities, // e.g., ["parking", "showers", "lights"]
    @Default('grass') String surfaceType, // grass, artificial, concrete
    @Default(11) int maxPlayers, // Max players per team (default 11v11)
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy, // User who added this venue
    @Default(true) bool isActive, // Can be deactivated without deleting
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}

// Helper functions for GeoPoint serialization (must be top-level for json_serializable)
GeoPoint _geoPointFromJson(Object? json) {
  if (json == null) throw ArgumentError('GeoPoint cannot be null');
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

Object? _geoPointToJson(GeoPoint object) => object;

/// Firestore converter for Venue
class VenueConverter implements JsonConverter<Venue, Map<String, dynamic>> {
  const VenueConverter();

  @override
  Venue fromJson(Map<String, dynamic> json) => Venue.fromJson(json);

  @override
  Map<String, dynamic> toJson(Venue object) => object.toJson();
}

