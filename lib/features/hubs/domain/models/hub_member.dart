import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kattrick/shared/infrastructure/firestore/converters/timestamp_firestore_converter.dart';

part 'hub_member.freezed.dart';
part 'hub_member.g.dart';

/// First-class membership entity - replaces Hub.memberJoinDates, Hub.roles, etc.
/// Firestore path: /hubs/{hubId}/members/{userId}
///
/// This model represents a user's membership in a hub, storing all per-user
/// data that was previously embedded in Hub document maps.
///
/// Key Design Decisions:
/// - veteranSince is SERVER-MANAGED (set by Cloud Function after 60 days)
/// - status enables soft-deletes (left) and bans without document deletion
/// - role is stored, not computed (no DateTime.now() usage)
/// - Audit trail with updatedAt/updatedBy for compliance
@freezed
class HubMember with _$HubMember {
  const factory HubMember({
    required String hubId,
    required String userId,

    // Core membership data
    @TimestampConverter() required DateTime joinedAt,
    @Default(HubMemberRole.member) HubMemberRole role,
    @Default(HubMemberStatus.active) HubMemberStatus status,

    // Time-based promotions (SERVER-MANAGED ONLY by Cloud Function)
    @TimestampConverter() DateTime? veteranSince,

    // Additional metadata (moved from Hub.managerRatings map)
    @Default(0.0) double managerRating,

    // Gamification stats (Sprint 2.3)
    @Default(0) int totalMvps, // Total "Man of the Match" awards in this hub

    // Activity tracking
    @TimestampConverter() DateTime? lastActiveAt,

    // Audit trail
    @TimestampConverter() DateTime? updatedAt,
    String? updatedBy, // userId or 'system:functionName'

    // Optional: reason for status change (for bans/kicks)
    String? statusReason,
  }) = _HubMember;

  const HubMember._();

  factory HubMember.fromJson(Map<String, dynamic> json) =>
      _$HubMemberFromJson(json);

  /// Helper: Is this member a veteran?
  bool get isVeteran => veteranSince != null;

  /// Helper: Days since joining (safe, uses stored joinedAt)
  int get daysSinceJoined {
    final now = DateTime.now();
    return now.difference(joinedAt).inDays;
  }

  /// Helper: Is membership active?
  bool get isActive => status == HubMemberStatus.active;

  /// Helper: Can this member be promoted to veteran?
  bool get canPromoteToVeteran {
    return role == HubMemberRole.member &&
        status == HubMemberStatus.active &&
        veteranSince == null;
  }
}

/// Role hierarchy - SINGLE SOURCE OF TRUTH for all permissions
///
/// Order matters: manager > moderator > veteran > member > guest
enum HubMemberRole {
  manager, // Hub creator or promoted manager - full control
  moderator, // Can manage content, players, create events
  veteran, // Long-time member (60+ days), can record results
  member; // Regular member, can create games and participate

  String get firestoreValue => name;

  String get displayName {
    switch (this) {
      case HubMemberRole.manager:
        return 'מנהל';
      case HubMemberRole.moderator:
        return 'מנחה';
      case HubMemberRole.veteran:
        return 'שחקן ותיק';
      case HubMemberRole.member:
        return 'חבר';
    }
  }

  static HubMemberRole fromString(String value) {
    return HubMemberRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HubMemberRole.member,
    );
  }

  /// Backward compatibility with old role strings from Hub.roles map
  static HubMemberRole fromFirestore(String value) {
    switch (value) {
      case 'manager':
      case 'admin': // Old value used in some hubs
        return HubMemberRole.manager;
      case 'moderator':
        return HubMemberRole.moderator;
      case 'veteran':
        return HubMemberRole.veteran;
      case 'member':
      default:
        return HubMemberRole.member;
    }
  }

  /// Role hierarchy comparison
  bool isAtLeast(HubMemberRole minRole) {
    const hierarchy = [
      HubMemberRole.member,
      HubMemberRole.veteran,
      HubMemberRole.moderator,
      HubMemberRole.manager,
    ];
    return hierarchy.indexOf(this) >= hierarchy.indexOf(minRole);
  }

  // Permission Matrix - SINGLE SOURCE OF TRUTH
  // Migrated from HubRole to consolidate role systems

  /// Can manage hub members (approve/kick/ban)
  bool get canManageMembers =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  /// Can change member roles
  bool get canManageRoles => this == HubMemberRole.manager;

  /// Can change hub settings
  bool get canManageSettings => this == HubMemberRole.manager;

  /// Can delete the hub
  bool get canDeleteHub => this == HubMemberRole.manager;

  /// Can create games
  bool get canCreateGames => this != HubMemberRole.member || isAtLeast(HubMemberRole.member);

  /// Can create events
  bool get canCreateEvents => isAtLeast(HubMemberRole.moderator);

  /// Can moderate content (delete posts/comments)
  bool get canModerateContent => isAtLeast(HubMemberRole.moderator);

  /// Can invite players
  bool get canInvitePlayers => isAtLeast(HubMemberRole.veteran);

  /// Can view analytics
  bool get canViewAnalytics => isAtLeast(HubMemberRole.veteran);

  /// Can record game results
  bool get canRecordGame => isAtLeast(HubMemberRole.veteran);

  /// Can edit hub info (name, description, branding)
  bool get canEditHubInfo => this == HubMemberRole.manager;

  /// Can delete posts
  bool get canDeletePosts => isAtLeast(HubMemberRole.moderator);

  /// Can delete comments
  bool get canDeleteComments => isAtLeast(HubMemberRole.moderator);
}

/// Membership status - replaces implicit "not in memberIds" logic
enum HubMemberStatus {
  active, // Currently an active member
  left, // User chose to leave (soft-delete)
  banned, // Kicked/banned by manager
  archived; // Archived by manager (can be restored)

  String get firestoreValue => name;

  String get displayName {
    switch (this) {
      case HubMemberStatus.active:
        return 'פעיל';
      case HubMemberStatus.left:
        return 'עזב';
      case HubMemberStatus.banned:
        return 'חסום';
      case HubMemberStatus.archived:
        return 'בארכיון';
    }
  }

  static HubMemberStatus fromString(String value) {
    return HubMemberStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => HubMemberStatus.active,
    );
  }
}

/// Firestore converter for HubMember
class HubMemberConverter
    implements JsonConverter<HubMember, Map<String, dynamic>> {
  const HubMemberConverter();

  @override
  HubMember fromJson(Map<String, dynamic> json) => HubMember.fromJson(json);

  @override
  Map<String, dynamic> toJson(HubMember object) => object.toJson();
}
