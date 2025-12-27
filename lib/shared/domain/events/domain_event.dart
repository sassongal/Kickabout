import 'package:uuid/uuid.dart';

/// Base class for all domain events in the system.
///
/// Domain events represent something that happened in the domain that other
/// parts of the system might be interested in. They enable loose coupling
/// between features by allowing features to react to events without direct
/// dependencies.
///
/// Example:
/// ```dart
/// class GameCreatedEvent extends DomainEvent {
///   final String gameId;
///   GameCreatedEvent({required this.gameId});
/// }
/// ```
abstract class DomainEvent {
  /// When this event occurred
  final DateTime timestamp;

  /// Unique identifier for this event instance
  final String eventId;

  DomainEvent({
    DateTime? timestamp,
    String? eventId,
  })  : timestamp = timestamp ?? DateTime.now(),
        eventId = eventId ?? _generateEventId();

  /// Generate a unique event ID
  static String _generateEventId() {
    return const Uuid().v4();
  }

  @override
  String toString() {
    return '$runtimeType(eventId: $eventId, timestamp: $timestamp)';
  }
}
