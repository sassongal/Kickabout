import 'package:flutter/foundation.dart';

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
  
  // Cache configuration
  static const Duration defaultTtl = Duration(minutes: 5);
  static const Duration gamesTtl = Duration(minutes: 10);
  static const Duration eventsTtl = Duration(minutes: 15);
  static const Duration usersTtl = Duration(hours: 1);
  static const int maxMemoryCacheSize = 100; // Max items in memory cache

  /// Get cached data
  T? get<T>(String key) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      _memoryCache.remove(key);
      return null;
    }
    return entry.data as T;
  }

  /// Set cached data
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiration = DateTime.now().add(ttl ?? defaultTtl);
    _memoryCache[key] = _CacheEntry(data, expiration);

    // Evict oldest entries if cache is too large
    if (_memoryCache.length > maxMemoryCacheSize) {
      _evictOldest();
    }
  }

  /// Get or fetch data with caching
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetch, {
    Duration? ttl,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = get<T>(key);
      if (cached != null) {
        debugPrint('📦 Cache hit: $key');
        return cached;
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
      rethrow;
    }
  }

  /// Clear specific cache entry
  void clear(String key) {
    _memoryCache.remove(key);
  }

  /// Clear all cache
  void clearAll() {
    _memoryCache.clear();
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

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final total = _memoryCache.length;
    final expired = _memoryCache.values.where((e) => e.isExpired).length;
    final active = total - expired;

    return {
      'total': total,
      'active': active,
      'expired': expired,
      'maxSize': maxMemoryCacheSize,
    };
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

