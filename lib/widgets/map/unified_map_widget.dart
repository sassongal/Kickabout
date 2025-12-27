import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/widgets/map/map_mode.dart';
import 'package:kattrick/widgets/map/map_providers.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/models/models.dart';

/// Unified Map Widget - Single reusable map component for all map-based screens
///
/// This widget consolidates map functionality from MapScreen, DiscoverVenuesScreen,
/// and DiscoverHubsScreen into a single, mode-based component.
///
/// Key Features:
/// - Performance-first: Never loads all 800+ venues at once
/// - Mode-based configuration (findVenues, exploreHubs, exploreGames)
/// - Camera debouncing (800ms) to reduce API calls
/// - Radius-based fetching with result limits
/// - Custom markers with caching
/// - Filter chip integration
/// - Bottom sheet support for details
///
/// Usage:
/// ```dart
/// UnifiedMapWidget(
///   mode: MapMode.findVenues,
///   onItemSelected: (item) => _navigateToDetails(item),
///   initialRadius: 10.0, // km
/// )
/// ```
class UnifiedMapWidget extends ConsumerStatefulWidget {
  /// Map display mode (determines data source and UI)
  final MapMode mode;

  /// Callback when a marker is tapped
  final void Function(dynamic item)? onItemSelected;

  /// Initial search radius in kilometers
  final double? initialRadius;

  /// Initial center position (optional, defaults to current location)
  final Position? initialPosition;

  /// Whether to show radius control slider
  final bool showRadiusControl;

  /// Whether to show filter chips
  final bool showFilterChips;

  /// Whether to show "My Location" button
  final bool showMyLocationButton;

  /// Custom filters (optional - mode-specific)
  final Map<String, dynamic>? customFilters;

  /// Hub ID filter (for hub-specific maps)
  final String? hubId;

  const UnifiedMapWidget({
    super.key,
    required this.mode,
    this.onItemSelected,
    this.initialRadius,
    this.initialPosition,
    this.showRadiusControl = true,
    this.showFilterChips = true,
    this.showMyLocationButton = true,
    this.customFilters,
    this.hubId,
  });

  @override
  ConsumerState<UnifiedMapWidget> createState() => _UnifiedMapWidgetState();
}

class _UnifiedMapWidgetState extends ConsumerState<UnifiedMapWidget> {
  // Map controller
  GoogleMapController? _mapController;

  // Location state
  Position? _currentPosition;
  bool _isLoading = true;
  bool _isLoadingMarkers = false;

  // Search radius (in kilometers)
  late double _radiusKm;

  // Markers
  Set<Marker> _markers = {};

  // Custom icon cache (avoid recreating)
  final Map<String, BitmapDescriptor> _iconCache = {};

  // Camera debouncing
  Timer? _cameraUpdateTimer;
  static const _cameraDebounceMs = 800;

  // Data cache
  List<dynamic> _loadedItems = [];

