import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/data/repositories.dart';
import 'package:kickadoor/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for matching players with relevant hubs based on venues
/// This service helps players find hubs that play at venues near them
class HubVenueMatcherService {
  final HubsRepository _hubsRepo;
  final VenuesRepository _venuesRepo;

  HubVenueMatcherService({
    required HubsRepository hubsRepo,
    required VenuesRepository venuesRepo,
  })  : _hubsRepo = hubsRepo,
        _venuesRepo = venuesRepo;

  /// Find relevant hubs for a player based on their location and preferred venues
  ///
  /// [latitude] - Player's latitude
  /// [longitude] - Player's longitude
  /// [radiusKm] - Search radius in kilometers
  /// [maxResults] - Maximum number of hubs to return
  Future<List<HubMatchResult>> findRelevantHubs({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int maxResults = 20,
  }) async {
    try {
      // 1. Find all venues within radius
      final nearbyVenues = await _venuesRepo.findVenuesNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      // 2. Get unique hub IDs from venues
      final hubIds = nearbyVenues
          .map((v) => v.hubId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (hubIds.isEmpty) {
        return [];
      }

      // 3. Get hubs
      final hubs = <Hub>[];
      for (final hubId in hubIds) {
        final hub = await _hubsRepo.getHub(hubId);
        if (hub != null) {
          hubs.add(hub);
        }
      }

      // 4. Calculate match scores and create results
      final results = <HubMatchResult>[];
      for (final hub in hubs) {
        // Get all venues for this hub
        final hubVenues = await _venuesRepo.getVenuesByHub(hub.hubId);

        // Find closest venue
        double? closestDistance;
        Venue? closestVenue;

        for (final venue in hubVenues) {
          final distance = Geolocator.distanceBetween(
                latitude,
                longitude,
                venue.location.latitude,
                venue.location.longitude,
              ) /
              1000; // Convert to km

          if (closestDistance == null || distance < closestDistance) {
            closestDistance = distance;
            closestVenue = venue;
          }
        }

        if (closestVenue != null && closestDistance != null) {
          // Calculate relevance score
          // Factors: distance (closer = better), hub size (more members = better)
          final distanceScore =
              1.0 / (1.0 + closestDistance); // Inverse distance
          final sizeScore =
              (hub.memberCount / 100.0).clamp(0.0, 1.0); // Normalize to 0-1
          final relevanceScore = (distanceScore * 0.7) + (sizeScore * 0.3);

          results.add(HubMatchResult(
            hub: hub,
            closestVenue: closestVenue,
            distanceKm: closestDistance,
            relevanceScore: relevanceScore,
            venueCount: hubVenues.length,
          ));
        }
      }

      // 5. Sort by relevance score (highest first)
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      // 6. Return top results
      return results.take(maxResults).toList();
    } catch (e) {
      return [];
    }
  }

  /// Find hubs that play at a specific venue
  Future<List<Hub>> findHubsByVenue(String venueId) async {
    try {
      final venue = await _venuesRepo.getVenue(venueId);
      if (venue == null) return [];

      final hub = await _hubsRepo.getHub(venue.hubId);
      if (hub == null) return [];

      return [hub];
    } catch (e) {
      return [];
    }
  }

  /// Find hubs that play at venues near a specific location
  Future<List<Hub>> findHubsByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final venues = await _venuesRepo.findVenuesNearby(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      final hubIds = venues
          .map((v) => v.hubId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final hubs = <Hub>[];
      for (final hubId in hubIds) {
        final hub = await _hubsRepo.getHub(hubId);
        if (hub != null) {
          hubs.add(hub);
        }
      }

      return hubs;
    } catch (e) {
      return [];
    }
  }
}

/// Result of hub matching
class HubMatchResult {
  final Hub hub;
  final Venue closestVenue;
  final double distanceKm;
  final double relevanceScore; // 0.0 - 1.0
  final int venueCount;

  HubMatchResult({
    required this.hub,
    required this.closestVenue,
    required this.distanceKm,
    required this.relevanceScore,
    required this.venueCount,
  });
}

/// Provider for HubVenueMatcherService
final hubVenueMatcherServiceProvider = Provider<HubVenueMatcherService>((ref) {
  return HubVenueMatcherService(
    hubsRepo: ref.watch(hubsRepositoryProvider),
    venuesRepo: ref.watch(venuesRepositoryProvider),
  );
});
