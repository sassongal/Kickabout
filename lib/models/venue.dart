import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';
import 'package:kattrick/models/converters/geopoint_converter.dart';

part 'venue.freezed.dart';
part 'venue.g.dart';

/// Venue/Field model - represents a physical football field/venue
/// A Hub can have multiple venues where they play
@freezed
class Venue with _$Venue {
  const factory Venue({
    required String venueId,
    @Default(0)
    int venueNumber, // Unique sequential number for this venue (like hubId)
    required String hubId, // Which hub this venue belongs to
    required String name, // e.g., "גן דניאל - מגרש 1"
    String? description,
    @GeoPointConverter()
    required GeoPoint location, // Exact location from Google Maps
    String? address, // Human-readable address
    String? city, // עיר בה נמצא המגרש
    String? region, // אזור (מחושב אוטומטית מהעיר)
    String? googlePlaceId, // Google Places API ID for real venues
    @Default([])
    List<String> amenities, // e.g., ["parking", "showers", "lights"]
    @Default('grass') String surfaceType, // grass, artificial, concrete
    @Default(11) int maxPlayers, // Max players per team (default 11v11)
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
    String? createdBy, // User who added this venue
    @Default(true) bool isActive, // Can be deactivated without deleting
    @Default(false) bool isMain, // Is this the main/home venue for the hub
    @Default(0) int hubCount, // Number of hubs using this venue
    @Default(true) bool isPublic, // Whether this is a public venue
    @Default('manual') String source, // 'manual' or 'osm'
    String? externalId, // OSM ID
  }) = _Venue;

  factory Venue.fromJson(Map<String, dynamic> json) => _$VenueFromJson(json);
}

/// Firestore converter for Venue
class VenueConverter implements JsonConverter<Venue, Map<String, dynamic>> {
  const VenueConverter();

  @override
  Venue fromJson(Map<String, dynamic> json) => Venue.fromJson(json);

  @override
  Map<String, dynamic> toJson(Venue object) => object.toJson();
}
