// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_match_result_dialog_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$logMatchResultDialogNotifierHash() =>
    r'bde81546ce600c31c28ccc37c65ce5365c92ae02';

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

abstract class _$LogMatchResultDialogNotifier
    extends BuildlessAutoDisposeNotifier<LogMatchResultDialogState> {
  late final LogMatchResultDialogParams params;

  LogMatchResultDialogState build(
    LogMatchResultDialogParams params,
  );
}

/// Notifier for managing log match result dialog state
///
/// Copied from [LogMatchResultDialogNotifier].
@ProviderFor(LogMatchResultDialogNotifier)
const logMatchResultDialogNotifierProvider =
    LogMatchResultDialogNotifierFamily();

/// Notifier for managing log match result dialog state
///
/// Copied from [LogMatchResultDialogNotifier].
class LogMatchResultDialogNotifierFamily
    extends Family<LogMatchResultDialogState> {
  /// Notifier for managing log match result dialog state
  ///
  /// Copied from [LogMatchResultDialogNotifier].
  const LogMatchResultDialogNotifierFamily();

  /// Notifier for managing log match result dialog state
  ///
  /// Copied from [LogMatchResultDialogNotifier].
  LogMatchResultDialogNotifierProvider call(
    LogMatchResultDialogParams params,
  ) {
    return LogMatchResultDialogNotifierProvider(
      params,
    );
  }

  @override
  LogMatchResultDialogNotifierProvider getProviderOverride(
    covariant LogMatchResultDialogNotifierProvider provider,
  ) {
    return call(
      provider.params,
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
  String? get name => r'logMatchResultDialogNotifierProvider';
}

/// Notifier for managing log match result dialog state
///
/// Copied from [LogMatchResultDialogNotifier].
class LogMatchResultDialogNotifierProvider
    extends AutoDisposeNotifierProviderImpl<LogMatchResultDialogNotifier,
        LogMatchResultDialogState> {
  /// Notifier for managing log match result dialog state
  ///
  /// Copied from [LogMatchResultDialogNotifier].
  LogMatchResultDialogNotifierProvider(
    LogMatchResultDialogParams params,
  ) : this._internal(
          () => LogMatchResultDialogNotifier()..params = params,
          from: logMatchResultDialogNotifierProvider,
          name: r'logMatchResultDialogNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$logMatchResultDialogNotifierHash,
          dependencies: LogMatchResultDialogNotifierFamily._dependencies,
          allTransitiveDependencies:
              LogMatchResultDialogNotifierFamily._allTransitiveDependencies,
          params: params,
        );

  LogMatchResultDialogNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final LogMatchResultDialogParams params;

  @override
  LogMatchResultDialogState runNotifierBuild(
    covariant LogMatchResultDialogNotifier notifier,
  ) {
    return notifier.build(
      params,
    );
  }

  @override
  Override overrideWith(LogMatchResultDialogNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: LogMatchResultDialogNotifierProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<LogMatchResultDialogNotifier,
      LogMatchResultDialogState> createElement() {
    return _LogMatchResultDialogNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LogMatchResultDialogNotifierProvider &&
        other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LogMatchResultDialogNotifierRef
    on AutoDisposeNotifierProviderRef<LogMatchResultDialogState> {
  /// The parameter `params` of this provider.
  LogMatchResultDialogParams get params;
}

class _LogMatchResultDialogNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<LogMatchResultDialogNotifier,
        LogMatchResultDialogState> with LogMatchResultDialogNotifierRef {
  _LogMatchResultDialogNotifierProviderElement(super.provider);

  @override
  LogMatchResultDialogParams get params =>
      (origin as LogMatchResultDialogNotifierProvider).params;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
