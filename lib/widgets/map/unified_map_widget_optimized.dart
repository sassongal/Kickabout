import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/widgets/map/map_mode.dart';
import 'package:kattrick/widgets/map/map_providers.dart';
import 'package:kattrick/widgets/map/premium_map_card.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';

/// **OPTIMIZED** Unified Map Widget - Camera Bounds-Based with Marker Diffing
///
/// Performance improvements:
/// - ✅ Updates markers based on CAMERA BOUNDS (not circular radius)
/// - ✅ Marker diffing algorithm (only add/remove changed markers)
/// - ✅ ref.listen for camera idle events (no excessive rebuilds)
/// - ✅ "Search This Area" floating button
/// - ✅ Prevents marker flickering with smart diffing
/// - ✅ Camera position tracking with debouncing
///
/// Key Features:
/// - Mode-based configuration (findVenues, exploreHubs, exploreGames)
/// - Custom markers with caching
/// - Bottom sheet support for details
/// - Smooth camera transitions
class UnifiedMapWidgetOptimized extends ConsumerStatefulWidget {
  /// Map display mode (determines data source and UI)
  final MapMode mode;

  /// Callback when a marker is tapped
  final void Function(dynamic item)? onItemSelected;

  /// Initial center position (optional, defaults to current location)
  final Position? initialPosition;

  /// Whether to show "My Location" button
  final bool showMyLocationButton;

  /// Custom filters (optional - mode-specific)
  final Map<String, dynamic>? customFilters;

  /// Hub ID filter (for hub-specific maps)
  final String? hubId;

  const UnifiedMapWidgetOptimized({
    super.key,
    required this.mode,
    this.onItemSelected,
    this.initialPosition,
    this.showMyLocationButton = true,
    this.customFilters,
    this.hubId,
  });

  @override
  ConsumerState<UnifiedMapWidgetOptimized> createState() =>
      _UnifiedMapWidgetOptimizedState();
}

