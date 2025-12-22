import 'package:kattrick/services/cache_service.dart';

/// Centralized cache invalidation service
///
/// This service provides a single place to manage cache invalidation logic.
/// Instead of scattering cache.clear() calls throughout repositories,
/// use these methods to ensure all related caches are properly invalidated.
///
/// Benefits:
/// - Prevents bugs from forgetting to clear related caches
/// - Makes cache dependencies explicit and documented
/// - Easier to debug cache issues
/// - Centralized logging for cache invalidation
///
/// Example:
/// ```dart
/// // Instead of:
/// CacheService().clear(CacheKeys.game(gameId));
/// CacheService().clear(CacheKeys.gamesByHub(hubId));
///
/// // Use:
/// CacheInvalidationService().onGameUpdated(gameId, hubId: hubId);
/// ```
class CacheInvalidationService {
  final CacheService _cache;

  CacheInvalidationService({CacheService? cache})
      : _cache = cache ?? CacheService();

  /// Invalidate caches when a game is created
  void onGameCreated(String gameId, {String? hubId}) {
    _cache.clear(CacheKeys.game(gameId));

    if (hubId != null && hubId.isNotEmpty) {
      _cache.clear(CacheKeys.gamesByHub(hubId));
      _cache.clear(CacheKeys.hub(hubId)); // Hub gameCount may change
    }

    _cache.clear(CacheKeys.publicGames());
  }

  /// Invalidate caches when a game is updated
  void onGameUpdated(String gameId,
      {String? hubId, String? region, String? city}) {
    _cache.clear(CacheKeys.game(gameId));

    if (hubId != null && hubId.isNotEmpty) {
      _cache.clear(CacheKeys.gamesByHub(hubId));
    }

    if (region != null) {
      _cache.clear(CacheKeys.publicGames(region: region, city: city));
    } else if (city != null) {
      _cache.clear(CacheKeys.publicGames(city: city));
    }

    _cache.clear(CacheKeys.publicGames());
  }

  /// Invalidate caches when a game is deleted
  void onGameDeleted(String gameId, {String? hubId}) {
    _cache.clear(CacheKeys.game(gameId));

    if (hubId != null && hubId.isNotEmpty) {
      _cache.clear(CacheKeys.gamesByHub(hubId));
      _cache.clear(CacheKeys.hub(hubId)); // Hub gameCount may change
    }

    _cache.clear(CacheKeys.publicGames());
  }

  /// Invalidate caches when a hub is created
  void onHubCreated(String hubId) {
    _cache.clear(CacheKeys.hub(hubId));
  }

  /// Invalidate caches when a hub is updated
  void onHubUpdated(String hubId) {
    _cache.clear(CacheKeys.hub(hubId));
    _cache.clear(CacheKeys.gamesByHub(hubId));
    _cache.clear(CacheKeys.eventsByHub(hubId));
  }

  /// Invalidate caches when a hub is deleted
  void onHubDeleted(String hubId) {
    _cache.clear(CacheKeys.hub(hubId));
    _cache.clear(CacheKeys.gamesByHub(hubId));
    _cache.clear(CacheKeys.eventsByHub(hubId));
  }

  /// Invalidate caches when a hub event is created
  void onEventCreated(String hubId, String eventId) {
    _cache.clear(CacheKeys.event(hubId, eventId));
    _cache.clear(CacheKeys.eventsByHub(hubId));
  }

  /// Invalidate caches when a hub event is updated
  void onEventUpdated(String hubId, String eventId) {
    _cache.clear(CacheKeys.event(hubId, eventId));
    _cache.clear(CacheKeys.eventsByHub(hubId));
  }

  /// Invalidate caches when a hub event is deleted
  void onEventDeleted(String hubId, String eventId) {
    _cache.clear(CacheKeys.event(hubId, eventId));
    _cache.clear(CacheKeys.eventsByHub(hubId));
  }

  /// Invalidate caches when an event is converted to a game
  void onEventConvertedToGame(String hubId, String eventId, String gameId) {
    // Event is now marked as completed
    onEventUpdated(hubId, eventId);

    // Game was created
    onGameCreated(gameId, hubId: hubId);
  }

  /// Invalidate caches when a user is updated
  void onUserUpdated(String userId) {
    _cache.clear(CacheKeys.user(userId));
  }

  /// Invalidate caches when a venue is created or updated
  void onVenueUpdated(String venueId) {
    _cache.clear(CacheKeys.venue(venueId));
    // Note: We don't clear all venues cache because that's expensive
    // UI should handle stale data or use pagination
  }

  /// Invalidate all caches (use sparingly, expensive operation)
  void clearAll() {
    _cache.clearAll();
  }

  /// Invalidate caches when hub membership changes
  void onHubMembershipChanged(String hubId, String userId) {
    _cache.clear(CacheKeys.hub(hubId));
    _cache.clear(CacheKeys.user(userId)); // User's hubIds may have changed
  }

  /// Invalidate caches when a signup is created/updated
  void onSignupChanged(String gameId, {String? hubId}) {
    _cache.clear(CacheKeys.game(gameId));

    if (hubId != null && hubId.isNotEmpty) {
      _cache.clear(CacheKeys.gamesByHub(hubId));
    }
  }
}
