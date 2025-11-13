import 'package:kickadoor/models/models.dart';

/// Hub role enum
enum HubRole {
  manager,
  moderator,
  member;

  String get displayName {
    switch (this) {
      case HubRole.manager:
        return 'מנהל';
      case HubRole.moderator:
        return 'מנחה';
      case HubRole.member:
        return 'חבר';
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
    }
  }

  static HubRole fromFirestore(String value) {
    switch (value) {
      case 'manager':
        return HubRole.manager;
      case 'moderator':
        return HubRole.moderator;
      case 'member':
      default:
        return HubRole.member;
    }
  }

  /// Check if role has permission to perform action
  bool canManageMembers() => this == HubRole.manager || this == HubRole.moderator;
  bool canManageRoles() => this == HubRole.manager;
  bool canManageSettings() => this == HubRole.manager;
  bool canDeleteHub() => this == HubRole.manager;
  bool canCreateGames() => this == HubRole.manager || this == HubRole.moderator || this == HubRole.member;
  bool canModerateContent() => this == HubRole.manager || this == HubRole.moderator;
}

/// Helper class for hub permissions
class HubPermissions {
  final Hub hub;
  final String userId;

  HubPermissions({required this.hub, required this.userId});

  HubRole get userRole {
    // Creator is always manager
    if (userId == hub.createdBy) return HubRole.manager;
    
    // Check roles map
    final roleString = hub.roles[userId];
    if (roleString != null) {
      return HubRole.fromFirestore(roleString);
    }
    
    // Default to member if in memberIds
    if (hub.memberIds.contains(userId)) {
      return HubRole.member;
    }
    
    // Not a member
    throw Exception('User is not a member of this hub');
  }

  bool canManageMembers() => userRole.canManageMembers();
  bool canManageRoles() => userRole.canManageRoles();
  bool canManageSettings() => userRole.canManageSettings();
  bool canDeleteHub() => userRole.canDeleteHub();
  bool canCreateGames() => userRole.canCreateGames();
  bool canModerateContent() => userRole.canModerateContent();
  bool isManager() => userRole == HubRole.manager;
  bool isModerator() => userRole == HubRole.moderator || userRole == HubRole.manager;
  bool isMember() => hub.memberIds.contains(userId);
}
