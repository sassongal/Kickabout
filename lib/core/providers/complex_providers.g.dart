// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complex_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$hubStreamHash() => r'96c6316476ca4e4e50361a6ccf8041319faba125';

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

/// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
///
/// This provider eliminates duplicate watchHub() subscriptions across screens.
/// All hub-related UI should watch this provider instead of calling repository directly.
///
/// Benefits:
/// - Cache coherence: One subscription shared across all widgets
/// - Memory efficiency: No duplicate streams
/// - Consistent state: All widgets see the same data
/// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
///
/// Usage:
/// ```dart
/// final hubAsync = ref.watch(hubStreamProvider(hubId));
/// return hubAsync.when(
///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubStream].
@ProviderFor(hubStream)
const hubStreamProvider = HubStreamFamily();

/// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
///
/// This provider eliminates duplicate watchHub() subscriptions across screens.
/// All hub-related UI should watch this provider instead of calling repository directly.
///
/// Benefits:
/// - Cache coherence: One subscription shared across all widgets
/// - Memory efficiency: No duplicate streams
/// - Consistent state: All widgets see the same data
/// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
///
/// Usage:
/// ```dart
/// final hubAsync = ref.watch(hubStreamProvider(hubId));
/// return hubAsync.when(
///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubStream].
class HubStreamFamily extends Family<AsyncValue<Hub?>> {
  /// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
  ///
  /// This provider eliminates duplicate watchHub() subscriptions across screens.
  /// All hub-related UI should watch this provider instead of calling repository directly.
  ///
  /// Benefits:
  /// - Cache coherence: One subscription shared across all widgets
  /// - Memory efficiency: No duplicate streams
  /// - Consistent state: All widgets see the same data
  /// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
  ///
  /// Usage:
  /// ```dart
  /// final hubAsync = ref.watch(hubStreamProvider(hubId));
  /// return hubAsync.when(
  ///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubStream].
  const HubStreamFamily();

  /// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
  ///
  /// This provider eliminates duplicate watchHub() subscriptions across screens.
  /// All hub-related UI should watch this provider instead of calling repository directly.
  ///
  /// Benefits:
  /// - Cache coherence: One subscription shared across all widgets
  /// - Memory efficiency: No duplicate streams
  /// - Consistent state: All widgets see the same data
  /// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
  ///
  /// Usage:
  /// ```dart
  /// final hubAsync = ref.watch(hubStreamProvider(hubId));
  /// return hubAsync.when(
  ///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubStream].
  HubStreamProvider call(
    String hubId,
  ) {
    return HubStreamProvider(
      hubId,
    );
  }

  @override
  HubStreamProvider getProviderOverride(
    covariant HubStreamProvider provider,
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
  String? get name => r'hubStreamProvider';
}

/// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
///
/// This provider eliminates duplicate watchHub() subscriptions across screens.
/// All hub-related UI should watch this provider instead of calling repository directly.
///
/// Benefits:
/// - Cache coherence: One subscription shared across all widgets
/// - Memory efficiency: No duplicate streams
/// - Consistent state: All widgets see the same data
/// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
///
/// Usage:
/// ```dart
/// final hubAsync = ref.watch(hubStreamProvider(hubId));
/// return hubAsync.when(
///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubStream].
class HubStreamProvider extends AutoDisposeStreamProvider<Hub?> {
  /// Unified hub stream provider - SINGLE SOURCE OF TRUTH for hub data
  ///
  /// This provider eliminates duplicate watchHub() subscriptions across screens.
  /// All hub-related UI should watch this provider instead of calling repository directly.
  ///
  /// Benefits:
  /// - Cache coherence: One subscription shared across all widgets
  /// - Memory efficiency: No duplicate streams
  /// - Consistent state: All widgets see the same data
  /// - Easy invalidation: ref.invalidate(hubStreamProvider(hubId))
  ///
  /// Usage:
  /// ```dart
  /// final hubAsync = ref.watch(hubStreamProvider(hubId));
  /// return hubAsync.when(
  ///   data: (hub) => hub != null ? HubContent(hub) : NotFound(),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubStream].
  HubStreamProvider(
    String hubId,
  ) : this._internal(
          (ref) => hubStream(
            ref as HubStreamRef,
            hubId,
          ),
          from: hubStreamProvider,
          name: r'hubStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubStreamHash,
          dependencies: HubStreamFamily._dependencies,
          allTransitiveDependencies: HubStreamFamily._allTransitiveDependencies,
          hubId: hubId,
        );

