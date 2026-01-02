// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$weatherDataHash() => r'159a91a5abd88d7e5fa1234cc26dba6bf2118cd5';

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

abstract class _$WeatherData
    extends BuildlessAutoDisposeAsyncNotifier<Map<String, dynamic>?> {
  late final double lat;
  late final double lon;

  FutureOr<Map<String, dynamic>?> build(
    double lat,
    double lon,
  );
}

/// Weather data provider with 15-minute caching
/// Reduces API calls by ~80% while keeping data fresh
///
/// Copied from [WeatherData].
@ProviderFor(WeatherData)
const weatherDataProvider = WeatherDataFamily();

/// Weather data provider with 15-minute caching
/// Reduces API calls by ~80% while keeping data fresh
///
/// Copied from [WeatherData].
class WeatherDataFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// Weather data provider with 15-minute caching
  /// Reduces API calls by ~80% while keeping data fresh
  ///
  /// Copied from [WeatherData].
  const WeatherDataFamily();

  /// Weather data provider with 15-minute caching
  /// Reduces API calls by ~80% while keeping data fresh
  ///
  /// Copied from [WeatherData].
  WeatherDataProvider call(
    double lat,
    double lon,
  ) {
    return WeatherDataProvider(
      lat,
      lon,
    );
  }

  @override
  WeatherDataProvider getProviderOverride(
    covariant WeatherDataProvider provider,
  ) {
    return call(
      provider.lat,
      provider.lon,
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
  String? get name => r'weatherDataProvider';
}

/// Weather data provider with 15-minute caching
/// Reduces API calls by ~80% while keeping data fresh
///
/// Copied from [WeatherData].
class WeatherDataProvider extends AutoDisposeAsyncNotifierProviderImpl<
    WeatherData, Map<String, dynamic>?> {
  /// Weather data provider with 15-minute caching
  /// Reduces API calls by ~80% while keeping data fresh
  ///
  /// Copied from [WeatherData].
  WeatherDataProvider(
    double lat,
    double lon,
  ) : this._internal(
          () => WeatherData()
            ..lat = lat
            ..lon = lon,
          from: weatherDataProvider,
          name: r'weatherDataProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$weatherDataHash,
          dependencies: WeatherDataFamily._dependencies,
          allTransitiveDependencies:
              WeatherDataFamily._allTransitiveDependencies,
          lat: lat,
          lon: lon,
        );

  WeatherDataProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.lat,
    required this.lon,
  }) : super.internal();

  final double lat;
  final double lon;

  @override
  FutureOr<Map<String, dynamic>?> runNotifierBuild(
    covariant WeatherData notifier,
  ) {
    return notifier.build(
      lat,
      lon,
    );
  }

  @override
  Override overrideWith(WeatherData Function() create) {
    return ProviderOverride(
      origin: this,
      override: WeatherDataProvider._internal(
        () => create()
          ..lat = lat
          ..lon = lon,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        lat: lat,
        lon: lon,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<WeatherData, Map<String, dynamic>?>
      createElement() {
    return _WeatherDataProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WeatherDataProvider && other.lat == lat && other.lon == lon;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, lat.hashCode);
    hash = _SystemHash.combine(hash, lon.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WeatherDataRef
    on AutoDisposeAsyncNotifierProviderRef<Map<String, dynamic>?> {
  /// The parameter `lat` of this provider.
  double get lat;

  /// The parameter `lon` of this provider.
  double get lon;
}

class _WeatherDataProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<WeatherData,
        Map<String, dynamic>?> with WeatherDataRef {
  _WeatherDataProviderElement(super.provider);

  @override
  double get lat => (origin as WeatherDataProvider).lat;
  @override
  double get lon => (origin as WeatherDataProvider).lon;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
