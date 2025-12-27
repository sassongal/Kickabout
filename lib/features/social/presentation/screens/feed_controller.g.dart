// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$feedControllerHash() => r'ebeb6c8888a3d7777c448e6bb25e0302d86c9410';

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

abstract class _$FeedController
    extends BuildlessAutoDisposeAsyncNotifier<List<FeedPost>> {
  late final FeedFilter filter;

  FutureOr<List<FeedPost>> build(
    FeedFilter filter,
  );
}

/// See also [FeedController].
@ProviderFor(FeedController)
const feedControllerProvider = FeedControllerFamily();

/// See also [FeedController].
class FeedControllerFamily extends Family<AsyncValue<List<FeedPost>>> {
  /// See also [FeedController].
  const FeedControllerFamily();

  /// See also [FeedController].
  FeedControllerProvider call(
    FeedFilter filter,
  ) {
    return FeedControllerProvider(
      filter,
    );
  }

  @override
  FeedControllerProvider getProviderOverride(
    covariant FeedControllerProvider provider,
  ) {
    return call(
      provider.filter,
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
  String? get name => r'feedControllerProvider';
}

/// See also [FeedController].
class FeedControllerProvider extends AutoDisposeAsyncNotifierProviderImpl<
    FeedController, List<FeedPost>> {
  /// See also [FeedController].
  FeedControllerProvider(
    FeedFilter filter,
  ) : this._internal(
          () => FeedController()..filter = filter,
          from: feedControllerProvider,
          name: r'feedControllerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$feedControllerHash,
          dependencies: FeedControllerFamily._dependencies,
          allTransitiveDependencies:
              FeedControllerFamily._allTransitiveDependencies,
          filter: filter,
        );

  FeedControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.filter,
  }) : super.internal();

  final FeedFilter filter;

  @override
  FutureOr<List<FeedPost>> runNotifierBuild(
    covariant FeedController notifier,
  ) {
    return notifier.build(
      filter,
    );
  }

  @override
  Override overrideWith(FeedController Function() create) {
    return ProviderOverride(
      origin: this,
      override: FeedControllerProvider._internal(
        () => create()..filter = filter,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        filter: filter,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<FeedController, List<FeedPost>>
      createElement() {
    return _FeedControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedControllerProvider && other.filter == filter;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, filter.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin FeedControllerRef on AutoDisposeAsyncNotifierProviderRef<List<FeedPost>> {
  /// The parameter `filter` of this provider.
  FeedFilter get filter;
}

class _FeedControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<FeedController,
        List<FeedPost>> with FeedControllerRef {
  _FeedControllerProviderElement(super.provider);

  @override
  FeedFilter get filter => (origin as FeedControllerProvider).filter;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
