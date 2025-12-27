import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/geographic_point_firestore_converter.dart';
import 'package:kattrick/features/hubs/domain/models/hub_settings.dart';

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

    // Settings (typed for compile-time safety)
    @HubSettingsConverter() @Default(HubSettings()) HubSettings settings,

    // @deprecated Legacy settings map - kept for backward compatibility during migration
    // Use `settings` field instead. Will be removed after all data is migrated.
    @Deprecated('Use settings field instead') Map<String, dynamic>? legacySettings,

    // Custom permissions (RARE overrides only)
    // Example: Allow specific user to create events even if not moderator
    // Format: {'canCreateEvents': ['userId1', 'userId2']}
    @Default({}) Map<String, dynamic> permissions,

    // Location & venues
    @NullableGeographicPointFirestoreConverter()
    GeographicPoint? location, // Primary location (deprecated, use venues)
    String? geohash,
    double? radius, // radius in km
    @Default([]) List<String> venueIds, // IDs of venues where this hub plays
    String? mainVenueId, // ID of the main venue (home field) - required
    String?
        primaryVenueId, // ID of the primary venue (for map display) - denormalized
    @NullableGeographicPointFirestoreConverter()
    GeographicPoint? primaryVenueLocation, // Location of primary venue - denormalized

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

  const Hub._();

  factory Hub.fromJson(Map<String, dynamic> json) => _$HubFromJson(json);

  // ============================================================================
  // BUSINESS LOGIC METHODS
  // ============================================================================

  // Membership capacity
  /// Whether the hub has reached its maximum member capacity
  bool get isFull => settings.maxMembers > 0 && memberCount >= settings.maxMembers;

  /// Whether the hub has available slots for new members
  bool get hasSpace => !isFull;

  /// Number of available member slots (999 if unlimited)
  int get availableSlots => settings.maxMembers > 0
      ? settings.maxMembers - memberCount
      : 999;

  // Joining policies
  /// Whether joining requires manager approval
  bool get requiresApproval => settings.joinMode.requiresApproval;

  /// Whether members can join automatically without approval
  bool get allowsAutoJoin => settings.joinMode.allowsAutoJoin;

  // Role checks (uses denormalized arrays for O(1) lookup)
  /// Check if a user is a manager of this hub
  bool isManager(String userId) => managerIds.contains(userId);

  /// Check if a user is a moderator of this hub
  bool isModerator(String userId) => moderatorIds.contains(userId);

  /// Check if a user is an active member of this hub
  bool isActiveMember(String userId) => activeMemberIds.contains(userId);

  /// Check if a user is the creator of this hub
  bool isCreator(String userId) => createdBy == userId;

  // Invitations
  /// Get the invitation code for this hub (falls back to hubId prefix)
  String get inviteCode => settings.invitationCode ?? hubId.substring(0, 8);

  /// Whether invitations are enabled for this hub
  bool get invitationsEnabled => settings.invitationsEnabled;

  // Display helpers
  /// Get formatted member count text in Hebrew
  String get memberCountText => '$memberCount ${memberCount == 1 ? 'חבר' : 'חברים'}';
}

/// Firestore converter for Hub
class HubConverter implements JsonConverter<Hub, Map<String, dynamic>> {
  const HubConverter();

  @override
  Hub fromJson(Map<String, dynamic> json) => Hub.fromJson(json);

  @override
  Map<String, dynamic> toJson(Hub object) => object.toJson();
}
