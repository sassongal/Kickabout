import 'package:kattrick/models/hub_member.dart';

/// @deprecated Use HubMemberRole instead. This enum is maintained only for backward compatibility.
/// Will be removed in future version.
///
/// Simple user role enum for permission checks
enum UserRole {
  admin,
  member,
  none;

  /// Check if user has admin permissions
  bool get isAdmin => this == UserRole.admin;

  /// Check if user is a member
  bool get isMember => this == UserRole.member || this == UserRole.admin;

  /// Convert to HubMemberRole (migration utility)
  HubMemberRole? toHubMemberRole() {
    switch (this) {
      case UserRole.admin:
        return HubMemberRole.manager;
      case UserRole.member:
        return HubMemberRole.member;
      case UserRole.none:
        return null;
    }
  }
}

/// @deprecated Use HubMemberRole instead. This enum is maintained only for backward compatibility.
/// Will be removed in future version. All permission logic has been moved to HubMemberRole.
///
/// Hub role enum
enum HubRole {
  manager,
  moderator,
  member,
  veteran, // Veteran player (in hub for more than 2 months)
  guest; // Non-member

  String get displayName {
    switch (this) {
      case HubRole.manager:
        return 'מנהל';
      case HubRole.moderator:
        return 'מנחה';
      case HubRole.member:
        return 'חבר';
      case HubRole.veteran:
        return 'שחקן ותיק';
      case HubRole.guest:
        return 'אורח';
    }
  }

  String get firestoreValue {
    switch (this) {
      case HubRole.manager:
        return 'manager';
      case HubRole.moderator:
        return 'moderator';
      case HubRole.member:
        return 'member';
      case HubRole.veteran:
        return 'veteran';
      case HubRole.guest:
        return 'guest';
    }
  }

  static HubRole fromFirestore(String value) {
    switch (value) {
      case 'manager':
      case 'admin': // Backward compatibility
        return HubRole.manager;
      case 'moderator':
        return HubRole.moderator;
      case 'veteran':
        return HubRole.veteran;
      case 'member':
        return HubRole.member;
      default:
        return HubRole.guest;
    }
  }

  /// Convert to canonical HubMemberRole (migration utility)
  HubMemberRole toHubMemberRole() {
    switch (this) {
      case HubRole.manager:
        return HubMemberRole.manager;
      case HubRole.moderator:
        return HubMemberRole.moderator;
      case HubRole.veteran:
        return HubMemberRole.veteran;
      case HubRole.member:
      case HubRole.guest:
        return HubMemberRole.member;
    }
  }

  /// @deprecated Use HubMemberRole permission methods instead
  /// Check if role has permission to perform action
  ///
  /// Permission Matrix (Gap Analysis #1):
  /// - Manager: Full access to everything
  /// - Moderator: Can manage members, create games/events, moderate content
  /// - Veteran: ✅ Can RECORD GAME RESULTS (new!), create games, view analytics, invite players
  /// - Member: Can create games, view content, participate
  /// - Guest: Read-only
  bool canManageMembers() =>
      this == HubRole.manager || this == HubRole.moderator;
  bool canManageRoles() => this == HubRole.manager;
  bool canManageSettings() => this == HubRole.manager;
  bool canDeleteHub() => this == HubRole.manager;
  bool canCreateGames() =>
      this == HubRole.manager ||
      this == HubRole.moderator ||
      this == HubRole.member ||
      this == HubRole.veteran;
  bool canCreateEvents() =>
      this == HubRole.manager || this == HubRole.moderator;
  bool canModerateContent() =>
      this == HubRole.manager || this == HubRole.moderator;
  bool canInvitePlayers() =>
      this == HubRole.manager ||
      this == HubRole.moderator ||
      this == HubRole.veteran;
  bool canViewAnalytics() =>
      this == HubRole.manager ||
      this == HubRole.moderator ||
      this == HubRole.veteran;

  /// ✅ NEW: Can record game results (Gap Analysis #1)
  /// Veterans can start game recording alongside Managers
  bool canRecordGame() =>
      this == HubRole.manager ||
      this == HubRole.moderator ||
      this == HubRole.veteran;

  bool canEditHubInfo() => this == HubRole.manager;
  bool canDeletePosts() => this == HubRole.manager || this == HubRole.moderator;
  bool canDeleteComments() =>
      this == HubRole.manager || this == HubRole.moderator;
}
