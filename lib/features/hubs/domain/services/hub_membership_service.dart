import 'package:kattrick/features/hubs/data/repositories/hubs_repository.dart';
import 'package:kattrick/data/users_repository.dart';
import 'package:kattrick/services/push_notification_service.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/models/hub_member.dart';

/// Domain service for hub membership operations
///
/// Orchestrates membership logic with proper business validation.
/// Repository methods handle only atomic data operations.
///
/// This service enforces business rules:
/// - Hub capacity limits (max 50 members by default)
/// - User hub limits (max 10 hubs per user)
/// - Ban status checks
/// - Notification subscriptions
class HubMembershipService {
  final HubsRepository _hubsRepo;
  final UsersRepository _usersRepo;
  final PushNotificationService _notificationService;

  HubMembershipService({
    required HubsRepository hubsRepo,
    required UsersRepository usersRepo,
    required PushNotificationService notificationService,
  })  : _hubsRepo = hubsRepo,
        _usersRepo = usersRepo,
        _notificationService = notificationService;

  /// Add member to hub with business validation
  ///
  /// Validates:
  /// - Hub exists and has capacity
  /// - User exists and under hub limit
  /// - User not banned
  ///
  /// Throws:
  /// - [HubMembershipException] if hub or user not found
  /// - [HubCapacityExceededException] if hub full
  /// - [UserHubLimitException] if user at max hubs (10)
  /// - [HubMemberBannedException] if user banned
  Future<void> addMember({
    required String hubId,
    required String userId,
  }) async {
    // VALIDATION: Check hub exists and has space
    final hub = await _hubsRepo.getHub(hubId);
    if (hub == null) {
      throw HubMembershipException('Hub not found');
    }

    if (hub.isFull) {
      throw HubCapacityExceededException(
        'Hub is full (max ${hub.settings.maxMembers} members)',
        currentCount: hub.memberCount,
        maxCount: hub.settings.maxMembers,
      );
    }

    // VALIDATION: Check user exists and under limit
    final user = await _usersRepo.getUser(userId);
    if (user == null) {
      throw HubMembershipException('User not found');
    }

    if (user.hubIds.length >= 10) {
      throw UserHubLimitException(
        'User has joined maximum hubs (10)',
        currentCount: user.hubIds.length,
      );
    }

    // VALIDATION: Check not banned
    final membership = await _hubsRepo.getMembership(hubId, userId);
    if (membership?.status == HubMemberStatus.banned) {
      throw HubMemberBannedException('You are banned from this hub');
    }

    // ORCHESTRATION: Delegate atomic operation to repository
    await _hubsRepo.addMember(hubId, userId);

    // ORCHESTRATION: Subscribe to notifications
    await _notificationService.subscribeToHubTopic(hubId);
  }

  /// Remove member from hub
  ///
  /// Validates:
  /// - Hub exists
  /// - Unsubscribes from notifications
  ///
  /// Throws:
  /// - [HubMembershipException] if hub not found
  Future<void> removeMember({
    required String hubId,
    required String userId,
  }) async {
    // VALIDATION: Check hub exists
    final hub = await _hubsRepo.getHub(hubId);
    if (hub == null) {
      throw HubMembershipException('Hub not found');
    }

    // ORCHESTRATION: Remove member
    await _hubsRepo.removeMember(hubId, userId);

    // ORCHESTRATION: Unsubscribe from notifications
    await _notificationService.unsubscribeFromHubTopic(hubId);
  }

  /// Ban member from hub
  ///
  /// Validates:
  /// - Requesting user has manager permissions
  /// - Cannot ban hub creator
  ///
  /// Throws:
  /// - [InsufficientPermissionsException] if not manager
  /// - [HubMembershipException] if trying to ban creator
  Future<void> banMember({
    required String hubId,
    required String userId,
    required String reason,
    required String bannedBy,
  }) async {
    // VALIDATION: Check permissions
    final hub = await _hubsRepo.getHub(hubId);
    if (hub == null) {
      throw HubMembershipException('Hub not found');
    }

    if (!hub.isManager(bannedBy)) {
      throw InsufficientPermissionsException('Only managers can ban members');
    }

    // VALIDATION: Cannot ban hub creator
    if (hub.isCreator(userId)) {
      throw HubMembershipException('Cannot ban hub creator');
    }

    // ORCHESTRATION: Ban member (repository signature: hubId, uid, reason, bannedBy)
    await _hubsRepo.banMember(hubId, userId, reason, bannedBy);

    // ORCHESTRATION: Unsubscribe from notifications
    await _notificationService.unsubscribeFromHubTopic(hubId);
  }

  /// Update member role
  ///
  /// Validates:
  /// - Requesting user has manager permissions
  /// - Cannot demote hub creator
  ///
  /// Throws:
  /// - [InsufficientPermissionsException] if not manager
  /// - [HubMembershipException] if trying to change creator role
  Future<void> updateMemberRole({
    required String hubId,
    required String userId,
    required HubMemberRole newRole,
    required String updatedBy,
  }) async {
    // VALIDATION: Check permissions
    final hub = await _hubsRepo.getHub(hubId);
    if (hub == null) {
      throw HubMembershipException('Hub not found');
    }

    if (!hub.isManager(updatedBy)) {
      throw InsufficientPermissionsException('Only managers can change member roles');
    }

    // VALIDATION: Cannot change creator role
    if (hub.isCreator(userId)) {
      throw HubMembershipException('Cannot change hub creator role');
    }

    // ORCHESTRATION: Update role (repository signature: hubId, uid, role as String, updatedBy)
    await _hubsRepo.updateMemberRole(hubId, userId, newRole.name, updatedBy);
  }
}

// ============================================================================
// CUSTOM EXCEPTIONS
// ============================================================================

/// Base exception for hub membership operations
class HubMembershipException implements Exception {
  final String message;

  HubMembershipException(this.message);

  @override
  String toString() => message;
}

/// Hub has reached maximum member capacity
class HubCapacityExceededException extends HubMembershipException {
  final int currentCount;
  final int maxCount;

  HubCapacityExceededException(
    super.message, {
    required this.currentCount,
    required this.maxCount,
  });
}

/// User has reached maximum hub membership limit (10)
class UserHubLimitException extends HubMembershipException {
  final int currentCount;

  UserHubLimitException(
    super.message, {
    required this.currentCount,
  });
}

/// User is banned from the hub
class HubMemberBannedException extends HubMembershipException {
  HubMemberBannedException(super.message);
}

/// User lacks required permissions for operation
class InsufficientPermissionsException extends HubMembershipException {
  InsufficientPermissionsException(super.message);
}
