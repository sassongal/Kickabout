import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'entity_id.freezed.dart';
part 'entity_id.g.dart';

/// Base class for all typed entity IDs
///
/// Prevents primitive obsession by creating type-safe wrappers around string IDs.
/// Eliminates entire classes of bugs where IDs are accidentally swapped.
///
/// Example:
/// ```dart
/// void addPlayer(GameId gameId, UserId userId) {
///   // Compiler enforces correct parameter order
/// }
/// ```
abstract class EntityId {
  String get value;

  /// Check if this ID is valid (non-empty)
  bool get isValid => value.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityId &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

// ============================================================================
// TYPED ID IMPLEMENTATIONS
// ============================================================================

/// Hub identifier
@freezed
class HubId with _$HubId implements EntityId {
  const factory HubId(String value) = _HubId;
  const HubId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory HubId.fromJson(Map<String, dynamic> json) => _$HubIdFromJson(json);

  /// Generate a new unique hub ID
  factory HubId.generate() => HubId(const Uuid().v4());

  /// Create from string value
  factory HubId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('HubId cannot be empty');
    }
    return HubId(value);
  }
}

/// Game identifier
@freezed
class GameId with _$GameId implements EntityId {
  const factory GameId(String value) = _GameId;
  const GameId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory GameId.fromJson(Map<String, dynamic> json) => _$GameIdFromJson(json);

  /// Generate a new unique game ID
  factory GameId.generate() => GameId(const Uuid().v4());

  /// Create from string value
  factory GameId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('GameId cannot be empty');
    }
    return GameId(value);
  }
}

/// User identifier
@freezed
class UserId with _$UserId implements EntityId {
  const factory UserId(String value) = _UserId;
  const UserId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory UserId.fromJson(Map<String, dynamic> json) => _$UserIdFromJson(json);

  /// Create from Firebase Auth UID
  factory UserId.fromAuthUid(String uid) {
    if (uid.isEmpty) {
      throw ArgumentError('UserId cannot be empty');
    }
    return UserId(uid);
  }

  /// Create from string value
  factory UserId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('UserId cannot be empty');
    }
    return UserId(value);
  }
}

/// Event identifier
@freezed
class EventId with _$EventId implements EntityId {
  const factory EventId(String value) = _EventId;
  const EventId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory EventId.fromJson(Map<String, dynamic> json) =>
      _$EventIdFromJson(json);

  /// Generate a new unique event ID
  factory EventId.generate() => EventId(const Uuid().v4());

  /// Create from string value
  factory EventId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('EventId cannot be empty');
    }
    return EventId(value);
  }
}

/// Venue identifier
@freezed
class VenueId with _$VenueId implements EntityId {
  const factory VenueId(String value) = _VenueId;
  const VenueId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory VenueId.fromJson(Map<String, dynamic> json) =>
      _$VenueIdFromJson(json);

  /// Generate a new unique venue ID
  factory VenueId.generate() => VenueId(const Uuid().v4());

  /// Create from string value
  factory VenueId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('VenueId cannot be empty');
    }
    return VenueId(value);
  }
}

/// Post identifier (for social feed posts)
@freezed
class PostId with _$PostId implements EntityId {
  const factory PostId(String value) = _PostId;
  const PostId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory PostId.fromJson(Map<String, dynamic> json) => _$PostIdFromJson(json);

  /// Generate a new unique post ID
  factory PostId.generate() => PostId(const Uuid().v4());

  /// Create from string value
  factory PostId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('PostId cannot be empty');
    }
    return PostId(value);
  }
}

/// Comment identifier
@freezed
class CommentId with _$CommentId implements EntityId {
  const factory CommentId(String value) = _CommentId;
  const CommentId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory CommentId.fromJson(Map<String, dynamic> json) =>
      _$CommentIdFromJson(json);

  /// Generate a new unique comment ID
  factory CommentId.generate() => CommentId(const Uuid().v4());

  /// Create from string value
  factory CommentId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('CommentId cannot be empty');
    }
    return CommentId(value);
  }
}

/// Notification identifier
@freezed
class NotificationId with _$NotificationId implements EntityId {
  const factory NotificationId(String value) = _NotificationId;
  const NotificationId._();

  @override
  bool get isValid => value.isNotEmpty;

  factory NotificationId.fromJson(Map<String, dynamic> json) =>
      _$NotificationIdFromJson(json);

  /// Generate a new unique notification ID
  factory NotificationId.generate() => NotificationId(const Uuid().v4());

  /// Create from string value
  factory NotificationId.fromString(String value) {
    if (value.isEmpty) {
      throw ArgumentError('NotificationId cannot be empty');
    }
    return NotificationId(value);
  }
}
