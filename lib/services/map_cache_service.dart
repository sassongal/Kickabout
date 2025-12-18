import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Service for caching map-related data to reduce API calls and improve performance
/// 
/// Features:
/// - In-memory cache for map tiles
/// - Cache for venue locations
/// - Cache for hub locations
/// - Automatic cache expiration
class MapCacheService {
  static final MapCacheService _instance = MapCacheService._internal();
  factory MapCacheService() => _instance;
  MapCacheService._internal();

  // Cache for map tiles (key: "lat_lng_zoom", value: tile data)
  final Map<String, _CacheEntry<Uint8List>> _tileCache = {};
  
  // Cache for venue locations (key: venueId, value: location data)
  final Map<String, _CacheEntry<Map<String, dynamic>>> _venueCache = {};
  
  // Cache for hub locations (key: hubId, value: location data)
  final Map<String, _CacheEntry<Map<String, dynamic>>> _hubCache = {};

  // Cache limits
  static const int MAX_TILE_CACHE_SIZE = 200; // Keep 200 tiles in memory
  static const int MAX_VENUE_CACHE_SIZE = 500; // Keep 500 venues
  static const int MAX_HUB_CACHE_SIZE = 300; // Keep 300 hubs
  
  // Cache TTL (Time To Live)
  static const Duration TILE_CACHE_TTL = Duration(hours: 24); // Tiles don't change often
  static const Duration VENUE_CACHE_TTL = Duration(hours: 1); // Venues change occasionally
  static const Duration HUB_CACHE_TTL = Duration(minutes: 30); // Hubs change more frequently

  /// Get cached tile or null if not cached/expired
  Uint8List? getTile(double lat, double lng, int zoom) {
    final key = _getTileKey(lat, lng, zoom);
    final entry = _tileCache[key];
    
    if (entry == null || entry.isExpired) {
      _tileCache.remove(key);
      return null;
    }
    
    return entry.data;
  }

  /// Cache a tile
  void cacheTile(double lat, double lng, int zoom, Uint8List tileData) {
    final key = _getTileKey(lat, lng, zoom);
    
    // Clean up if cache is full
    if (_tileCache.length >= MAX_TILE_CACHE_SIZE) {
      _cleanupExpiredEntries(_tileCache);
      if (_tileCache.length >= MAX_TILE_CACHE_SIZE) {
        // Remove oldest entry
        final oldestKey = _tileCache.keys.first;
        _tileCache.remove(oldestKey);
      }
    }
    
    _tileCache[key] = _CacheEntry(tileData, TILE_CACHE_TTL);
  }

  /// Get cached venue location or null
  Map<String, dynamic>? getVenueLocation(String venueId) {
    final entry = _venueCache[venueId];
    
    if (entry == null || entry.isExpired) {
      _venueCache.remove(venueId);
      return null;
    }
    
    return entry.data;
  }

  /// Cache venue location
  void cacheVenueLocation(String venueId, Map<String, dynamic> locationData) {
    // Clean up if cache is full
    if (_venueCache.length >= MAX_VENUE_CACHE_SIZE) {
      _cleanupExpiredEntries(_venueCache);
      if (_venueCache.length >= MAX_VENUE_CACHE_SIZE) {
        final oldestKey = _venueCache.keys.first;
        _venueCache.remove(oldestKey);
      }
    }
    
    _venueCache[venueId] = _CacheEntry(locationData, VENUE_CACHE_TTL);
  }

  /// Get cached hub location or null
  Map<String, dynamic>? getHubLocation(String hubId) {
    final entry = _hubCache[hubId];
    
    if (entry == null || entry.isExpired) {
      _hubCache.remove(hubId);
      return null;
    }
    
    return entry.data;
  }

  /// Cache hub location
  void cacheHubLocation(String hubId, Map<String, dynamic> locationData) {
    // Clean up if cache is full
    if (_hubCache.length >= MAX_HUB_CACHE_SIZE) {
      _cleanupExpiredEntries(_hubCache);
      if (_hubCache.length >= MAX_HUB_CACHE_SIZE) {
        final oldestKey = _hubCache.keys.first;
        _hubCache.remove(oldestKey);
      }
    }
    
    _hubCache[hubId] = _CacheEntry(locationData, HUB_CACHE_TTL);
  }

  /// Clear all caches
  void clearAll() {
    _tileCache.clear();
    _venueCache.clear();
    _hubCache.clear();
  }

  /// Clear expired entries from a cache
  void _cleanupExpiredEntries<T>(Map<String, _CacheEntry<T>> cache) {
    final expiredKeys = cache.entries
        .where((e) => e.value.isExpired)
        .map((e) => e.key)
        .toList();
    
    for (final key in expiredKeys) {
      cache.remove(key);
    }
  }

  /// Generate tile cache key
  String _getTileKey(double lat, double lng, int zoom) {
    // Round to 4 decimal places (~11 meters precision) to increase cache hits
    final roundedLat = (lat * 10000).round() / 10000;
    final roundedLng = (lng * 10000).round() / 10000;
    return '${roundedLat}_${roundedLng}_$zoom';
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    return {
      'tiles': {
        'count': _tileCache.length,
        'expired': _tileCache.values.where((e) => e.isExpired).length,
      },
      'venues': {
        'count': _venueCache.length,
        'expired': _venueCache.values.where((e) => e.isExpired).length,
      },
      'hubs': {
        'count': _hubCache.length,
        'expired': _hubCache.values.where((e) => e.isExpired).length,
      },
    };
  }
}

/// Cache entry with expiration
class _CacheEntry<T> {
  final T data;
  final DateTime expiresAt;

  _CacheEntry(this.data, Duration ttl)
      : expiresAt = DateTime.now().add(ttl);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