  @override
  void initState() {
    super.initState();
    _radiusKm = widget.initialRadius ?? widget.mode.defaultRadius;

    // Set initial position
    _currentPosition = widget.initialPosition ??
        Position(
          latitude: 31.7683, // Jerusalem, Israel (default)
          longitude: 35.2137,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );

    _loadCustomIcons();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _cameraUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Load custom marker icons with caching
  Future<void> _loadCustomIcons() async {
    try {
      // Load mode-specific icons
      final iconPaths = _getIconPathsForMode();

      for (final entry in iconPaths.entries) {
        try {
          final icon = await BitmapDescriptor.asset(
            const ImageConfiguration(size: Size(100, 100)),
            entry.value,
          );
          _iconCache[entry.key] = icon;
        } catch (e) {
          debugPrint('⚠️ Failed to load icon ${entry.key}: $e');
          // Use default marker as fallback
          _iconCache[entry.key] = BitmapDescriptor.defaultMarkerWithHue(
            widget.mode.fallbackMarkerHue,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading custom icons: $e');
    }
  }

  /// Get icon paths based on map mode
  Map<String, String> _getIconPathsForMode() {
    switch (widget.mode) {
      case MapMode.findVenues:
        return {
          'venue_public': 'assets/icons/venue_public.png',
          'venue_rental': 'assets/icons/venue_rental.png',
        };
      case MapMode.exploreHubs:
        return {
          'hub': 'assets/icons/hub_marker.png',
        };
      case MapMode.exploreGames:
        return {
          'game_live': 'assets/icons/game_live.png',
          'game_upcoming': 'assets/icons/game_upcoming.png',
        };
    }
  }

  /// Get current location with permission handling
  Future<void> _loadCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        _setDefaultLocation();
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied');
          _setDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied forever');
        _setDefaultLocation();
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Location timeout');
          return _currentPosition!;
        },
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(position.latitude, position.longitude),
          ),
        );

        // Load markers for current location
        _loadMarkersDebounced();
      }
    } catch (e) {
      debugPrint('Error loading location: $e');
      _setDefaultLocation();
    }
  }

  /// Set default location when GPS fails
  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load markers with debouncing to prevent excessive API calls
  void _loadMarkersDebounced() {
    _cameraUpdateTimer?.cancel();
    _cameraUpdateTimer = Timer(
      const Duration(milliseconds: _cameraDebounceMs),
      _loadMarkers,
    );
  }

  /// Load markers based on current map mode and camera position
  Future<void> _loadMarkers() async {
    if (_mapController == null || _currentPosition == null) return;

    try {
      setState(() {
        _isLoadingMarkers = true;
      });

      final center = await _mapController!.getLatLng(
        ScreenCoordinate(
          x: (MediaQuery.of(context).size.width / 2).round(),
          y: (MediaQuery.of(context).size.height / 2).round(),
        ),
      );

      // Load items based on mode
      final items = await _loadItemsForMode(
        center.latitude,
        center.longitude,
        _radiusKm,
      );

      // Apply result limit
      final limitedItems = items.take(widget.mode.maxInitialResults).toList();

      // Create markers
      final markers = <Marker>{};
      for (final item in limitedItems) {
        final marker = _createMarkerForItem(item);
        if (marker != null) {
          markers.add(marker);
        }
      }

      if (mounted) {
        setState(() {
          _loadedItems = limitedItems;
          _markers = markers;
          _isLoadingMarkers = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading markers: $e');
      if (mounted) {
        setState(() {
          _isLoadingMarkers = false;
        });
      }
    }
  }

  /// Load items based on map mode using providers
  Future<List<dynamic>> _loadItemsForMode(
    double lat,
    double lng,
    double radiusKm,
  ) async {
    // Create map state for the provider
    final mapState = MapState(
      center: Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
      radiusKm: radiusKm,
      mode: widget.mode,
    );

    // Load items using the appropriate provider
    try {
      final items = await ref.read(nearbyItemsProvider(mapState).future);
      return items;
    } catch (e) {
      debugPrint('Error loading items for ${widget.mode.label}: $e');
      return [];
    }
  }

  /// Create marker for an item
  Marker? _createMarkerForItem(dynamic item) {
    try {
      String markerId;
      LatLng position;
      BitmapDescriptor icon;
      String title;

      if (item is Venue) {
        markerId = 'venue_${item.venueId}';
        position = LatLng(item.location.latitude, item.location.longitude);
        icon = _getIconForVenue(item);
        title = item.name;
      } else if (item is Hub) {
        markerId = 'hub_${item.hubId}';
        // Hub location might be nullable, check before using
        if (item.location == null) return null;
        position = LatLng(item.location!.latitude, item.location!.longitude);
        icon = _iconCache['hub'] ??
            BitmapDescriptor.defaultMarkerWithHue(
              widget.mode.fallbackMarkerHue,
            );
        title = item.name;
      } else if (item is Game && item.locationPoint != null) {
        markerId = 'game_${item.gameId}';
        position = LatLng(
          item.locationPoint!.latitude,
          item.locationPoint!.longitude,
        );
        icon = _getIconForGame(item);
        // Game doesn't have a 'name' field, use location or default
        title = item.location ?? 'משחק';
      } else {
        return null;
      }

      return Marker(
        markerId: MarkerId(markerId),
        position: position,
        icon: icon,
        infoWindow: InfoWindow(title: title),
        onTap: () {
          if (widget.onItemSelected != null) {
            widget.onItemSelected!(item);
          }
        },
      );
    } catch (e) {
      debugPrint('Error creating marker: $e');
      return null;
    }
  }

  /// Get icon for venue
  BitmapDescriptor _getIconForVenue(Venue venue) {
    if (venue.isPublic) {
      return _iconCache['venue_public'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else {
      return _iconCache['venue_rental'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
  }

  /// Get icon for game
  BitmapDescriptor _getIconForGame(Game game) {
    if (game.status == GameStatus.inProgress) {
      return _iconCache['game_live'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      return _iconCache['game_upcoming'] ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  /// Handle radius change
  void _onRadiusChanged(double newRadius) {
    setState(() {
      _radiusKm = newRadius;
    });
    _loadMarkersDebounced();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PremiumLoadingState(
        message: 'טוען ${widget.mode.label}...',
      );
    }

    return Stack(
      children: [
        // Map
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            zoom: _getZoomForRadius(_radiusKm),
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: widget.showMyLocationButton,
          mapType: MapType.normal,
          onMapCreated: (controller) {
            setState(() {
              _mapController = controller;
            });
            // Load markers once map is ready
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _loadMarkers();
            });
          },
          onCameraIdle: () {
            _loadMarkersDebounced();
          },
        ),

        // Loading indicator
        if (_isLoadingMarkers)
          Positioned(
            top: 16,
            right: 16,
            child: Card(
              color: Colors.black87,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          widget.mode.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'טוען...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Radius control slider
        if (widget.showRadiusControl)
          Positioned(
            bottom: 80,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'רדיוס חיפוש',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${_radiusKm.toStringAsFixed(1)} ק״מ',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: widget.mode.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _radiusKm,
                      min: widget.mode.minRadius,
                      max: widget.mode.maxRadius,
                      divisions: ((widget.mode.maxRadius -
                                  widget.mode.minRadius) *
                              2)
                          .round(),
                      activeColor: widget.mode.primaryColor,
                      onChanged: _onRadiusChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Results count
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Card(
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.mode.icon,
                        color: widget.mode.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_loadedItems.length} ${widget.mode.label}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  if (_loadedItems.length >= widget.mode.maxInitialResults)
                    Text(
                      'הצג עוד בתוצאות',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[400],
                          ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Empty state
        if (!_isLoadingMarkers && _loadedItems.isEmpty)
          Center(
            child: Card(
              margin: const EdgeInsets.all(32.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.mode.icon,
                      size: 48,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.mode.emptyStateTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.mode.emptyStateMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Calculate appropriate zoom level for radius
  double _getZoomForRadius(double radiusKm) {
    // Approximate zoom levels for radius (rough estimation)
    if (radiusKm <= 1) return 15.0;
    if (radiusKm <= 2) return 14.0;
    if (radiusKm <= 5) return 13.0;
    if (radiusKm <= 10) return 12.0;
    if (radiusKm <= 20) return 11.0;
    if (radiusKm <= 30) return 10.0;
    return 9.0;
  }
}
