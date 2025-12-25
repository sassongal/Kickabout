// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_past_game_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$logPastGameNotifierHash() =>
    r'76e16270787a6d4ed8d0c9add2125d5f68497b8c';

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

abstract class _$LogPastGameNotifier
    extends BuildlessAutoDisposeNotifier<LogPastGameState> {
  late final String hubId;

  LogPastGameState build(
    String hubId,
  );
}

/// Notifier for managing log past game screen state
///
/// Copied from [LogPastGameNotifier].
@ProviderFor(LogPastGameNotifier)
const logPastGameNotifierProvider = LogPastGameNotifierFamily();

/// Notifier for managing log past game screen state
///
/// Copied from [LogPastGameNotifier].
class LogPastGameNotifierFamily extends Family<LogPastGameState> {
  /// Notifier for managing log past game screen state
  ///
  /// Copied from [LogPastGameNotifier].
  const LogPastGameNotifierFamily();

  /// Notifier for managing log past game screen state
  ///
  /// Copied from [LogPastGameNotifier].
  LogPastGameNotifierProvider call(
    String hubId,
  ) {
    return LogPastGameNotifierProvider(
      hubId,
    );
  }

  @override
  LogPastGameNotifierProvider getProviderOverride(
    covariant LogPastGameNotifierProvider provider,
  ) {
    return call(
      provider.hubId,
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
  String? get name => r'logPastGameNotifierProvider';
}

/// Notifier for managing log past game screen state
///
/// Copied from [LogPastGameNotifier].
class LogPastGameNotifierProvider extends AutoDisposeNotifierProviderImpl<
    LogPastGameNotifier, LogPastGameState> {
  /// Notifier for managing log past game screen state
  ///
  /// Copied from [LogPastGameNotifier].
  LogPastGameNotifierProvider(
    String hubId,
  ) : this._internal(
          () => LogPastGameNotifier()..hubId = hubId,
          from: logPastGameNotifierProvider,
          name: r'logPastGameNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$logPastGameNotifierHash,
          dependencies: LogPastGameNotifierFamily._dependencies,
          allTransitiveDependencies:
              LogPastGameNotifierFamily._allTransitiveDependencies,
          hubId: hubId,
        );

  LogPastGameNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.hubId,
  }) : super.internal();

  final String hubId;

  @override
  LogPastGameState runNotifierBuild(
    covariant LogPastGameNotifier notifier,
  ) {
    return notifier.build(
      hubId,
    );
  }

  @override
  Override overrideWith(LogPastGameNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LogPastGameNotifierProvider._internal(
        () => create()..hubId = hubId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        hubId: hubId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<LogPastGameNotifier, LogPastGameState>
      createElement() {
    return _LogPastGameNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LogPastGameNotifierProvider && other.hubId == hubId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, hubId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LogPastGameNotifierRef
    on AutoDisposeNotifierProviderRef<LogPastGameState> {
  /// The parameter `hubId` of this provider.
  String get hubId;
}

class _LogPastGameNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<LogPastGameNotifier,
        LogPastGameState> with LogPastGameNotifierRef {
  _LogPastGameNotifierProviderElement(super.provider);

  @override
  String get hubId => (origin as LogPastGameNotifierProvider).hubId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