  HubStreamProvider._internal(
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
  Override overrideWith(
    Stream<Hub?> Function(HubStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubStreamProvider._internal(
        (ref) => create(ref as HubStreamRef),
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
  AutoDisposeStreamProviderElement<Hub?> createElement() {
    return _HubStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubStreamProvider && other.hubId == hubId;
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
mixin HubStreamRef on AutoDisposeStreamProviderRef<Hub?> {
  /// The parameter `hubId` of this provider.
  String get hubId;
}

class _HubStreamProviderElement extends AutoDisposeStreamProviderElement<Hub?>
    with HubStreamRef {
  _HubStreamProviderElement(super.provider);

  @override
  String get hubId => (origin as HubStreamProvider).hubId;
}

String _$hubsByMemberStreamHash() =>
    r'd96082c95f18636cc3a99fa28c571bc0bf5bb2d5';

/// Hubs by member stream - all hubs a user belongs to
///
/// This provider eliminates duplicate watchHubsByMember() subscriptions.
/// All screens showing user's hubs should use this provider.
///
/// Benefits:
/// - Single subscription shared across widgets
/// - Automatic caching with keepAlive
/// - Consistent hub list across screens
///
/// Usage:
/// ```dart
/// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
/// return hubsAsync.when(
///   data: (hubs) => HubList(hubs),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubsByMemberStream].
@ProviderFor(hubsByMemberStream)
const hubsByMemberStreamProvider = HubsByMemberStreamFamily();

/// Hubs by member stream - all hubs a user belongs to
///
/// This provider eliminates duplicate watchHubsByMember() subscriptions.
/// All screens showing user's hubs should use this provider.
///
/// Benefits:
/// - Single subscription shared across widgets
/// - Automatic caching with keepAlive
/// - Consistent hub list across screens
///
/// Usage:
/// ```dart
/// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
/// return hubsAsync.when(
///   data: (hubs) => HubList(hubs),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubsByMemberStream].
class HubsByMemberStreamFamily extends Family<AsyncValue<List<Hub>>> {
  /// Hubs by member stream - all hubs a user belongs to
  ///
  /// This provider eliminates duplicate watchHubsByMember() subscriptions.
  /// All screens showing user's hubs should use this provider.
  ///
  /// Benefits:
  /// - Single subscription shared across widgets
  /// - Automatic caching with keepAlive
  /// - Consistent hub list across screens
  ///
  /// Usage:
  /// ```dart
  /// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
  /// return hubsAsync.when(
  ///   data: (hubs) => HubList(hubs),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubsByMemberStream].
  const HubsByMemberStreamFamily();

  /// Hubs by member stream - all hubs a user belongs to
  ///
  /// This provider eliminates duplicate watchHubsByMember() subscriptions.
  /// All screens showing user's hubs should use this provider.
  ///
  /// Benefits:
  /// - Single subscription shared across widgets
  /// - Automatic caching with keepAlive
  /// - Consistent hub list across screens
  ///
  /// Usage:
  /// ```dart
  /// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
  /// return hubsAsync.when(
  ///   data: (hubs) => HubList(hubs),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubsByMemberStream].
  HubsByMemberStreamProvider call(
    String userId,
  ) {
    return HubsByMemberStreamProvider(
      userId,
    );
  }

  @override
  HubsByMemberStreamProvider getProviderOverride(
    covariant HubsByMemberStreamProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'hubsByMemberStreamProvider';
}

/// Hubs by member stream - all hubs a user belongs to
///
/// This provider eliminates duplicate watchHubsByMember() subscriptions.
/// All screens showing user's hubs should use this provider.
///
/// Benefits:
/// - Single subscription shared across widgets
/// - Automatic caching with keepAlive
/// - Consistent hub list across screens
///
/// Usage:
/// ```dart
/// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
/// return hubsAsync.when(
///   data: (hubs) => HubList(hubs),
///   loading: () => LoadingIndicator(),
///   error: (err, stack) => ErrorDisplay(err),
/// );
/// ```
///
/// Copied from [hubsByMemberStream].
class HubsByMemberStreamProvider extends AutoDisposeStreamProvider<List<Hub>> {
  /// Hubs by member stream - all hubs a user belongs to
  ///
  /// This provider eliminates duplicate watchHubsByMember() subscriptions.
  /// All screens showing user's hubs should use this provider.
  ///
  /// Benefits:
  /// - Single subscription shared across widgets
  /// - Automatic caching with keepAlive
  /// - Consistent hub list across screens
  ///
  /// Usage:
  /// ```dart
  /// final hubsAsync = ref.watch(hubsByMemberStreamProvider(userId));
  /// return hubsAsync.when(
  ///   data: (hubs) => HubList(hubs),
  ///   loading: () => LoadingIndicator(),
  ///   error: (err, stack) => ErrorDisplay(err),
  /// );
  /// ```
  ///
  /// Copied from [hubsByMemberStream].
  HubsByMemberStreamProvider(
    String userId,
  ) : this._internal(
          (ref) => hubsByMemberStream(
            ref as HubsByMemberStreamRef,
            userId,
          ),
          from: hubsByMemberStreamProvider,
          name: r'hubsByMemberStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubsByMemberStreamHash,
          dependencies: HubsByMemberStreamFamily._dependencies,
          allTransitiveDependencies:
              HubsByMemberStreamFamily._allTransitiveDependencies,
          userId: userId,
        );

  HubsByMemberStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<List<Hub>> Function(HubsByMemberStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubsByMemberStreamProvider._internal(
        (ref) => create(ref as HubsByMemberStreamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Hub>> createElement() {
    return _HubsByMemberStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubsByMemberStreamProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HubsByMemberStreamRef on AutoDisposeStreamProviderRef<List<Hub>> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _HubsByMemberStreamProviderElement
    extends AutoDisposeStreamProviderElement<List<Hub>>
    with HubsByMemberStreamRef {
  _HubsByMemberStreamProviderElement(super.provider);

  @override
  String get userId => (origin as HubsByMemberStreamProvider).userId;
}

String _$hubPermissionsStreamHash() =>
    r'1f2bb781d89f9c2a4582a0407de1a1837e5e3f85';

/// Hub permissions provider - computes effective permissions for a user in a hub
///
/// This provider automatically watches hub state and membership, recomputing
/// permissions when either changes.
///
/// Usage:
/// ```dart
/// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
/// if (permissions.canCreateGames) { ... }
/// ```
///
/// Copied from [hubPermissionsStream].
@ProviderFor(hubPermissionsStream)
const hubPermissionsStreamProvider = HubPermissionsStreamFamily();

/// Hub permissions provider - computes effective permissions for a user in a hub
///
/// This provider automatically watches hub state and membership, recomputing
/// permissions when either changes.
///
/// Usage:
/// ```dart
/// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
/// if (permissions.canCreateGames) { ... }
/// ```
///
/// Copied from [hubPermissionsStream].
class HubPermissionsStreamFamily extends Family<AsyncValue<HubPermissions?>> {
  /// Hub permissions provider - computes effective permissions for a user in a hub
  ///
  /// This provider automatically watches hub state and membership, recomputing
  /// permissions when either changes.
  ///
  /// Usage:
  /// ```dart
  /// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
  /// if (permissions.canCreateGames) { ... }
  /// ```
  ///
  /// Copied from [hubPermissionsStream].
  const HubPermissionsStreamFamily();

  /// Hub permissions provider - computes effective permissions for a user in a hub
  ///
  /// This provider automatically watches hub state and membership, recomputing
  /// permissions when either changes.
  ///
  /// Usage:
  /// ```dart
  /// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
  /// if (permissions.canCreateGames) { ... }
  /// ```
  ///
  /// Copied from [hubPermissionsStream].
  HubPermissionsStreamProvider call(
    ({String hubId, String userId}) params,
  ) {
    return HubPermissionsStreamProvider(
      params,
    );
  }

  @override
  HubPermissionsStreamProvider getProviderOverride(
    covariant HubPermissionsStreamProvider provider,
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
  String? get name => r'hubPermissionsStreamProvider';
}

/// Hub permissions provider - computes effective permissions for a user in a hub
///
/// This provider automatically watches hub state and membership, recomputing
/// permissions when either changes.
///
/// Usage:
/// ```dart
/// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
/// if (permissions.canCreateGames) { ... }
/// ```
///
/// Copied from [hubPermissionsStream].
class HubPermissionsStreamProvider
    extends AutoDisposeStreamProvider<HubPermissions?> {
  /// Hub permissions provider - computes effective permissions for a user in a hub
  ///
  /// This provider automatically watches hub state and membership, recomputing
  /// permissions when either changes.
  ///
  /// Usage:
  /// ```dart
  /// final permissions = await ref.watch(hubPermissionsStreamProvider((hubId: hubId, userId: userId)).future);
  /// if (permissions.canCreateGames) { ... }
  /// ```
  ///
  /// Copied from [hubPermissionsStream].
  HubPermissionsStreamProvider(
    ({String hubId, String userId}) params,
  ) : this._internal(
          (ref) => hubPermissionsStream(
            ref as HubPermissionsStreamRef,
            params,
          ),
          from: hubPermissionsStreamProvider,
          name: r'hubPermissionsStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubPermissionsStreamHash,
          dependencies: HubPermissionsStreamFamily._dependencies,
          allTransitiveDependencies:
              HubPermissionsStreamFamily._allTransitiveDependencies,
          params: params,
        );

  HubPermissionsStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String hubId, String userId}) params;

  @override
  Override overrideWith(
    Stream<HubPermissions?> Function(HubPermissionsStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubPermissionsStreamProvider._internal(
        (ref) => create(ref as HubPermissionsStreamRef),
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
  AutoDisposeStreamProviderElement<HubPermissions?> createElement() {
    return _HubPermissionsStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubPermissionsStreamProvider && other.params == params;
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
mixin HubPermissionsStreamRef on AutoDisposeStreamProviderRef<HubPermissions?> {
  /// The parameter `params` of this provider.
  ({String hubId, String userId}) get params;
}

class _HubPermissionsStreamProviderElement
    extends AutoDisposeStreamProviderElement<HubPermissions?>
    with HubPermissionsStreamRef {
  _HubPermissionsStreamProviderElement(super.provider);

  @override
  ({String hubId, String userId}) get params =>
      (origin as HubPermissionsStreamProvider).params;
}

String _$hubRoleStreamHash() => r'36e76c8f910873c195bee3fea8f5a8486bf5bbdb';

/// Hub role stream provider - derives user's role in a hub
///
/// Convenience provider that extracts just the role from permissions.
///
/// Usage:
/// ```dart
/// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
/// ```
///
/// Copied from [hubRoleStream].
@ProviderFor(hubRoleStream)
const hubRoleStreamProvider = HubRoleStreamFamily();

/// Hub role stream provider - derives user's role in a hub
///
/// Convenience provider that extracts just the role from permissions.
///
/// Usage:
/// ```dart
/// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
/// ```
///
/// Copied from [hubRoleStream].
class HubRoleStreamFamily extends Family<AsyncValue<HubMemberRole?>> {
  /// Hub role stream provider - derives user's role in a hub
  ///
  /// Convenience provider that extracts just the role from permissions.
  ///
  /// Usage:
  /// ```dart
  /// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
  /// ```
  ///
  /// Copied from [hubRoleStream].
  const HubRoleStreamFamily();

  /// Hub role stream provider - derives user's role in a hub
  ///
  /// Convenience provider that extracts just the role from permissions.
  ///
  /// Usage:
  /// ```dart
  /// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
  /// ```
  ///
  /// Copied from [hubRoleStream].
  HubRoleStreamProvider call(
    ({String hubId, String userId}) params,
  ) {
    return HubRoleStreamProvider(
      params,
    );
  }

  @override
  HubRoleStreamProvider getProviderOverride(
    covariant HubRoleStreamProvider provider,
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
  String? get name => r'hubRoleStreamProvider';
}

/// Hub role stream provider - derives user's role in a hub
///
/// Convenience provider that extracts just the role from permissions.
///
/// Usage:
/// ```dart
/// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
/// ```
///
/// Copied from [hubRoleStream].
class HubRoleStreamProvider extends AutoDisposeStreamProvider<HubMemberRole?> {
  /// Hub role stream provider - derives user's role in a hub
  ///
  /// Convenience provider that extracts just the role from permissions.
  ///
  /// Usage:
  /// ```dart
  /// final role = ref.watch(hubRoleStreamProvider((hubId: hubId, userId: userId)));
  /// ```
  ///
  /// Copied from [hubRoleStream].
  HubRoleStreamProvider(
    ({String hubId, String userId}) params,
  ) : this._internal(
          (ref) => hubRoleStream(
            ref as HubRoleStreamRef,
            params,
          ),
          from: hubRoleStreamProvider,
          name: r'hubRoleStreamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubRoleStreamHash,
          dependencies: HubRoleStreamFamily._dependencies,
          allTransitiveDependencies:
              HubRoleStreamFamily._allTransitiveDependencies,
          params: params,
        );

  HubRoleStreamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String hubId, String userId}) params;

  @override
  Override overrideWith(
    Stream<HubMemberRole?> Function(HubRoleStreamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubRoleStreamProvider._internal(
        (ref) => create(ref as HubRoleStreamRef),
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
  AutoDisposeStreamProviderElement<HubMemberRole?> createElement() {
    return _HubRoleStreamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubRoleStreamProvider && other.params == params;
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
mixin HubRoleStreamRef on AutoDisposeStreamProviderRef<HubMemberRole?> {
  /// The parameter `params` of this provider.
  ({String hubId, String userId}) get params;
}

class _HubRoleStreamProviderElement
    extends AutoDisposeStreamProviderElement<HubMemberRole?>
    with HubRoleStreamRef {
  _HubRoleStreamProviderElement(super.provider);

  @override
  ({String hubId, String userId}) get params =>
      (origin as HubRoleStreamProvider).params;
}

String _$paginatedHubMembersHash() =>
    r'da2c0e19b27037064e78f25ffce754e484f01920';

/// Paginated hub members provider - replaces manual pagination state
///
/// Automatically fetches members in pages, maintains state across rebuilds,
/// and provides loading indicators for infinite scroll.
///
/// Usage:
/// ```dart
/// final membersAsync = ref.watch(paginatedHubMembersProvider(
///   (hubId: hubId, page: currentPage, pageSize: 20)
/// ));
/// ```
///
/// Copied from [paginatedHubMembers].
@ProviderFor(paginatedHubMembers)
const paginatedHubMembersProvider = PaginatedHubMembersFamily();

/// Paginated hub members provider - replaces manual pagination state
///
/// Automatically fetches members in pages, maintains state across rebuilds,
/// and provides loading indicators for infinite scroll.
///
/// Usage:
/// ```dart
/// final membersAsync = ref.watch(paginatedHubMembersProvider(
///   (hubId: hubId, page: currentPage, pageSize: 20)
/// ));
/// ```
///
/// Copied from [paginatedHubMembers].
class PaginatedHubMembersFamily extends Family<AsyncValue<List<User>>> {
  /// Paginated hub members provider - replaces manual pagination state
  ///
  /// Automatically fetches members in pages, maintains state across rebuilds,
  /// and provides loading indicators for infinite scroll.
  ///
  /// Usage:
  /// ```dart
  /// final membersAsync = ref.watch(paginatedHubMembersProvider(
  ///   (hubId: hubId, page: currentPage, pageSize: 20)
  /// ));
  /// ```
  ///
  /// Copied from [paginatedHubMembers].
  const PaginatedHubMembersFamily();

  /// Paginated hub members provider - replaces manual pagination state
  ///
  /// Automatically fetches members in pages, maintains state across rebuilds,
  /// and provides loading indicators for infinite scroll.
  ///
  /// Usage:
  /// ```dart
  /// final membersAsync = ref.watch(paginatedHubMembersProvider(
  ///   (hubId: hubId, page: currentPage, pageSize: 20)
  /// ));
  /// ```
  ///
  /// Copied from [paginatedHubMembers].
  PaginatedHubMembersProvider call(
    ({String hubId, int page, int pageSize}) params,
  ) {
    return PaginatedHubMembersProvider(
      params,
    );
  }

  @override
  PaginatedHubMembersProvider getProviderOverride(
    covariant PaginatedHubMembersProvider provider,
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
  String? get name => r'paginatedHubMembersProvider';
}

/// Paginated hub members provider - replaces manual pagination state
///
/// Automatically fetches members in pages, maintains state across rebuilds,
/// and provides loading indicators for infinite scroll.
///
/// Usage:
/// ```dart
/// final membersAsync = ref.watch(paginatedHubMembersProvider(
///   (hubId: hubId, page: currentPage, pageSize: 20)
/// ));
/// ```
///
/// Copied from [paginatedHubMembers].
class PaginatedHubMembersProvider
    extends AutoDisposeFutureProvider<List<User>> {
  /// Paginated hub members provider - replaces manual pagination state
  ///
  /// Automatically fetches members in pages, maintains state across rebuilds,
  /// and provides loading indicators for infinite scroll.
  ///
  /// Usage:
  /// ```dart
  /// final membersAsync = ref.watch(paginatedHubMembersProvider(
  ///   (hubId: hubId, page: currentPage, pageSize: 20)
  /// ));
  /// ```
  ///
  /// Copied from [paginatedHubMembers].
  PaginatedHubMembersProvider(
    ({String hubId, int page, int pageSize}) params,
  ) : this._internal(
          (ref) => paginatedHubMembers(
            ref as PaginatedHubMembersRef,
            params,
          ),
          from: paginatedHubMembersProvider,
          name: r'paginatedHubMembersProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$paginatedHubMembersHash,
          dependencies: PaginatedHubMembersFamily._dependencies,
          allTransitiveDependencies:
              PaginatedHubMembersFamily._allTransitiveDependencies,
          params: params,
        );

  PaginatedHubMembersProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String hubId, int page, int pageSize}) params;

  @override
  Override overrideWith(
    FutureOr<List<User>> Function(PaginatedHubMembersRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: PaginatedHubMembersProvider._internal(
        (ref) => create(ref as PaginatedHubMembersRef),
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
  AutoDisposeFutureProviderElement<List<User>> createElement() {
    return _PaginatedHubMembersProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaginatedHubMembersProvider && other.params == params;
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
mixin PaginatedHubMembersRef on AutoDisposeFutureProviderRef<List<User>> {
  /// The parameter `params` of this provider.
  ({String hubId, int page, int pageSize}) get params;
}

class _PaginatedHubMembersProviderElement
    extends AutoDisposeFutureProviderElement<List<User>>
    with PaginatedHubMembersRef {
  _PaginatedHubMembersProviderElement(super.provider);

  @override
  ({String hubId, int page, int pageSize}) get params =>
      (origin as PaginatedHubMembersProvider).params;
}

String _$hubMembersCountHash() => r'7a130ea25c744077f8aabcada9b63bfec0d1fb1a';

/// Total hub members count provider
///
/// Copied from [hubMembersCount].
@ProviderFor(hubMembersCount)
const hubMembersCountProvider = HubMembersCountFamily();

/// Total hub members count provider
///
/// Copied from [hubMembersCount].
class HubMembersCountFamily extends Family<AsyncValue<int>> {
  /// Total hub members count provider
  ///
  /// Copied from [hubMembersCount].
  const HubMembersCountFamily();

  /// Total hub members count provider
  ///
  /// Copied from [hubMembersCount].
  HubMembersCountProvider call(
    String hubId,
  ) {
    return HubMembersCountProvider(
      hubId,
    );
  }

  @override
  HubMembersCountProvider getProviderOverride(
    covariant HubMembersCountProvider provider,
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
  String? get name => r'hubMembersCountProvider';
}

/// Total hub members count provider
///
/// Copied from [hubMembersCount].
class HubMembersCountProvider extends AutoDisposeFutureProvider<int> {
  /// Total hub members count provider
  ///
  /// Copied from [hubMembersCount].
  HubMembersCountProvider(
    String hubId,
  ) : this._internal(
          (ref) => hubMembersCount(
            ref as HubMembersCountRef,
            hubId,
          ),
          from: hubMembersCountProvider,
          name: r'hubMembersCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubMembersCountHash,
          dependencies: HubMembersCountFamily._dependencies,
          allTransitiveDependencies:
              HubMembersCountFamily._allTransitiveDependencies,
          hubId: hubId,
        );

  HubMembersCountProvider._internal(
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
  Override overrideWith(
    FutureOr<int> Function(HubMembersCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubMembersCountProvider._internal(
        (ref) => create(ref as HubMembersCountRef),
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
  AutoDisposeFutureProviderElement<int> createElement() {
    return _HubMembersCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubMembersCountProvider && other.hubId == hubId;
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
mixin HubMembersCountRef on AutoDisposeFutureProviderRef<int> {
  /// The parameter `hubId` of this provider.
  String get hubId;
}

class _HubMembersCountProviderElement
    extends AutoDisposeFutureProviderElement<int> with HubMembersCountRef {
  _HubMembersCountProviderElement(super.provider);

  @override
  String get hubId => (origin as HubMembersCountProvider).hubId;
}

String _$leaderboardHash() => r'6433ec59a604ca64e42b4b046d9e1eee5bd98e1d';

/// Leaderboard provider - watches top ranked users
///
/// Copied from [leaderboard].
@ProviderFor(leaderboard)
const leaderboardProvider = LeaderboardFamily();

/// Leaderboard provider - watches top ranked users
///
/// Copied from [leaderboard].
class LeaderboardFamily extends Family<AsyncValue<List<LeaderboardEntry>>> {
  /// Leaderboard provider - watches top ranked users
  ///
  /// Copied from [leaderboard].
  const LeaderboardFamily();

  /// Leaderboard provider - watches top ranked users
  ///
  /// Copied from [leaderboard].
  LeaderboardProvider call(
    LeaderboardParams params,
  ) {
    return LeaderboardProvider(
      params,
    );
  }

  @override
  LeaderboardProvider getProviderOverride(
    covariant LeaderboardProvider provider,
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
  String? get name => r'leaderboardProvider';
}

/// Leaderboard provider - watches top ranked users
///
/// Copied from [leaderboard].
class LeaderboardProvider
    extends AutoDisposeFutureProvider<List<LeaderboardEntry>> {
  /// Leaderboard provider - watches top ranked users
  ///
  /// Copied from [leaderboard].
  LeaderboardProvider(
    LeaderboardParams params,
  ) : this._internal(
          (ref) => leaderboard(
            ref as LeaderboardRef,
            params,
          ),
          from: leaderboardProvider,
          name: r'leaderboardProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$leaderboardHash,
          dependencies: LeaderboardFamily._dependencies,
          allTransitiveDependencies:
              LeaderboardFamily._allTransitiveDependencies,
          params: params,
        );

  LeaderboardProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final LeaderboardParams params;

  @override
  Override overrideWith(
    FutureOr<List<LeaderboardEntry>> Function(LeaderboardRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LeaderboardProvider._internal(
        (ref) => create(ref as LeaderboardRef),
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
  AutoDisposeFutureProviderElement<List<LeaderboardEntry>> createElement() {
    return _LeaderboardProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LeaderboardProvider && other.params == params;
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
mixin LeaderboardRef on AutoDisposeFutureProviderRef<List<LeaderboardEntry>> {
  /// The parameter `params` of this provider.
  LeaderboardParams get params;
}

class _LeaderboardProviderElement
    extends AutoDisposeFutureProviderElement<List<LeaderboardEntry>>
    with LeaderboardRef {
  _LeaderboardProviderElement(super.provider);

  @override
  LeaderboardParams get params => (origin as LeaderboardProvider).params;
}

String _$unreadNotificationsCountHash() =>
    r'd5b471ec1f913619bec0480184292c0e0405c0f9';

/// Unread notifications count provider
///
/// Copied from [unreadNotificationsCount].
@ProviderFor(unreadNotificationsCount)
const unreadNotificationsCountProvider = UnreadNotificationsCountFamily();

/// Unread notifications count provider
///
/// Copied from [unreadNotificationsCount].
class UnreadNotificationsCountFamily extends Family<AsyncValue<int>> {
  /// Unread notifications count provider
  ///
  /// Copied from [unreadNotificationsCount].
  const UnreadNotificationsCountFamily();

  /// Unread notifications count provider
  ///
  /// Copied from [unreadNotificationsCount].
  UnreadNotificationsCountProvider call(
    String userId,
  ) {
    return UnreadNotificationsCountProvider(
      userId,
    );
  }

  @override
  UnreadNotificationsCountProvider getProviderOverride(
    covariant UnreadNotificationsCountProvider provider,
  ) {
    return call(
      provider.userId,
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
  String? get name => r'unreadNotificationsCountProvider';
}

/// Unread notifications count provider
///
/// Copied from [unreadNotificationsCount].
class UnreadNotificationsCountProvider extends AutoDisposeStreamProvider<int> {
  /// Unread notifications count provider
  ///
  /// Copied from [unreadNotificationsCount].
  UnreadNotificationsCountProvider(
    String userId,
  ) : this._internal(
          (ref) => unreadNotificationsCount(
            ref as UnreadNotificationsCountRef,
            userId,
          ),
          from: unreadNotificationsCountProvider,
          name: r'unreadNotificationsCountProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$unreadNotificationsCountHash,
          dependencies: UnreadNotificationsCountFamily._dependencies,
          allTransitiveDependencies:
              UnreadNotificationsCountFamily._allTransitiveDependencies,
          userId: userId,
        );

  UnreadNotificationsCountProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    Stream<int> Function(UnreadNotificationsCountRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UnreadNotificationsCountProvider._internal(
        (ref) => create(ref as UnreadNotificationsCountRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<int> createElement() {
    return _UnreadNotificationsCountProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UnreadNotificationsCountProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UnreadNotificationsCountRef on AutoDisposeStreamProviderRef<int> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UnreadNotificationsCountProviderElement
    extends AutoDisposeStreamProviderElement<int>
    with UnreadNotificationsCountRef {
  _UnreadNotificationsCountProviderElement(super.provider);

  @override
  String get userId => (origin as UnreadNotificationsCountProvider).userId;
}

String _$hubsByCreatorHash() => r'5aa6580891c9dd453b4cf51431a3990c6ade14c2';

/// Hubs by creator stream provider with keepAlive for performance
///
/// Copied from [hubsByCreator].
@ProviderFor(hubsByCreator)
const hubsByCreatorProvider = HubsByCreatorFamily();

/// Hubs by creator stream provider with keepAlive for performance
///
/// Copied from [hubsByCreator].
class HubsByCreatorFamily extends Family<AsyncValue<List<Hub>>> {
  /// Hubs by creator stream provider with keepAlive for performance
  ///
  /// Copied from [hubsByCreator].
  const HubsByCreatorFamily();

  /// Hubs by creator stream provider with keepAlive for performance
  ///
  /// Copied from [hubsByCreator].
  HubsByCreatorProvider call(
    String uid,
  ) {
    return HubsByCreatorProvider(
      uid,
    );
  }

  @override
  HubsByCreatorProvider getProviderOverride(
    covariant HubsByCreatorProvider provider,
  ) {
    return call(
      provider.uid,
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
  String? get name => r'hubsByCreatorProvider';
}

/// Hubs by creator stream provider with keepAlive for performance
///
/// Copied from [hubsByCreator].
class HubsByCreatorProvider extends AutoDisposeStreamProvider<List<Hub>> {
  /// Hubs by creator stream provider with keepAlive for performance
  ///
  /// Copied from [hubsByCreator].
  HubsByCreatorProvider(
    String uid,
  ) : this._internal(
          (ref) => hubsByCreator(
            ref as HubsByCreatorRef,
            uid,
          ),
          from: hubsByCreatorProvider,
          name: r'hubsByCreatorProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubsByCreatorHash,
          dependencies: HubsByCreatorFamily._dependencies,
          allTransitiveDependencies:
              HubsByCreatorFamily._allTransitiveDependencies,
          uid: uid,
        );

  HubsByCreatorProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.uid,
  }) : super.internal();

  final String uid;

  @override
  Override overrideWith(
    Stream<List<Hub>> Function(HubsByCreatorRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubsByCreatorProvider._internal(
        (ref) => create(ref as HubsByCreatorRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        uid: uid,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<Hub>> createElement() {
    return _HubsByCreatorProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubsByCreatorProvider && other.uid == uid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, uid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HubsByCreatorRef on AutoDisposeStreamProviderRef<List<Hub>> {
  /// The parameter `uid` of this provider.
  String get uid;
}

class _HubsByCreatorProviderElement
    extends AutoDisposeStreamProviderElement<List<Hub>> with HubsByCreatorRef {
  _HubsByCreatorProviderElement(super.provider);

  @override
  String get uid => (origin as HubsByCreatorProvider).uid;
}

String _$homeDashboardDataHash() => r'3212ea2f55ca5127a9c40f2e81e1c0acd006d025';

/// Home dashboard data provider (weather & vibe) - using Open-Meteo (free)
///
/// Refactored to delegate to DashboardService for business logic.
/// This provider now only handles state management.
///
/// Copied from [homeDashboardData].
@ProviderFor(homeDashboardData)
final homeDashboardDataProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>>.internal(
  homeDashboardData,
  name: r'homeDashboardDataProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$homeDashboardDataHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HomeDashboardDataRef
    = AutoDisposeFutureProviderRef<Map<String, dynamic>>;
String _$hubPermissionsHash() => r'149637cf1e7b9cb6dc02eb42dd851d90aef39804';

/// Hub permissions provider - provides HubPermissions for a user in a hub
/// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
///
/// Copied from [hubPermissions].
@ProviderFor(hubPermissions)
const hubPermissionsProvider = HubPermissionsFamily();

/// Hub permissions provider - provides HubPermissions for a user in a hub
/// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
///
/// Copied from [hubPermissions].
class HubPermissionsFamily extends Family<AsyncValue<HubPermissions>> {
  /// Hub permissions provider - provides HubPermissions for a user in a hub
  /// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
  ///
  /// Copied from [hubPermissions].
  const HubPermissionsFamily();

  /// Hub permissions provider - provides HubPermissions for a user in a hub
  /// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
  ///
  /// Copied from [hubPermissions].
  HubPermissionsProvider call(
    ({String hubId, String userId}) params,
  ) {
    return HubPermissionsProvider(
      params,
    );
  }

  @override
  HubPermissionsProvider getProviderOverride(
    covariant HubPermissionsProvider provider,
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
  String? get name => r'hubPermissionsProvider';
}

/// Hub permissions provider - provides HubPermissions for a user in a hub
/// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
///
/// Copied from [hubPermissions].
class HubPermissionsProvider extends AutoDisposeFutureProvider<HubPermissions> {
  /// Hub permissions provider - provides HubPermissions for a user in a hub
  /// Usage: ref.watch(hubPermissionsProvider((hubId: 'xxx', userId: 'yyy')))
  ///
  /// Copied from [hubPermissions].
  HubPermissionsProvider(
    ({String hubId, String userId}) params,
  ) : this._internal(
          (ref) => hubPermissions(
            ref as HubPermissionsRef,
            params,
          ),
          from: hubPermissionsProvider,
          name: r'hubPermissionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubPermissionsHash,
          dependencies: HubPermissionsFamily._dependencies,
          allTransitiveDependencies:
              HubPermissionsFamily._allTransitiveDependencies,
          params: params,
        );

  HubPermissionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ({String hubId, String userId}) params;

  @override
  Override overrideWith(
    FutureOr<HubPermissions> Function(HubPermissionsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubPermissionsProvider._internal(
        (ref) => create(ref as HubPermissionsRef),
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
  AutoDisposeFutureProviderElement<HubPermissions> createElement() {
    return _HubPermissionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubPermissionsProvider && other.params == params;
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
mixin HubPermissionsRef on AutoDisposeFutureProviderRef<HubPermissions> {
  /// The parameter `params` of this provider.
  ({String hubId, String userId}) get params;
}

class _HubPermissionsProviderElement
    extends AutoDisposeFutureProviderElement<HubPermissions>
    with HubPermissionsRef {
  _HubPermissionsProviderElement(super.provider);

  @override
  ({String hubId, String userId}) get params =>
      (origin as HubPermissionsProvider).params;
}

String _$hubRoleHash() => r'76c3a535d6bf37e0a2a3dd4c3d24cd619f1d125d';

/// Returns UserRole.admin if user is the hub creator or has manager/moderator role
/// Returns UserRole.member if user is a member of the hub
/// Returns UserRole.none if user is not a member
///
/// Copied from [hubRole].
@ProviderFor(hubRole)
const hubRoleProvider = HubRoleFamily();

/// Returns UserRole.admin if user is the hub creator or has manager/moderator role
/// Returns UserRole.member if user is a member of the hub
/// Returns UserRole.none if user is not a member
///
/// Copied from [hubRole].
class HubRoleFamily extends Family<AsyncValue<UserRole>> {
  /// Returns UserRole.admin if user is the hub creator or has manager/moderator role
  /// Returns UserRole.member if user is a member of the hub
  /// Returns UserRole.none if user is not a member
  ///
  /// Copied from [hubRole].
  const HubRoleFamily();

  /// Returns UserRole.admin if user is the hub creator or has manager/moderator role
  /// Returns UserRole.member if user is a member of the hub
  /// Returns UserRole.none if user is not a member
  ///
  /// Copied from [hubRole].
  HubRoleProvider call(
    String hubId,
  ) {
    return HubRoleProvider(
      hubId,
    );
  }

  @override
  HubRoleProvider getProviderOverride(
    covariant HubRoleProvider provider,
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
  String? get name => r'hubRoleProvider';
}

/// Returns UserRole.admin if user is the hub creator or has manager/moderator role
/// Returns UserRole.member if user is a member of the hub
/// Returns UserRole.none if user is not a member
///
/// Copied from [hubRole].
class HubRoleProvider extends AutoDisposeFutureProvider<UserRole> {
  /// Returns UserRole.admin if user is the hub creator or has manager/moderator role
  /// Returns UserRole.member if user is a member of the hub
  /// Returns UserRole.none if user is not a member
  ///
  /// Copied from [hubRole].
  HubRoleProvider(
    String hubId,
  ) : this._internal(
          (ref) => hubRole(
            ref as HubRoleRef,
            hubId,
          ),
          from: hubRoleProvider,
          name: r'hubRoleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$hubRoleHash,
          dependencies: HubRoleFamily._dependencies,
          allTransitiveDependencies: HubRoleFamily._allTransitiveDependencies,
          hubId: hubId,
        );

  HubRoleProvider._internal(
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
  Override overrideWith(
    FutureOr<UserRole> Function(HubRoleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HubRoleProvider._internal(
        (ref) => create(ref as HubRoleRef),
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
  AutoDisposeFutureProviderElement<UserRole> createElement() {
    return _HubRoleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HubRoleProvider && other.hubId == hubId;
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
mixin HubRoleRef on AutoDisposeFutureProviderRef<UserRole> {
  /// The parameter `hubId` of this provider.
  String get hubId;
}

class _HubRoleProviderElement extends AutoDisposeFutureProviderElement<UserRole>
    with HubRoleRef {
  _HubRoleProviderElement(super.provider);

  @override
  String get hubId => (origin as HubRoleProvider).hubId;
}

String _$adminTasksHash() => r'bdc0343ee8f698a35f1b1edc8e90c779055c174e';

/// Admin tasks count stream provider
///
/// Refactored to delegate to AdminTaskService for business logic.
/// This provider now only handles state management and streaming.
///
/// Copied from [adminTasks].
@ProviderFor(adminTasks)
final adminTasksProvider = AutoDisposeStreamProvider<int>.internal(
  adminTasks,
  name: r'adminTasksProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adminTasksHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminTasksRef = AutoDisposeStreamProviderRef<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
