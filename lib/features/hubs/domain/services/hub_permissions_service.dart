/// SINGLE SOURCE OF TRUTH for all hub permissions
/// Used by both Flutter client and mirrored in Firestore rules
///
/// This service eliminates the previous fragmented permission logic that was
/// spread across HubRole, HubPermissions, Firestore rules, and UI widgets.
///
/// Key Principles:
/// - Permissions derive ONLY from HubMember.role (server-managed)
/// - NO client-side DateTime.now() checks
/// - Hub creator is ALWAYS manager
/// - Custom permissions via Hub.permissions are rare overrides only
library;

import 'package:kattrick/models/hub_member.dart';
import 'package:kattrick/models/hub.dart';
import 'package:kattrick/models/hub_role.dart';
import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';

/// Permission capabilities mapped to roles
///
/// PERMISSION MATRIX:
/// | Capability         | Manager | Moderator | Veteran | Member | Guest |
/// |--------------------|---------|-----------|---------|--------|-------|
/// | Create games       |    ✅   |     ✅    |    ✅   |   ✅   |  ❌   |
/// | Create events      |    ✅   |     ✅    |    ❌   |   ❌   |  ❌   |
/// | Record results     |    ✅   |     ✅    |    ✅   |   ❌   |  ❌   |
/// | Invite players     |    ✅   |     ✅    |    ✅   |   ❌   |  ❌   |
/// | View analytics     |    ✅   |     ✅    |    ✅   |   ❌   |  ❌   |
/// | Send chat          |    ✅   |     ✅    |    ✅   |   ✅   |  ❌   |
/// | Moderate chat      |    ✅   |     ✅    |    ❌   |   ❌   |  ❌   |
/// | Manage members     |    ✅   |     ✅    |    ❌   |   ❌   |  ❌   |
/// | Manage roles       |    ✅   |     ❌    |    ❌   |   ❌   |  ❌   |
/// | Manage settings    |    ✅   |     ❌    |    ❌   |   ❌   |  ❌   |
extension HubMemberRolePermissions on HubMemberRole {
  // Core game/event permissions
  bool get canCreateGames => true; // All roles can create games

  bool get canCreateEvents =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  bool get canRecordResults =>
      this == HubMemberRole.manager ||
      this == HubMemberRole.moderator ||
      this == HubMemberRole.veteran;

  bool get canInvitePlayers =>
      this == HubMemberRole.manager ||
      this == HubMemberRole.moderator ||
      this == HubMemberRole.veteran;

  bool get canViewAnalytics =>
      this == HubMemberRole.manager ||
      this == HubMemberRole.moderator ||
      this == HubMemberRole.veteran;

  // Communication permissions
  bool get canSendChatMessages => true; // All roles can chat

  bool get canModerateChat =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  bool get canCreatePosts => true; // All roles can post

  bool get canDeletePosts =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  // Member management permissions
  bool get canManageMembers =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  bool get canManageRoles => this == HubMemberRole.manager;

  bool get canBanMembers =>
      this == HubMemberRole.manager || this == HubMemberRole.moderator;

  // Hub management permissions
  bool get canEditHubInfo => this == HubMemberRole.manager;

  bool get canManageSettings => this == HubMemberRole.manager;

  bool get canDeleteHub => this == HubMemberRole.manager;

  bool get canManageVenues => this == HubMemberRole.manager;

  // Helper: Check if this role meets minimum requirement
  bool meetsMinimum(HubMemberRole minimum) {
    return isAtLeast(minimum);
  }
}

/// Unified permission checker for a user in a hub
///
/// Usage:
/// ```dart
/// final permissions = HubPermissions(
///   hub: hub,
///   membership: membership, // can be null for guests
///   userId: currentUserId,
/// );
///
/// if (permissions.canCreateGames) {
///   // Show create game button
/// }
/// ```
class HubPermissions {
  final Hub hub;
  final HubMember? membership;
  final String userId;

  HubPermissions({
    required this.hub,
    required this.userId,
    this.membership,
  });

  /// Determine effective role (including creator check)
  ///
  /// Priority:
  /// 1. Hub creator is ALWAYS manager
  /// 2. Membership.role (if active)
  /// 3. Guest (no membership or inactive)
  HubMemberRole get effectiveRole {
    // Creator is ALWAYS manager, even without membership doc
    if (userId == hub.createdBy) {
      return HubMemberRole.manager;
    }

    // Check membership
    if (membership == null || membership!.status != HubMemberStatus.active) {
      // No active membership = guest (no permissions)
      // Note: We use a "guest" concept even though it's not in the enum
      // Guests get no permissions, represented by returning member but
      // checking isActive separately
      return HubMemberRole.member; // Will be blocked by isActive check
    }

    return membership!.role;
  }

