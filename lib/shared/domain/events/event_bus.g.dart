// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_bus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventBusHash() => r'cb546a1b422bd1713e34b5fc8d4aca87658e34e5';

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
///
/// Copied from [eventBus].
@ProviderFor(eventBus)
final eventBusProvider = AutoDisposeProvider<EventBus>.internal(
  eventBus,
  name: r'eventBusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$eventBusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EventBusRef = AutoDisposeProviderRef<EventBus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
