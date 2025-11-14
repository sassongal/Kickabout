import 'package:kickadoor/config/env.dart';
// Conditional import for Remote Config (not available on web)
import 'package:firebase_remote_config/firebase_remote_config.dart'
    if (dart.library.html) 'package:kickadoor/services/remote_config_service_stub.dart';

/// Service for Firebase Remote Config
class RemoteConfigService {
  static RemoteConfigService? _instance;
  dynamic _remoteConfig;

  RemoteConfigService._();

  factory RemoteConfigService() {
    _instance ??= RemoteConfigService._();
    return _instance!;
  }

  /// Initialize Remote Config
  Future<void> initialize() async {
    if (!Env.isFirebaseAvailable) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values
      await _remoteConfig!.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await _remoteConfig!.setDefaults({
        'venue_search_radius_default': 5000,
        'venue_search_radius_max': 10000,
        'hub_search_radius_default': 5.0,
        'enable_venue_rental_search': true,
        'venue_cache_ttl_seconds': 300,
        'api_rate_limit_seconds': 2,
        'enable_smart_recommendations': false,
        'geohash_precision': 7,
      });

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();
    } catch (e) {
      // Remote Config not available, use defaults
      print('Remote Config initialization failed: $e');
    }
  }

  /// Get default venue search radius in meters
  int get venueSearchRadiusDefault {
    return _remoteConfig?.getInt('venue_search_radius_default') ?? 5000;
  }

  /// Get maximum venue search radius in meters
  int get venueSearchRadiusMax {
    return _remoteConfig?.getInt('venue_search_radius_max') ?? 10000;
  }

  /// Get default hub search radius in kilometers
  double get hubSearchRadiusDefault {
    return _remoteConfig?.getDouble('hub_search_radius_default') ?? 5.0;
  }

  /// Check if rental venue search is enabled
  bool get enableVenueRentalSearch {
    return _remoteConfig?.getBool('enable_venue_rental_search') ?? true;
  }

  /// Get venue cache TTL in seconds
  int get venueCacheTtlSeconds {
    return _remoteConfig?.getInt('venue_cache_ttl_seconds') ?? 300;
  }

  /// Get API rate limit in seconds
  int get apiRateLimitSeconds {
    return _remoteConfig?.getInt('api_rate_limit_seconds') ?? 2;
  }

  /// Check if smart recommendations are enabled
  bool get enableSmartRecommendations {
    return _remoteConfig?.getBool('enable_smart_recommendations') ?? false;
  }

  /// Get geohash precision
  int get geohashPrecision {
    return _remoteConfig?.getInt('geohash_precision') ?? 7;
  }

  /// Fetch latest config (call periodically)
  Future<void> fetch() async {
    if (_remoteConfig == null || !Env.isFirebaseAvailable) return;
    
    try {
      await _remoteConfig!.fetch();
      await _remoteConfig!.activate();
    } catch (e) {
      print('Failed to fetch Remote Config: $e');
    }
  }
}

