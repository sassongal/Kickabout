import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Map display and interaction modes for UnifiedMapWidget
///
/// Each mode configures the map for a specific use case with customized
/// markers, filters, and performance limits.
enum MapMode {
  /// Hub discovery mode - explore nearby football communities
  exploreHubs,

  /// Venue discovery mode - find and select football venues
  findVenues,

  /// Game discovery mode - find active and upcoming matches
  exploreGames;

  /// Display label in Hebrew
  String get label {
    switch (this) {
      case MapMode.findVenues:
        return 'מגרשים';
      case MapMode.exploreHubs:
        return 'הובים';
      case MapMode.exploreGames:
        return 'משחקים';
    }
  }

  /// Icon representing this mode
  IconData get icon {
    switch (this) {
      case MapMode.findVenues:
        return Icons.stadium;
      case MapMode.exploreHubs:
        return Icons.groups;
      case MapMode.exploreGames:
        return Icons.sports_soccer;
    }
  }

  /// Primary color for this mode's markers and UI
  Color get primaryColor {
    switch (this) {
      case MapMode.findVenues:
        return PremiumColors.secondary; // Green (grass/venue)
      case MapMode.exploreHubs:
        return PremiumColors.primary; // Blue (community)
      case MapMode.exploreGames:
        return PremiumColors.accent; // Purple (premium event)
    }
  }

  /// Default search radius in kilometers
  double get defaultRadius {
    switch (this) {
      case MapMode.findVenues:
        return 15.0; // Venues: 15km (broader search)
      case MapMode.exploreHubs:
        return 5.0; // Hubs: 5km (tight community)
      case MapMode.exploreGames:
        return 15.0; // Games: 15km (broader search)
    }
  }

  /// Maximum initial results to load (performance limit)
  ///
  /// Prevents loading all 800+ venues at once.
  /// Additional results loaded on demand (scroll/zoom).
  int get maxInitialResults {
    switch (this) {
      case MapMode.findVenues:
        return 50; // Increased limit for better discovery
      case MapMode.exploreHubs:
        return 20; // Show more hubs (less data per item)
      case MapMode.exploreGames:
        return 15; // Balanced game display
    }
  }

  /// Minimum search radius in kilometers
  double get minRadius => 1.0;

  /// Maximum search radius in kilometers
  double get maxRadius {
    switch (this) {
      case MapMode.findVenues:
        return 50.0;
      case MapMode.exploreHubs:
        return 30.0;
      case MapMode.exploreGames:
        return 50.0;
    }
  }

  /// Whether to show radius control slider
  bool get showRadiusControl => true;

  /// Whether to enable marker clustering (not currently supported)
  bool get enableClustering => false;

  /// Marker hue for fallback (when custom icons fail)
  double get fallbackMarkerHue {
    switch (this) {
      case MapMode.findVenues:
        return BitmapDescriptor.hueGreen;
      case MapMode.exploreHubs:
        return BitmapDescriptor.hueAzure;
      case MapMode.exploreGames:
        return BitmapDescriptor.hueViolet;
    }
  }

  /// Display name for empty state
  String get emptyStateTitle {
    switch (this) {
      case MapMode.findVenues:
        return 'לא נמצאו מגרשים';
      case MapMode.exploreHubs:
        return 'לא נמצאו הובים';
      case MapMode.exploreGames:
        return 'לא נמצאו משחקים';
    }
  }

  /// Message for empty state
  String get emptyStateMessage {
    switch (this) {
      case MapMode.findVenues:
        return 'נסה להגדיל את רדיוס החיפוש';
      case MapMode.exploreHubs:
        return 'נסה להגדיל את רדיוס החיפוש או לזוז לאזור אחר';
      case MapMode.exploreGames:
        return 'אין משחקים פעילים באזור זה כרגע';
    }
  }
}
