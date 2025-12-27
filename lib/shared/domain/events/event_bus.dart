import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kattrick/shared/domain/events/domain_event.dart';

part 'event_bus.g.dart';

/// Provider for the global event bus
///
/// Usage:
/// ```dart
/// // Fire an event
/// ref.read(eventBusProvider).fire(GameCreatedEvent(gameId: '123'));
///
/// // Listen to events
/// ref.read(eventBusProvider).on<GameCreatedEvent>().listen((event) {
///   print('Game created: ${event.gameId}');
/// });
/// ```
@riverpod
EventBus eventBus(Ref ref) {
  final bus = EventBus();

  // Dispose the event bus when the provider is disposed
  ref.onDispose(() {
    bus.dispose();
  });

  return bus;
}

/// Event bus for domain events.
///
/// This provides a publish-subscribe mechanism for domain events, allowing
/// different parts of the application to react to domain changes without
/// tight coupling.
///
/// The event bus uses broadcast streams, so multiple listeners can subscribe
/// to the same event type.
class EventBus {
  final StreamController<DomainEvent> _controller =
      StreamController<DomainEvent>.broadcast();

  /// Subscribe to events of a specific type.
  ///
  /// Returns a stream that only emits events of type [T].
  ///
  /// Example:
  /// ```dart
  /// eventBus.on<GameCreatedEvent>().listen((event) {
  ///   print('Game ${event.gameId} was created');
  /// });
  /// ```
  Stream<T> on<T extends DomainEvent>() {
    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// Fire a domain event.
  ///
  /// All subscribers to this event type will be notified.
  ///
  /// Example:
  /// ```dart
  /// eventBus.fire(GameCreatedEvent(gameId: '123', hubId: '456'));
  /// ```
  void fire(DomainEvent event) {
    if (_controller.isClosed) {
      throw StateError('Cannot fire events on a closed EventBus');
    }
    _controller.add(event);
  }

  /// Dispose of the event bus and close all streams.
  ///
  /// After calling dispose, no more events can be fired.
  void dispose() {
    if (!_controller.isClosed) {
      _controller.close();
    }
  }

  /// Check if the event bus is closed
  bool get isClosed => _controller.isClosed;
}
