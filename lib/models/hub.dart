import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/models/converters/timestamp_converter.dart';
import 'package:kickadoor/models/converters/timestamp_map_converter.dart';
import 'package:kickadoor/models/converters/geopoint_converter.dart';

part 'hub.freezed.dart';
part 'hub.g.dart';

/// Hub model matching Firestore schema: /hubs/{hubId}
@freezed
class Hub with _$Hub {
  const factory Hub({
    required String hubId,
    required String name,
    String? description,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    @Default([]) List<String> memberIds,
    @Default({}) @TimestampMapConverter() Map<String, Timestamp> memberJoinDates, // userId -> join date timestamp
    @Default({
      'ratingMode': 'basic',
      'showManagerContactInfo': true,
      'allowJoinRequests': true,
    })
    Map<String, dynamic> settings,
    @Default({}) Map<String, String> roles, // userId -> role (manager, moderator, member)
    @Default({}) Map<String, dynamic> permissions, // Custom permissions: {canCreateEvents: [userId1, userId2], canCreatePosts: [userId1, userId2]}
    @NullableGeoPointConverter() GeoPoint? location, // Primary location (deprecated, use venues)
    String? geohash,
    double? radius, // radius in km
    @Default([]) List<String> venueIds, // IDs of venues where this hub plays
    String? profileImageUrl, // Profile picture chosen by hub manager
    String? mainVenueId, // ID of the main venue (home field) - required
    String? primaryVenueId, // ID of the primary venue (for map display) - denormalized
    @NullableGeoPointConverter() GeoPoint? primaryVenueLocation, // Location of primary venue - denormalized
    String? logoUrl, // Hub logo URL (used for feed posts)
    String? hubRules, // Rules and guidelines for the hub
    String? region, // אזור: צפון, מרכז, דרום, ירושלים
    // Privacy settings
    @Default(false) bool isPrivate, // If true, requires "Request to Join" (create notification for manager)
    // Manager-only ratings for team balancing (1-10 scale)
    @Default({}) Map<String, double> managerRatings, // userId -> rating (1-10, manager-only, for team balancing)
    // Payment settings
    String? paymentLink, // PayBox/Bit payment link URL
    // Denormalized fields (updated by Cloud Functions, not written by client)
    int? gameCount, // Denormalized: Total games created (updated by onGameCreated)
    @TimestampConverter() DateTime? lastActivity, // Denormalized: Last activity time (updated by Cloud Functions)
  }) = _Hub;

  factory Hub.fromJson(Map<String, dynamic> json) => _$HubFromJson(json);
}

/// Firestore converter for Hub
class HubConverter implements JsonConverter<Hub, Map<String, dynamic>> {
  const HubConverter();

  @override
  Hub fromJson(Map<String, dynamic> json) => Hub.fromJson(json);

  @override
  Map<String, dynamic> toJson(Hub object) => object.toJson();
}
