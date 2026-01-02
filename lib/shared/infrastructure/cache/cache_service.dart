import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kattrick/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';

/// Cache entry with expiration
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'data': data,
        'expiresAt': expiresAt.toIso8601String(),
      };
}

/// Generic cache service for in-memory and persistent caching
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // In-memory cache
  final Map<String, _CacheEntry<dynamic>> _memoryCache = {};

  // Persistent cache (SharedPreferences)
  SharedPreferences? _prefs;
  bool _prefsInitialized = false;

  // OPTIMIZATION: Request deduplication - prevents multiple concurrent fetches for same key
  final Map<String, Future<dynamic>> _pendingRequests = {};

  // Cache analytics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _persistentCacheHits = 0;
  int _persistentCacheMisses = 0;
  int _deduplicatedRequests = 0;

  // Cache configuration
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration gamesTtl = Duration(minutes: 10);
  static const Duration eventsTtl = Duration(minutes: 15);
  static const Duration usersTtl = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100; // Max items in memory cache
  static const int maxPersistentCacheSize =
      50; // Max items in persistent cache (critical data only)

  // Keys that should be persisted (critical data)
  static const Set<String> _persistentKeys = {
    'user:',
    'hub:',
  };

  /// Initialize persistent cache
  Future<void> _initPrefs() async {
    if (_prefsInitialized) return;
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsInitialized = true;
      debugPrint('✅ Persistent cache initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize persistent cache: $e');
    }
  }

  /// Get cached data (checks memory first only - persistent cache is async)
  /// Note: Persistent cache is not checked synchronously to avoid blocking main thread
  T? get<T>(String key) {
    // Check memory cache only (synchronous)
    final entry = _memoryCache[key];
    if (entry != null && !entry.isExpired) {
      _cacheHits++;
      return entry.data as T;
    }

    if (entry != null && entry.isExpired) {
      _memoryCache.remove(key);
    }

    // Don't check persistent cache synchronously - it would block the main thread
    // Persistent cache will be loaded asynchronously when needed
    _cacheMisses++;
    return null;
  }

  /// Get from persistent cache
  /// Supports User and Hub objects with proper deserialization
  T? _getFromPersistent<T>(String key) {
    if (!_prefsInitialized) return null;
    try {
      final jsonStr = _prefs?.getString(key);
      if (jsonStr == null) {
        _persistentCacheMisses++;
        return null;
      }

      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(data['expiresAt'] as String);

      if (DateTime.now().isAfter(expiresAt)) {
        _prefs?.remove(key);
        _persistentCacheMisses++;
        return null;
      }

      _persistentCacheHits++;

      // Handle complex objects (User, Hub) with proper deserialization
      final rawData = data['data'];
      if (rawData is Map<String, dynamic> || rawData is Map) {
        try {
          // Convert JSON back to Firestore types (GeoPoint, Timestamp)
          final convertedData = _convertJsonToTimestamps(rawData);

          // FIX: Ensure convertedData is Map<String, dynamic>
          if (convertedData is! Map<String, dynamic>) {
            debugPrint(
                '⚠️ Converted data is not Map<String, dynamic>, skipping cache entry: $key');
            // Clear corrupted cache entry
            _prefs?.remove(key);
            return null;
          }

          // Try to deserialize based on key prefix
          if (key.startsWith('user:')) {
            try {
              return User.fromJson(convertedData) as T?;
            } catch (e, stackTrace) {
              debugPrint(
                  '⚠️ Error deserializing User from persistent cache: $e');
              debugPrint('Stack trace: $stackTrace');
              // Clear corrupted cache entry
              _prefs?.remove(key);
              return null;
            }
          } else if (key.startsWith('hub:')) {
            try {
              return Hub.fromJson(convertedData) as T?;
            } catch (e, stackTrace) {
              debugPrint(
                  '⚠️ Error deserializing Hub from persistent cache: $e');
              debugPrint('Stack trace: $stackTrace');
              // Clear corrupted cache entry
              _prefs?.remove(key);
              return null;
            }
          }
        } catch (e, stackTrace) {
          debugPrint(
              '⚠️ Error converting JSON to timestamps for cache entry $key: $e');
          debugPrint('Stack trace: $stackTrace');
          // Clear corrupted cache entry
          _prefs?.remove(key);
          return null;
        }
      }

      // Fallback for simple types
      return rawData as T?;
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error reading from persistent cache: $e');
      debugPrint('Stack trace: $stackTrace');
      // Clear corrupted cache entry if possible
      try {
        _prefs?.remove(key);
      } catch (_) {
        // Ignore errors during cleanup
      }
      _persistentCacheMisses++;
      return null;
    }
  }

  /// Check if key should be persisted
  bool _shouldPersist(String key) {
    return _persistentKeys.any((prefix) => key.startsWith(prefix));
  }

  /// Set cached data (saves to memory and persistent cache if applicable)
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiration = DateTime.now().add(ttl ?? defaultTtl);
    _memoryCache[key] = _CacheEntry(data, expiration);

    // Save to persistent cache for critical data
    if (_shouldPersist(key)) {
      _saveToPersistent(key, data, expiration);
    }

    // Evict oldest entries if cache is too large
    if (_memoryCache.length > maxMemoryCacheSize) {
      _evictOldest();
    }
  }

  /// Save to persistent cache (async, non-blocking)
  /// Supports User and Hub objects with proper serialization
  Future<void> _saveToPersistent<T>(
      String key, T data, DateTime expiration) async {
    // Don't block - run in background
    Future.microtask(() async {
      await _initPrefs();
      if (!_prefsInitialized) return;

      try {
        dynamic serializedData;

        // Handle complex objects (User, Hub) with proper serialization
        if (data is User) {
          serializedData = _convertTimestampsToJson(data.toJson());
        } else if (data is Hub) {
          serializedData = _convertTimestampsToJson(data.toJson());
        } else if (data is Map ||
            data is List ||
            data is String ||
            data is num ||
            data is bool) {
          // Simple types can be serialized directly
          serializedData = data;
        } else {
          // For other types, try toJson if available
          try {
            final jsonData = (data as dynamic).toJson();
            serializedData =
                jsonData is Map ? _convertTimestampsToJson(jsonData) : jsonData;
          } catch (e) {
            debugPrint(
                '⚠️ Cannot serialize ${data.runtimeType} to persistent cache');
            return; // Skip saving if can't serialize
          }
        }

        final entry = {
          'data': serializedData,
          'expiresAt': expiration.toIso8601String(),
        };

        await _prefs?.setString(key, jsonEncode(entry));

        // Evict oldest persistent entries if needed (also async, non-blocking)
        _evictOldestPersistent();
      } catch (e) {
        debugPrint('⚠️ Error saving to persistent cache: $e');
      }
    });
  }

  /// Evict oldest persistent cache entries (async, non-blocking)
  void _evictOldestPersistent() {
    if (!_prefsInitialized) return;

    // Run in background to avoid blocking main thread
    Future.microtask(() async {
      try {
        final keys = _prefs!.getKeys().where((k) => _shouldPersist(k)).toList();
        if (keys.length <= maxPersistentCacheSize) return;

        // Get expiration times and sort
        final entries = <MapEntry<String, DateTime>>[];
        for (final key in keys) {
          final jsonStr = _prefs!.getString(key);
          if (jsonStr != null) {
            try {
              final data = jsonDecode(jsonStr) as Map<String, dynamic>;
              final expiresAt = DateTime.parse(data['expiresAt'] as String);
              entries.add(MapEntry(key, expiresAt));
            } catch (e) {
              // Invalid entry, remove it
              await _prefs!.remove(key);
            }
          }
        }

        // Sort by expiration and remove oldest 10%
        entries.sort((a, b) => a.value.compareTo(b.value));
        final toRemove = (entries.length * 0.1).ceil();
        for (int i = 0; i < toRemove && i < entries.length; i++) {
          await _prefs!.remove(entries[i].key);
        }
      } catch (e) {
        debugPrint('⚠️ Error evicting persistent cache: $e');
      }
    });
  }

  /// Get or fetch data with caching (checks memory, then persistent async, then fetches)
  /// OPTIMIZED: Deduplicates concurrent requests for the same key
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      // Check memory cache first (synchronous)
      final cached = get<T>(key);
      if (cached != null) {
        debugPrint('📦 Cache hit (memory): $key');
        return cached;
      }

      // Check persistent cache asynchronously (non-blocking)
      if (_shouldPersist(key)) {
        await _initPrefs();
        if (_prefsInitialized) {
          final persistent = _getFromPersistent<T>(key);
          if (persistent != null) {
            debugPrint('📦 Cache hit (persistent): $key');
            // Also update memory cache
            set(key, persistent, ttl: ttl);
            return persistent;
          }
        }
      }

      // OPTIMIZATION: Check if already fetching this key
      if (_pendingRequests.containsKey(key)) {
        _deduplicatedRequests++;
        debugPrint('🔄 Request deduplicated: $key (reusing pending fetch)');
        return await _pendingRequests[key] as T;
      }
    }

    debugPrint('🌐 Cache miss: $key - fetching...');

    // Create and store the fetch promise
    final fetchFuture = _executeFetch<T>(key, fetch, ttl);
    _pendingRequests[key] = fetchFuture;

    try {
      final result = await fetchFuture;
      return result;
    } finally {
      // Always clean up pending request, even on error
      _pendingRequests.remove(key);
    }
  }

  /// Execute fetch and handle errors with fallback to expired cache
  Future<T> _executeFetch<T>(
    String key,
    Future<T> Function() fetch,
    Duration? ttl,
  ) async {
    try {
      final data = await fetch();
      set(key, data, ttl: ttl);
      return data;
    } catch (e) {
      // On error, try to return cached data even if expired
      final expired = _memoryCache[key];
      if (expired != null) {
        debugPrint('⚠️ Using expired cache for $key due to error');
        return expired.data as T;
      }

      // Try persistent cache as last resort (async, but we're already in error state)
      if (_shouldPersist(key)) {
        await _initPrefs();
        if (_prefsInitialized) {
          final persistent = _getFromPersistent<T>(key);
          if (persistent != null) {
            debugPrint('⚠️ Using persistent cache for $key due to error');
            return persistent;
          }
        }
      }

      rethrow;
    }
  }

  /// Clear specific cache entry (memory and persistent)
  void clear(String key) {
    _memoryCache.remove(key);
    if (_prefsInitialized) {
      _prefs?.remove(key);
    }
  }

  /// Clear all cache (memory and persistent)
  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_prefsInitialized) {
      final keys = _prefs!.getKeys().where((k) => _shouldPersist(k)).toList();
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
    debugPrint('🗑️ Cache cleared');
  }

  /// Clear expired entries
  void clearExpired() {
    _memoryCache.removeWhere((key, entry) => entry.isExpired);
  }

  /// Evict oldest entries
  void _evictOldest() {
    if (_memoryCache.isEmpty) return;

    // Sort by expiration time and remove oldest 10%
    final sorted = _memoryCache.entries.toList()
      ..sort((a, b) => a.value.expiresAt.compareTo(b.value.expiresAt));

    final toRemove = (sorted.length * 0.1).ceil();
    for (int i = 0; i < toRemove && i < sorted.length; i++) {
      _memoryCache.remove(sorted[i].key);
    }
  }

  /// Get cache statistics including analytics
  Map<String, dynamic> getStats() {
    final total = _memoryCache.length;
    final expired = _memoryCache.values.where((e) => e.isExpired).length;
    final active = total - expired;

    final totalRequests = _cacheHits + _cacheMisses;
    final hitRate =
        totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;

    final persistentTotal = _persistentCacheHits + _persistentCacheMisses;
    final persistentHitRate = persistentTotal > 0
        ? (_persistentCacheHits / persistentTotal * 100)
        : 0.0;

    return {
      'memory': {
        'total': total,
        'active': active,
        'expired': expired,
        'maxSize': maxMemoryCacheSize,
        'pendingRequests': _pendingRequests.length,
      },
      'analytics': {
        'hits': _cacheHits,
        'misses': _cacheMisses,
        'hitRate': '${hitRate.toStringAsFixed(2)}%',
        'totalRequests': totalRequests,
        'deduplicatedRequests': _deduplicatedRequests,
      },
      'persistent': {
        'hits': _persistentCacheHits,
        'misses': _persistentCacheMisses,
        'hitRate': '${persistentHitRate.toStringAsFixed(2)}%',
        'initialized': _prefsInitialized,
      },
    };
  }

  /// Reset analytics counters
  void resetAnalytics() {
    _cacheHits = 0;
    _cacheMisses = 0;
    _persistentCacheHits = 0;
    _persistentCacheMisses = 0;
    _deduplicatedRequests = 0;
  }

  /// Convert Timestamp and GeoPoint objects to JSON-serializable format
  /// Recursively converts all Timestamp and GeoPoint objects in a Map
  dynamic _convertTimestampsToJson(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is GeoPoint) {
      // Convert GeoPoint to Map for JSON serialization
      return {
        'latitude': data.latitude,
        'longitude': data.longitude,
      };
    } else if (data is UserLocation) {
      return _convertTimestampsToJson(data.toJson());
    } else if (data is PrivacySettings) {
      return _convertTimestampsToJson(data.toJson());
    } else if (data is NotificationPreferences) {
      return _convertTimestampsToJson(data.toJson());
    } else if (data is GeographicPoint) {
      return _convertTimestampsToJson(data.toJson());
    } else if (data is Map) {
      return data
          .map((key, value) => MapEntry(key, _convertTimestampsToJson(value)));
    } else if (data is List) {
      return data.map((item) => _convertTimestampsToJson(item)).toList();
    } else {
      return data;
    }
  }

  /// Convert JSON-serializable format back to Timestamp and GeoPoint objects
  /// Recursively converts all serialized Timestamp and GeoPoint objects
  dynamic _convertJsonToTimestamps(dynamic data) {
    if (data is Map) {
      // Check if it's a GeoPoint (has latitude and longitude, and only 2 keys)
      if (data.containsKey('latitude') &&
          data.containsKey('longitude') &&
          data.length == 2 &&
          data['latitude'] is num &&
          data['longitude'] is num) {
        return GeoPoint(
          (data['latitude'] as num).toDouble(),
          (data['longitude'] as num).toDouble(),
        );
      }
      // FIX: Convert to Map<String, dynamic> explicitly to avoid type errors
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final stringKey = key is String ? key : key.toString();
        result[stringKey] = _convertJsonToTimestamps(value);
      });
      return result;
    } else if (data is List) {
      return data.map((item) => _convertJsonToTimestamps(item)).toList();
    } else if (data is String) {
      // Try to parse as ISO8601 timestamp
      try {
        final dateTime = DateTime.parse(data);
        return Timestamp.fromDate(dateTime);
      } catch (e) {
        return data; // Not a timestamp, return as-is
      }
    } else {
      return data;
    }
  }
}

/// Cache keys for different data types
class CacheKeys {
  static String game(String gameId) => 'game:$gameId';
  static String gamesByHub(String hubId) => 'games:hub:$hubId';
  static String publicGames({String? region, String? city}) {
    if (region != null && city != null) {
      return 'games:public:region:$region:city:$city';
    }
    if (region != null) {
      return 'games:public:region:$region';
    }
    if (city != null) {
      return 'games:public:city:$city';
    }
    return 'games:public';
  }

  static String event(String hubId, String eventId) => 'event:$hubId:$eventId';
  static String eventsByHub(String hubId) => 'events:hub:$hubId';
  static String publicEvents({String? region}) =>
      region != null ? 'events:public:region:$region' : 'events:public';
  static String user(String userId) => 'user:$userId';
  static String hub(String hubId) => 'hub:$hubId';
  static String venue(String venueId) => 'venue:$venueId';
}
