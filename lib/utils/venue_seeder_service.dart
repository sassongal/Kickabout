import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/services/google_places_service.dart';

/// Service to seed venues from Google Places
class VenueSeederService {
  final Ref ref;

  VenueSeederService(this.ref);

  /// Seed major cities in Israel with football venues
  Future<void> seedMajorCities() async {
    final cities = [
      {'name': 'Tel Aviv', 'lat': 32.0853, 'lng': 34.7818},
      {'name': 'Jerusalem', 'lat': 31.7683, 'lng': 35.2137},
      {'name': 'Haifa', 'lat': 32.7940, 'lng': 34.9896},
      {'name': 'Rishon LeZion', 'lat': 31.9730, 'lng': 34.7925},
      {'name': 'Beer Sheva', 'lat': 31.2518, 'lng': 34.7913},
    ];

    final venuesRepo = ref.read(venuesRepositoryProvider);
    final placesService = GooglePlacesService();

    int totalCreated = 0;
    int totalSkipped = 0;

    for (final city in cities) {
      debugPrint('Seeding venues for ${city['name']}...');

      try {
        // Search for football venues in this city
        final results = await placesService.searchForFootballVenues(
          latitude: city['lat'] as double,
          longitude: city['lng'] as double,
          radius: 10000, // 10km radius
        );

        debugPrint('Found ${results.length} venues in ${city['name']}');

        for (final result in results) {
          try {
            // Check if venue already exists by googlePlaceId
            // We use getOrCreateVenueFromGooglePlace which handles the check
            final venue = result.toVenue(hubId: '');

            // This will create it if it doesn't exist, or return existing
            await venuesRepo.getOrCreateVenueFromGooglePlace(venue);
            totalCreated++;
          } catch (e) {
            debugPrint('Error processing venue ${result.name}: $e');
            totalSkipped++;
          }
        }
      } catch (e) {
        debugPrint('Error seeding ${city['name']}: $e');
      }
    }

    debugPrint(
        'Seeding complete. Processed: ${totalCreated + totalSkipped}, Created/Verified: $totalCreated, Errors: $totalSkipped');
  }
}

final venueSeederServiceProvider = Provider<VenueSeederService>((ref) {
  return VenueSeederService(ref);
});
