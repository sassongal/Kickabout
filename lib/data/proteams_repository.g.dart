// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proteams_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$proTeamsRepositoryHash() =>
    r'5d8f65f968fd06a8d452fa3cbf2be625c5d7cf00';

/// Provider for ProTeamsRepository
///
/// Copied from [proTeamsRepository].
@ProviderFor(proTeamsRepository)
final proTeamsRepositoryProvider =
    AutoDisposeProvider<ProTeamsRepository>.internal(
  proTeamsRepository,
  name: r'proTeamsRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$proTeamsRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProTeamsRepositoryRef = AutoDisposeProviderRef<ProTeamsRepository>;
String _$allProTeamsHash() => r'aa3f12dae8acf8eb66747b3c27315de0d6df93ac';

/// Provider to get all teams
///
/// Copied from [allProTeams].
@ProviderFor(allProTeams)
final allProTeamsProvider = AutoDisposeFutureProvider<List<ProTeam>>.internal(
  allProTeams,
  name: r'allProTeamsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$allProTeamsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AllProTeamsRef = AutoDisposeFutureProviderRef<List<ProTeam>>;
String _$proTeamHash() => r'8d82b257332bdc09f878e2a3635606ab65963d30';

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

/// Provider to get a specific team
///
/// Copied from [proTeam].
@ProviderFor(proTeam)
const proTeamProvider = ProTeamFamily();

/// Provider to get a specific team
///
/// Copied from [proTeam].
class ProTeamFamily extends Family<AsyncValue<ProTeam?>> {
  /// Provider to get a specific team
  ///
  /// Copied from [proTeam].
  const ProTeamFamily();

  /// Provider to get a specific team
  ///
  /// Copied from [proTeam].
  ProTeamProvider call(
    String teamId,
  ) {
    return ProTeamProvider(
      teamId,
    );
  }

  @override
  ProTeamProvider getProviderOverride(
    covariant ProTeamProvider provider,
  ) {
    return call(
      provider.teamId,
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
  String? get name => r'proTeamProvider';
}

/// Provider to get a specific team
///
/// Copied from [proTeam].
class ProTeamProvider extends AutoDisposeFutureProvider<ProTeam?> {
  /// Provider to get a specific team
  ///
  /// Copied from [proTeam].
  ProTeamProvider(
    String teamId,
  ) : this._internal(
          (ref) => proTeam(
            ref as ProTeamRef,
            teamId,
          ),
          from: proTeamProvider,
          name: r'proTeamProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$proTeamHash,
          dependencies: ProTeamFamily._dependencies,
          allTransitiveDependencies: ProTeamFamily._allTransitiveDependencies,
          teamId: teamId,
        );

  ProTeamProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teamId,
  }) : super.internal();

  final String teamId;

  @override
  Override overrideWith(
    FutureOr<ProTeam?> Function(ProTeamRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProTeamProvider._internal(
        (ref) => create(ref as ProTeamRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teamId: teamId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ProTeam?> createElement() {
    return _ProTeamProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProTeamProvider && other.teamId == teamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProTeamRef on AutoDisposeFutureProviderRef<ProTeam?> {
  /// The parameter `teamId` of this provider.
  String get teamId;
}

class _ProTeamProviderElement extends AutoDisposeFutureProviderElement<ProTeam?>
    with ProTeamRef {
  _ProTeamProviderElement(super.provider);

  @override
  String get teamId => (origin as ProTeamProvider).teamId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
