import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:kickadoor/models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  
  // Cache analytics
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _persistentCacheHits = 0;
  int _persistentCacheMisses = 0;
  
  // Cache configuration
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration gamesTtl = Duration(minutes: 10);
  static const Duration eventsTtl = Duration(minutes: 15);
  static const Duration usersTtl = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100; // Max items in memory cache
  static const int maxPersistentCacheSize = 50; // Max items in persistent cache (critical data only)
  
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
      if (rawData is Map<String, dynamic>) {
        // Try to deserialize based on key prefix
        if (key.startsWith('user:')) {
          try {
            return User.fromJson(rawData) as T?;
          } catch (e) {
            debugPrint('⚠️ Error deserializing User from persistent cache: $e');
            return null;
          }
        } else if (key.startsWith('hub:')) {
          try {
            return Hub.fromJson(rawData) as T?;
          } catch (e) {
            debugPrint('⚠️ Error deserializing Hub from persistent cache: $e');
            return null;
          }
        }
      }
      
      // Fallback for simple types
      return rawData as T?;
    } catch (e) {
      debugPrint('⚠️ Error reading from persistent cache: $e');
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
  Future<void> _saveToPersistent<T>(String key, T data, DateTime expiration) async {
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
        } else if (data is Map || data is List || data is String || data is num || data is bool) {
          // Simple types can be serialized directly
          serializedData = data;
        } else {
          // For other types, try toJson if available
          try {
            final jsonData = (data as dynamic).toJson();
            serializedData = jsonData is Map ? _convertTimestampsToJson(jsonData) : jsonData;
          } catch (e) {
            debugPrint('⚠️ Cannot serialize ${data.runtimeType} to persistent cache');
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
    }

    debugPrint('🌐 Cache miss: $key - fetching...');
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
    final hitRate = totalRequests > 0 ? (_cacheHits / totalRequests * 100) : 0.0;
    
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
      },
      'analytics': {
        'hits': _cacheHits,
        'misses': _cacheMisses,
        'hitRate': '${hitRate.toStringAsFixed(2)}%',
        'totalRequests': totalRequests,
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
  }

  /// Convert Timestamp objects to JSON-serializable format
  /// Recursively converts all Timestamp objects in a Map to ISO8601 strings
  dynamic _convertTimestampsToJson(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _convertTimestampsToJson(value)));
    } else if (data is List) {
      return data.map((item) => _convertTimestampsToJson(item)).toList();
    } else {
      return data;
    }
  }
}

/// Cache keys for different data types
class CacheKeys {
  static String game(String gameId) => 'game:$gameId';
  static String gamesByHub(String hubId) => 'games:hub:$hubId';
  static String publicGames({String? region}) => region != null 
      ? 'games:public:region:$region' 
      : 'games:public';
  static String event(String hubId, String eventId) => 'event:$hubId:$eventId';
  static String eventsByHub(String hubId) => 'events:hub:$hubId';
  static String publicEvents({String? region}) => region != null
      ? 'events:public:region:$region'
      : 'events:public';
  static String user(String userId) => 'user:$userId';
  static String hub(String hubId) => 'hub:$hubId';
  static String venue(String venueId) => 'venue:$venueId';
}