  /// Is user currently an active member?
  bool get isActive {
    if (userId == hub.createdBy) return true; // Creator always active
    return membership?.isActive ?? false;
  }

  // Core permission getters - delegate to role extension with active check
  bool get canCreateGames => isActive && effectiveRole.canCreateGames;

  bool get canCreateEvents =>
      isActive &&
      (effectiveRole.canCreateEvents ||
          _hasCustomPermission('canCreateEvents'));

  bool get canRecordResults => isActive && effectiveRole.canRecordResults;

  bool get canInvitePlayers => isActive && effectiveRole.canInvitePlayers;

  bool get canViewAnalytics => isActive && effectiveRole.canViewAnalytics;

  bool get canSendChatMessages => isActive && effectiveRole.canSendChatMessages;

  bool get canModerateChat => isActive && effectiveRole.canModerateChat;

  bool get canCreatePosts =>
      isActive &&
      (effectiveRole.canCreatePosts || _hasCustomPermission('canCreatePosts'));

  bool get canDeletePosts => isActive && effectiveRole.canDeletePosts;

  bool get canManageMembers => isActive && effectiveRole.canManageMembers;

  bool get canManageRoles => isActive && effectiveRole.canManageRoles;

  bool get canBanMembers => isActive && effectiveRole.canBanMembers;

  bool get canEditHubInfo => isActive && effectiveRole.canEditHubInfo;

  bool get canManageSettings => isActive && effectiveRole.canManageSettings;

  bool get canDeleteHub => isActive && effectiveRole.canDeleteHub;

  bool get canManageVenues => isActive && effectiveRole.canManageVenues;

  // Helper: Check custom permission overrides (rare)
  bool _hasCustomPermission(String permission) {
    final customPerms = hub.permissions[permission] as List?;
    return customPerms?.contains(userId) ?? false;
  }

  // Convenience role checks
  bool get isManager => effectiveRole == HubMemberRole.manager && isActive;
  bool get isModerator => effectiveRole == HubMemberRole.moderator && isActive;
  bool get isVeteran => membership?.isVeteran ?? false;
  bool get isMember => isActive;
  bool get isGuest => !isActive;

  String get roleDisplayName => effectiveRole.displayName;

  /// @deprecated Use effectiveRole instead. This backward compatibility shim will be removed.
  /// Backward compatibility: Map HubMemberRole to HubRole
  /// This allows existing UI code that uses HubRole to continue working
  HubRole get userRole {
    if (!isActive) return HubRole.guest;

    switch (effectiveRole) {
      case HubMemberRole.manager:
        return HubRole.manager;
      case HubMemberRole.moderator:
        return HubRole.moderator;
      case HubMemberRole.veteran:
        return HubRole.veteran;
      case HubMemberRole.member:
        return HubRole.member;
    }
  }

  /// Detailed permission info for debugging
  Map<String, dynamic> toDebugInfo() {
    return {
      'userId': userId,
      'hubId': hub.hubId,
      'effectiveRole': effectiveRole.name,
      'isActive': isActive,
      'isCreator': userId == hub.createdBy,
      'membershipStatus': membership?.status.name,
      'isVeteran': isVeteran,
      'veteranSince': membership?.veteranSince?.toIso8601String(),
    };
  }
}

/// Service for managing hub permissions (business logic)
///
/// This service encapsulates permission business logic and uses HubsRepository
/// for data access. It should be placed in the domain layer.
class HubPermissionsService {
  final HubsRepository _hubsRepo;

  HubPermissionsService({HubsRepository? hubsRepo})
      : _hubsRepo = hubsRepo ?? HubsRepository();

  /// Stream membership for a user in a hub (delegates to repository)
  Stream<HubMember?> watchMembership(String hubId, String userId) {
    return _hubsRepo.watchMembership(hubId, userId);
  }

  /// Get membership once (delegates to repository)
  Future<HubMember?> getMembership(String hubId, String userId) async {
    return _hubsRepo.getMembership(hubId, userId);
  }

  /// Get permissions for a user in a hub (business logic)
  Future<HubPermissions> getPermissions(
    Hub hub,
    String userId,
  ) async {
    final membership = await getMembership(hub.hubId, userId);
    return HubPermissions(
      hub: hub,
      membership: membership,
      userId: userId,
    );
  }

  /// Create permissions object from existing membership (business logic)
  HubPermissions createPermissions(
    Hub hub,
    HubMember? membership,
    String userId,
  ) {
    return HubPermissions(
      hub: hub,
      membership: membership,
      userId: userId,
    );
  }
}

