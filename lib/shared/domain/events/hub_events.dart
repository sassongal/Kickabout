import 'package:kattrick/shared/domain/events/domain_event.dart';

/// Event fired when a new member is added to a hub
class HubMemberAddedEvent extends DomainEvent {
  /// The ID of the hub
  final String hubId;

  /// The ID of the user who was added as a member
  final String userId;

  /// The role assigned to the new member
  final String? role;

  HubMemberAddedEvent({
    required this.hubId,
    required this.userId,
    this.role,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubMemberAddedEvent(hubId: $hubId, userId: $userId, role: $role, eventId: $eventId)';
  }
}

/// Event fired when a member is removed from a hub
class HubMemberRemovedEvent extends DomainEvent {
  /// The ID of the hub
  final String hubId;

  /// The ID of the user who was removed
  final String userId;

  /// Reason for removal (optional)
  final String? reason;

  HubMemberRemovedEvent({
    required this.hubId,
    required this.userId,
    this.reason,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubMemberRemovedEvent(hubId: $hubId, userId: $userId, reason: $reason, eventId: $eventId)';
  }
}

/// Event fired when a hub member's role is updated
class HubMemberRoleUpdatedEvent extends DomainEvent {
  /// The ID of the hub
  final String hubId;

  /// The ID of the user whose role was updated
  final String userId;

  /// The old role
  final String oldRole;

  /// The new role
  final String newRole;

  HubMemberRoleUpdatedEvent({
    required this.hubId,
    required this.userId,
    required this.oldRole,
    required this.newRole,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubMemberRoleUpdatedEvent(hubId: $hubId, userId: $userId, $oldRole -> $newRole, eventId: $eventId)';
  }
}

/// Event fired when a new hub is created
class HubCreatedEvent extends DomainEvent {
  /// The ID of the created hub
  final String hubId;

  /// The ID of the user who created the hub
  final String createdBy;

  /// The hub name
  final String hubName;

  HubCreatedEvent({
    required this.hubId,
    required this.createdBy,
    required this.hubName,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubCreatedEvent(hubId: $hubId, hubName: $hubName, createdBy: $createdBy, eventId: $eventId)';
  }
}

/// Event fired when hub settings are updated
class HubSettingsUpdatedEvent extends DomainEvent {
  /// The ID of the hub
  final String hubId;

  /// The ID of the user who updated the settings
  final String updatedBy;

  /// Description of what was updated (optional)
  final String? updateDescription;

  HubSettingsUpdatedEvent({
    required this.hubId,
    required this.updatedBy,
    this.updateDescription,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubSettingsUpdatedEvent(hubId: $hubId, updatedBy: $updatedBy, eventId: $eventId)';
  }
}

/// Event fired when a hub event (tournament/league) is created
class HubEventCreatedEvent extends DomainEvent {
  /// The ID of the hub
  final String hubId;

  /// The ID of the created hub event
  final String hubEventId;

  /// The ID of the user who created the event
  final String createdBy;

  /// The event name
  final String eventName;

  HubEventCreatedEvent({
    required this.hubId,
    required this.hubEventId,
    required this.createdBy,
    required this.eventName,
    DateTime? timestamp,
    String? eventId,
  }) : super(timestamp: timestamp, eventId: eventId);

  @override
  String toString() {
    return 'HubEventCreatedEvent(hubId: $hubId, hubEventId: $hubEventId, eventName: $eventName, eventId: $eventId)';
  }
}
