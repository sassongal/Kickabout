import 'package:kickadoor/models/models.dart';

/// Simple user role enum for permission checks
enum UserRole {
  admin,
  member,
  none;

  /// Check if user has admin permissions
  bool get isAdmin => this == UserRole.admin;

  /// Check if user is a member
  bool get isMember => this == UserRole.member || this == UserRole.admin;
}

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

  /// Check if role has permission to perform action
  ///
  /// Permission Matrix:
  /// - Manager: Full access to everything
  /// - Moderator: Can manage members, create games/events, moderate content
  /// - Veteran: Can create games, view analytics (future), invite players (future)
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
  bool canEditHubInfo() => this == HubRole.manager;
  bool canDeletePosts() => this == HubRole.manager || this == HubRole.moderator;
  bool canDeleteComments() =>
      this == HubRole.manager || this == HubRole.moderator;
}

/// Helper class for hub permissions
class HubPermissions {
  final Hub hub;
  final String userId;

  HubPermissions({required this.hub, required this.userId});

  /// Get the user's role in the hub
  /// Priority: Manager (creator) > Explicit role > Veteran (if >2 months) > Member > Guest
  HubRole get userRole {
    // Creator is always manager
    if (userId == hub.createdBy) return HubRole.manager;

    // Check explicit roles map (assigned by manager)
    final roleString = hub.roles[userId];
    if (roleString != null) {
      final explicitRole = HubRole.fromFirestore(roleString);
      // If explicitly set to moderator, return moderator (not veteran)
      if (explicitRole == HubRole.moderator) return HubRole.moderator;
      // If explicitly set to member, check if veteran
      if (explicitRole == HubRole.member) {
        return _isVeteranPlayer() ? HubRole.veteran : HubRole.member;
      }
      return explicitRole;
    }

    // Check if member
    if (hub.memberIds.contains(userId)) {
      // Check if veteran (in hub for more than 2 months)
      return _isVeteranPlayer() ? HubRole.veteran : HubRole.member;
    }

    // Not a member
    return HubRole.guest;
  }

  /// Check if user is a veteran player (in hub for more than 2 months)
  bool _isVeteranPlayer() {
    if (!hub.memberIds.contains(userId)) return false;

    // Get join date from memberJoinDates
    final joinDateTimestamp = hub.memberJoinDates[userId];
    if (joinDateTimestamp == null) {
      // If no join date recorded, use hub creation date as fallback
      // This handles legacy data where join dates weren't tracked
      final daysSinceHubCreation =
          DateTime.now().difference(hub.createdAt).inDays;
      return daysSinceHubCreation >= 60; // 2 months = ~60 days
    }

    // Convert Timestamp to DateTime
    final joinDate = joinDateTimestamp.toDate();

    // Check if more than 2 months (60 days)
    final daysSinceJoin = DateTime.now().difference(joinDate).inDays;
    return daysSinceJoin >= 60;
  }

  /// Check if user is a veteran player (public method)
  bool isVeteranPlayer() => _isVeteranPlayer();

  /// Get the date when user joined the hub
  DateTime? getJoinDate() {
    final joinDateTimestamp = hub.memberJoinDates[userId];
    if (joinDateTimestamp == null) return null;
    return joinDateTimestamp.toDate();
  }

  /// Get days since joining the hub
  int? getDaysSinceJoin() {
    final joinDate = getJoinDate();
    if (joinDate == null) return null;
    return DateTime.now().difference(joinDate).inDays;
  }

  // Permission methods
  bool canManageMembers() => userRole.canManageMembers();
  bool canManageRoles() => userRole.canManageRoles();
  bool canManageSettings() => userRole.canManageSettings();
  bool canDeleteHub() => userRole.canDeleteHub();
  bool canCreateGames() => userRole.canCreateGames();

  /// Check if user can create events
  /// Checks: 1) Default role permissions, 2) Custom permissions set by manager
  bool canCreateEvents() {
    // First check default role permissions
    if (userRole.canCreateEvents()) return true;

    // Then check custom permissions (set by manager)
    final canCreateEventsList = hub.permissions['canCreateEvents'] as List?;
    if (canCreateEventsList != null && canCreateEventsList.contains(userId)) {
      return true;
    }

    return false;
  }

  /// Check if user can create posts
  /// Checks: 1) Default role permissions (all members can), 2) Custom permissions set by manager
  bool canCreatePosts() {
    // Guest cannot post
    if (userRole == HubRole.guest) return false;

    // All hub members can create posts by default
    if (isMember()) return true;

    // Check custom permissions (if manager restricted posting)
    final canCreatePostsList = hub.permissions['canCreatePosts'] as List?;
    if (canCreatePostsList != null) {
      // If list exists, only users in the list can post
      return canCreatePostsList.contains(userId);
    }

    // Default: all members can post
    return isMember();
  }

  bool canModerateContent() => userRole.canModerateContent();
  bool canInvitePlayers() => userRole.canInvitePlayers();
  bool canViewAnalytics() => userRole.canViewAnalytics();
  bool canEditHubInfo() => userRole.canEditHubInfo();
  bool canDeletePosts() => userRole.canDeletePosts();
  bool canDeleteComments() => userRole.canDeleteComments();

  // Role check methods
  bool isManager() => userRole == HubRole.manager;
  bool isModerator() =>
      userRole == HubRole.moderator || userRole == HubRole.manager;
  bool isVeteran() => userRole == HubRole.veteran;
  bool isMember() => hub.memberIds.contains(userId);

  /// Get role display name
  String getRoleDisplayName() => userRole.displayName;
}