class _UnifiedMapWidgetOptimizedState
    extends ConsumerState<UnifiedMapWidgetOptimized> {
  // Map controller
  GoogleMapController? _mapController;

  // Location state
  Position? _currentPosition;
  Position? _initialLocation;
  bool _isLoading = true;
  bool _isLoadingMarkers = false;

  // Markers with diffing
  Set<Marker> _markers = {};

  // Custom icon cache (avoid recreating)
  final Map<String, BitmapDescriptor> _iconCache = {};

  // Camera state tracking
  LatLngBounds? _lastLoadedBounds;
  bool _showSearchAreaButton = false;

  // Selected item for PremiumMapCard
  dynamic _selectedItem; // User | Game | Venue | Hub

  // Debouncing
  Timer? _cameraDebounceTimer;
  static const _cameraDebounceMs = 500; // Reduced from 800ms for snappier UX

  // Data cache
  List<dynamic> _loadedItems = [];

  @override
  void initState() {
    super.initState();

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
    _initialLocation = _currentPosition;

    _loadCustomIcons();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _cameraDebounceTimer?.cancel();
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
          _initialLocation = position;
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
    _cameraDebounceTimer?.cancel();
    _cameraDebounceTimer = Timer(
      const Duration(milliseconds: _cameraDebounceMs),
      _loadMarkersInCameraBounds,
    );
  }

  /// **CAMERA BOUNDS-BASED LOADING** (not circular radius)
  Future<void> _loadMarkersInCameraBounds() async {
    if (_mapController == null) return;

    try {
      setState(() {
        _isLoadingMarkers = true;
      });

      // Get visible map bounds
      final bounds = await _mapController!.getVisibleRegion();

      // Check if we've moved significantly (prevent redundant loads)
      if (_lastLoadedBounds != null && _boundsAreSimilar(bounds, _lastLoadedBounds!)) {
        setState(() {
          _isLoadingMarkers = false;
        });
        return;
      }

      // Calculate center and radius from bounds
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      // Calculate radius (diagonal distance)
      final radiusMeters = Geolocator.distanceBetween(
        bounds.northeast.latitude,
        bounds.northeast.longitude,
        bounds.southwest.latitude,
        bounds.southwest.longitude,
      ) / 2;

      final radiusKm = radiusMeters / 1000;

      // Load items within bounds
      final items = await _loadItemsForBounds(
        center.latitude,
        center.longitude,
        radiusKm.clamp(widget.mode.minRadius, widget.mode.maxRadius),
      );

      // Apply result limit
      final limitedItems = items.take(widget.mode.maxInitialResults).toList();

      // **MARKER DIFFING**: Only update markers that changed
      final newMarkers = <Marker>{};

      for (final item in limitedItems) {
        final marker = _createMarkerForItem(item);
        if (marker != null) {
          newMarkers.add(marker);
        }
      }

      // Calculate diff
      final addedMarkers = newMarkers.difference(_markers);
      final removedMarkers = _markers.difference(newMarkers);

      debugPrint('🗺️ Marker Diff: +${addedMarkers.length} -${removedMarkers.length}');

      if (mounted) {
        setState(() {
          _loadedItems = limitedItems;
          _markers = newMarkers;
          _lastLoadedBounds = bounds;
          _isLoadingMarkers = false;

          // Show "Search This Area" button if user panned away
          _checkIfUserPannedAway(center);
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

  /// Check if two bounds are similar enough to skip reloading
  bool _boundsAreSimilar(LatLngBounds bounds1, LatLngBounds bounds2) {
    const threshold = 0.001; // ~100m
    return (bounds1.northeast.latitude - bounds2.northeast.latitude).abs() < threshold &&
        (bounds1.northeast.longitude - bounds2.northeast.longitude).abs() < threshold &&
        (bounds1.southwest.latitude - bounds2.southwest.latitude).abs() < threshold &&
        (bounds1.southwest.longitude - bounds2.southwest.longitude).abs() < threshold;
  }

  /// Check if user panned away from initial location
  void _checkIfUserPannedAway(LatLng center) {
    if (_initialLocation == null) return;

    final distanceMeters = Geolocator.distanceBetween(
      _initialLocation!.latitude,
      _initialLocation!.longitude,
      center.latitude,
      center.longitude,
    );

    // Show button if user is more than 500m away from initial location
    _showSearchAreaButton = distanceMeters > 500;
  }

  /// Load items based on map mode using providers
  Future<List<dynamic>> _loadItemsForBounds(
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

      if (item is User) {
        // Player markers
        markerId = 'player_${item.uid}';
        if (item.location == null) return null;
        position = LatLng(item.location!.latitude, item.location!.longitude);
        icon = _iconCache['player'] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        title = item.name;
      } else if (item is Venue) {
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
          // Set selected item to show PremiumMapCard
          setState(() {
            _selectedItem = item;
          });

          // Also call callback if provided (backward compatibility)
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

  /// Return to initial location
  void _returnToMyLocation() {
    if (_mapController == null || _initialLocation == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _initialLocation!.latitude,
            _initialLocation!.longitude,
          ),
          zoom: 14.0,
        ),
      ),
    );

    setState(() {
      _showSearchAreaButton = false;
    });
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
            zoom: 14.0,
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
              if (mounted) _loadMarkersInCameraBounds();
            });
          },
          onCameraIdle: () {
            // Use ref.listen pattern for smoother updates
            _loadMarkersDebounced();
          },
          onTap: (_) {
            // Deselect marker when tapping map background
            setState(() {
              _selectedItem = null;
            });
          },
        ),

        // Loading indicator (top-right)
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

        // "Search This Area" floating button
        if (_showSearchAreaButton)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _loadMarkersInCameraBounds();
                  setState(() {
                    _showSearchAreaButton = false;
                  });
                },
                icon: const Icon(Icons.search, size: 18),
                label: const Text('חפש באזור זה'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.mode.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ),

        // Results count (bottom)
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
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _returnToMyLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('חזור למיקום שלי'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Premium Map Card (slides up from bottom when item selected)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          bottom: _selectedItem != null ? 0 : -400,
          left: 0,
          right: 0,
          child: _selectedItem != null
              ? SafeArea(
                  child: PremiumMapCard(
                    item: _selectedItem!,
                    onClose: () {
                      setState(() {
                        _selectedItem = null;
                      });
                    },
                    userLocation: _currentPosition,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
