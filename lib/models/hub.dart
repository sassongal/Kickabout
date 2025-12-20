import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/models/converters/timestamp_converter.dart';
import 'package:kattrick/models/converters/geopoint_converter.dart';

part 'hub.freezed.dart';
part 'hub.g.dart';

/// Hub model - REFACTORED to remove god-object anti-pattern
///
/// Firestore path: /hubs/{hubId}
///
/// IMPORTANT CHANGES (2025-12-03 Membership Refactor):
/// ❌ REMOVED: memberJoinDates, roles, managerRatings, bannedUserIds
/// ✅ NOW IN: /hubs/{hubId}/members/{userId} (HubMember model)
/// ✅ KEPT: memberCount (denormalized counter, updated by Cloud Function)
///
/// This model now represents hub IDENTITY only, not membership lists.
/// All per-user data lives in the HubMember subcollection.
///
/// PERFORMANCE OPTIMIZATION (2025-12-20):
/// Added denormalized member arrays (activeMemberIds, managerIds, moderatorIds)
/// to eliminate costly get() calls in Firestore security rules.
/// These arrays MUST be kept in sync by HubsRepository methods.
@freezed
class Hub with _$Hub {
  const factory Hub({
    // Core identity
    required String hubId,
    required String name,
    String? description,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,

    // Member count (denormalized for display, kept in sync by Cloud Function)
    @Default(0) int memberCount,

    // Denormalized member arrays (CRITICAL for Firestore Rules optimization)
    // These eliminate costly get() calls in security rules by denormalizing
    // membership data directly into the Hub document.
    // ⚠️ MUST be kept in sync by repository methods (addMember, removeMember, updateMemberRole)
    @Default([]) List<String> activeMemberIds, // All active member user IDs
    @Default([]) List<String> managerIds, // User IDs with 'manager' role
    @Default([]) List<String> moderatorIds, // User IDs with 'moderator' role

    // Settings
    @Default({
      'showManagerContactInfo': true,
      'allowJoinRequests': true,
      'allowModeratorsToCreateGames':
          false, // Allow moderators to open games from events
    })
    Map<String, dynamic> settings,

    // Custom permissions (RARE overrides only)
    // Example: Allow specific user to create events even if not moderator
    // Format: {'canCreateEvents': ['userId1', 'userId2']}
    @Default({}) Map<String, dynamic> permissions,

    // Location & venues
    @NullableGeoPointConverter()
    GeoPoint? location, // Primary location (deprecated, use venues)
    String? geohash,
    double? radius, // radius in km
    @Default([]) List<String> venueIds, // IDs of venues where this hub plays
    String? mainVenueId, // ID of the main venue (home field) - required
    String?
        primaryVenueId, // ID of the primary venue (for map display) - denormalized
    @NullableGeoPointConverter()
    GeoPoint? primaryVenueLocation, // Location of primary venue - denormalized

    // Branding
    String? profileImageUrl, // Profile picture chosen by hub manager
    String? logoUrl, // Hub logo URL (used for feed posts)
    String? bannerUrl, // Hero banner for hub profile

    // Rules & region
    String? hubRules, // Rules and guidelines for the hub
    String? region, // אזור: צפון, מרכז, דרום, ירושלים
    String? city, // עיר ראשית של ההאב (auto-calculates region)

    // Privacy
    @Default(false) bool isPrivate, // If true, requires "Request to Join"

    // Payment
    String? paymentLink, // PayBox/Bit payment link URL

    // Denormalized stats (updated by Cloud Functions, not written by client)
    int? gameCount, // Total games created (updated by onGameCreated)
    @TimestampConverter()
    DateTime? lastActivity, // Last activity time (updated by Cloud Functions)
    @Default(0) double activityScore, // Activity score
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
