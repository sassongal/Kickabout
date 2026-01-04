import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/widgets/map/map_mode.dart';

/// Map state - holds current map center and radius
class MapState {
  final Position? center;
  final double radiusKm;
  final MapMode mode;

  const MapState({
    required this.center,
    required this.radiusKm,
    required this.mode,
  });

  MapState copyWith({
    Position? center,
    double? radiusKm,
    MapMode? mode,
  }) {
    return MapState(
      center: center ?? this.center,
      radiusKm: radiusKm ?? this.radiusKm,
      mode: mode ?? this.mode,
    );
  }
}

/// State notifier for map state management
class MapStateNotifier extends StateNotifier<MapState> {
  MapStateNotifier(MapMode mode)
      : super(MapState(
          center: null,
          radiusKm: mode.defaultRadius,
          mode: mode,
        ));

  void updateCenter(Position position) {
    state = state.copyWith(center: position);
  }

  void updateRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm);
  }

  void updateMode(MapMode mode) {
    state = state.copyWith(
      mode: mode,
      radiusKm: mode.defaultRadius, // Reset radius to mode default
    );
  }
}

/// Provider for map state (mode-specific)
final mapStateProvider =
    StateNotifierProvider.family<MapStateNotifier, MapState, MapMode>(
  (ref, mode) => MapStateNotifier(mode),
);

/// Provider for nearby venues based on map state
final nearbyVenuesProvider = FutureProvider.autoDispose
    .family<List<Venue>, MapState>((ref, mapState) async {
  if (mapState.center == null) return [];
  if (mapState.mode != MapMode.findVenues) return [];

  final venuesRepo = ref.watch(venuesRepositoryProvider);

  try {
    final venues = await venuesRepo.findVenuesNearby(
      latitude: mapState.center!.latitude,
      longitude: mapState.center!.longitude,
      radiusKm: mapState.radiusKm,
    );

    // Apply result limit from mode
    return venues.take(mapState.mode.maxInitialResults).toList();
  } catch (e, stackTrace) {
    // 🔍 DIAGNOSTIC: Enhanced error logging for map search failures
    debugPrint('❌ MAP SEARCH ERROR (Venues):');
    debugPrint('   Center: (${mapState.center!.latitude}, ${mapState.center!.longitude})');
    debugPrint('   Radius: ${mapState.radiusKm}km');
    debugPrint('   Error: $e');
    debugPrint('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    // Return empty list to prevent map crash
    return [];
  }
});

/// Provider for nearby hubs based on map state
final nearbyHubsProvider = FutureProvider.autoDispose
    .family<List<Hub>, MapState>((ref, mapState) async {
  if (mapState.center == null) return [];
  if (mapState.mode != MapMode.exploreHubs) return [];

  final hubsRepo = ref.watch(hubsRepositoryProvider);

  try {
    final hubs = await hubsRepo.findHubsNearby(
      latitude: mapState.center!.latitude,
      longitude: mapState.center!.longitude,
      radiusKm: mapState.radiusKm,
    );

    // Apply result limit from mode
    return hubs.take(mapState.mode.maxInitialResults).toList();
  } catch (e, stackTrace) {
    // 🔍 DIAGNOSTIC: Enhanced error logging for map search failures
    debugPrint('❌ MAP SEARCH ERROR (Hubs):');
    debugPrint('   Center: (${mapState.center!.latitude}, ${mapState.center!.longitude})');
    debugPrint('   Radius: ${mapState.radiusKm}km');
    debugPrint('   Error: $e');
    debugPrint('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    // Return empty list to prevent map crash
    return [];
  }
});

/// Provider for nearby games based on map state
final nearbyGamesProvider = FutureProvider.autoDispose
    .family<List<Game>, MapState>((ref, mapState) async {
  if (mapState.center == null) return [];
  if (mapState.mode != MapMode.exploreGames) return [];

  final gamesRepo = ref.watch(gamesRepositoryProvider);

  try {
    final games = await gamesRepo.findGamesNearby(
      latitude: mapState.center!.latitude,
      longitude: mapState.center!.longitude,
      radiusKm: mapState.radiusKm,
    );

    // Apply result limit from mode
    return games.take(mapState.mode.maxInitialResults).toList();
  } catch (e, stackTrace) {
    // 🔍 DIAGNOSTIC: Enhanced error logging for map search failures
    debugPrint('❌ MAP SEARCH ERROR (Games):');
    debugPrint('   Center: (${mapState.center!.latitude}, ${mapState.center!.longitude})');
    debugPrint('   Radius: ${mapState.radiusKm}km');
    debugPrint('   Error: $e');
    debugPrint('   Stack: ${stackTrace.toString().split('\n').take(3).join('\n')}');
    // Return empty list to prevent map crash
    return [];
  }
});

/// Combined provider that returns items based on map mode
final nearbyItemsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, MapState>((ref, mapState) async {
  switch (mapState.mode) {
    case MapMode.findVenues:
      final venues = await ref.watch(nearbyVenuesProvider(mapState).future);
      return venues;
    case MapMode.exploreHubs:
      final hubs = await ref.watch(nearbyHubsProvider(mapState).future);
      return hubs;
    case MapMode.exploreGames:
      final games = await ref.watch(nearbyGamesProvider(mapState).future);
      return games;
  }
});

/// Stream provider for watching nearby venues (real-time updates)
final watchNearbyVenuesProvider = StreamProvider.autoDispose
    .family<List<Venue>, MapState>((ref, mapState) async* {
  if (mapState.center == null) {
    yield [];
    return;
  }
  if (mapState.mode != MapMode.findVenues) {
    yield [];
    return;
  }

  // For venues, we use a one-time fetch since they don't change frequently
  // If real-time updates are needed in the future, implement a stream in VenuesRepository
  final venues = await ref.watch(nearbyVenuesProvider(mapState).future);
  yield venues;
});

/// Stream provider for watching nearby hubs (real-time updates)
final watchNearbyHubsProvider = StreamProvider.autoDispose
    .family<List<Hub>, MapState>((ref, mapState) async* {
  if (mapState.center == null) {
    yield [];
    return;
  }
  if (mapState.mode != MapMode.exploreHubs) {
    yield [];
    return;
  }

  // TODO: Implement real-time hub watching with location queries
  final hubs = await ref.watch(nearbyHubsProvider(mapState).future);
  yield hubs;
});

/// Stream provider for watching nearby games (real-time updates)
final watchNearbyGamesProvider = StreamProvider.autoDispose
    .family<List<Game>, MapState>((ref, mapState) async* {
  if (mapState.center == null) {
    yield [];
    return;
  }
  if (mapState.mode != MapMode.exploreGames) {
    yield [];
    return;
  }

  // TODO: Implement real-time game watching with location queries
  final games = await ref.watch(nearbyGamesProvider(mapState).future);
  yield games;
});
