// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_game_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$logGameNotifierHash() => r'a2fa76c5035c0b329b0a14b11690663baa888192';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$LogGameNotifier
    extends BuildlessAutoDisposeNotifier<LogGameState> {
  late final String hubId;
  late final String eventId;

  LogGameState build(
    String hubId,
    String eventId,
  );
}

/// Notifier for managing log game screen state
///
/// Copied from [LogGameNotifier].
@ProviderFor(LogGameNotifier)
const logGameNotifierProvider = LogGameNotifierFamily();

/// Notifier for managing log game screen state
///
/// Copied from [LogGameNotifier].
class LogGameNotifierFamily extends Family<LogGameState> {
  /// Notifier for managing log game screen state
  ///
  /// Copied from [LogGameNotifier].
  const LogGameNotifierFamily();

  /// Notifier for managing log game screen state
  ///
  /// Copied from [LogGameNotifier].
  LogGameNotifierProvider call(
    String hubId,
    String eventId,
  ) {
    return LogGameNotifierProvider(
      hubId,
      eventId,
    );
  }

  @override
  LogGameNotifierProvider getProviderOverride(
    covariant LogGameNotifierProvider provider,
  ) {
    return call(
      provider.hubId,
      provider.eventId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'logGameNotifierProvider';
}

/// Notifier for managing log game screen state
///
/// Copied from [LogGameNotifier].
class LogGameNotifierProvider
    extends AutoDisposeNotifierProviderImpl<LogGameNotifier, LogGameState> {
  /// Notifier for managing log game screen state
  ///
  /// Copied from [LogGameNotifier].
  LogGameNotifierProvider(
    String hubId,
    String eventId,
  ) : this._internal(
          () => LogGameNotifier()
            ..hubId = hubId
            ..eventId = eventId,
          from: logGameNotifierProvider,
          name: r'logGameNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$logGameNotifierHash,
          dependencies: LogGameNotifierFamily._dependencies,
          allTransitiveDependencies:
              LogGameNotifierFamily._allTransitiveDependencies,
          hubId: hubId,
          eventId: eventId,
        );

  LogGameNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hubId,
    required this.eventId,
  }) : super.internal();

  final String hubId;
  final String eventId;

  @override
  LogGameState runNotifierBuild(
    covariant LogGameNotifier notifier,
  ) {
    return notifier.build(
      hubId,
      eventId,
    );
  }

  @override
  Override overrideWith(LogGameNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LogGameNotifierProvider._internal(
        () => create()
          ..hubId = hubId
          ..eventId = eventId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hubId: hubId,
        eventId: eventId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<LogGameNotifier, LogGameState>
      createElement() {
    return _LogGameNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LogGameNotifierProvider &&
        other.hubId == hubId &&
        other.eventId == eventId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hubId.hashCode);
    hash = _SystemHash.combine(hash, eventId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LogGameNotifierRef on AutoDisposeNotifierProviderRef<LogGameState> {
  /// The parameter `hubId` of this provider.
  String get hubId;

  /// The parameter `eventId` of this provider.
  String get eventId;
}

class _LogGameNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<LogGameNotifier, LogGameState>
    with LogGameNotifierRef {
  _LogGameNotifierProviderElement(super.provider);

  @override
  String get hubId => (origin as LogGameNotifierProvider).hubId;
  @override
  String get eventId => (origin as LogGameNotifierProvider).eventId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
