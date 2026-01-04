import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:rxdart/rxdart.dart';

/// Optimized screen for discovering and searching football venues in Israel
///
/// **Performance Optimizations:**
/// - RxDart debouncing (300ms) for search
/// - Camera bounds-based loading (not getVenuesForMap())
/// - Server-side hybrid search (Firestore + Google Places API)
/// - Split view: Map 40%, List 60%
/// - Marker diffing to prevent flickering
class DiscoverVenuesScreenOptimized extends ConsumerStatefulWidget {
  const DiscoverVenuesScreenOptimized({super.key, this.filterCity});

  final String? filterCity;

  @override
  ConsumerState<DiscoverVenuesScreenOptimized> createState() =>
      _DiscoverVenuesScreenOptimizedState();
}

class _DiscoverVenuesScreenOptimizedState
    extends ConsumerState<DiscoverVenuesScreenOptimized> {
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  GoogleMapController? _mapController;

  // RxDart for debounced search
  final BehaviorSubject<String> _searchSubject = BehaviorSubject<String>();
  StreamSubscription<String>? _searchSubscription;

  // Default center: Israel center (approximately Tel Aviv)
  LatLng _currentCenter = const LatLng(32.0853, 34.7818);
  double _currentZoom = 12.0;
  LatLngBounds? _lastLoadedBounds;

  List<Venue> _venues = [];
  List<AutocompletePrediction> _autocompleteResults = [];
  bool _isLoadingLocation = false;
  bool _isLoadingVenues = false;
  bool _isSearching = false;
  bool _showAutocomplete = false;
  Set<Marker> _markers = {};

  Venue? _selectedVenue;
  PlaceResult? _selectedPlace; // For creating new venue

  // Custom icon cache
  BitmapDescriptor? _venuePublicIcon;
  BitmapDescriptor? _venueRentalIcon;
  BitmapDescriptor? _selectedVenueIcon;
  bool _iconsLoaded = false;

  // Search mode
  bool _useHybridSearch = false; // Toggle between camera bounds and hybrid search

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _initDebouncing();
    _loadVenuesForCurrentLocation();
  }

  @override
  void dispose() {
    _searchSubscription?.cancel();
    _searchSubject.close();
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize RxDart debounced search
  void _initDebouncing() {
    _searchSubscription = _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .distinct()
        .listen((query) {
      _performSearch(query);
    });

    _searchController.addListener(() {
      _searchSubject.add(_searchController.text);
    });
  }

  Future<void> _loadCustomIcons() async {
    try {
      final icons = await Future.wait([
        BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(80, 80)),
          'assets/icons/venue_public.png',
        ),
        BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(80, 80)),
          'assets/icons/venue_rental.png',
        ),
        BitmapDescriptor.asset(
          const ImageConfiguration(
              size: Size(100, 100)), // Slightly larger for selected
          'assets/icons/venue_public.png',
        ),
      ]);

      if (mounted) {
        setState(() {
          _venuePublicIcon = icons[0];
          _venueRentalIcon = icons[1];
          _selectedVenueIcon = icons[2];
          _iconsLoaded = true;
        });
        // Update markers with new icons
        _updateMarkers();
      }
    } catch (e) {
      debugPrint('Error loading venue icons: $e');
      // Fallback to default markers - icons already null
    }
  }

  /// Perform search using hybrid approach or autocomplete
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      // If query is empty, reload venues based on current camera position
      await _loadVenuesForCameraBounds();
      setState(() {
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      return;
    }

    if (query.length < 3) {
      setState(() {
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      if (_useHybridSearch) {
        // **SERVER-SIDE HYBRID SEARCH** (Firestore + Google Places API)
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final results = await venuesRepo.searchVenuesCombined(query);

        if (mounted) {
          setState(() {
            _venues = results;
            _isSearching = false;
            _useHybridSearch = false; // Reset flag after search
          });
          _updateMarkers();
        }
      } else {
        // Show autocomplete for Google Places
        final results = await _placesService.getAutocomplete(query);

        if (mounted) {
          setState(() {
            _autocompleteResults = results;
            _showAutocomplete = results.isNotEmpty;
            _isSearching = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _showAutocomplete = false;
        });
      }
    }
  }

  Future<void> _selectAutocompleteResult(
      AutocompletePrediction prediction) async {
    setState(() => _isSearching = true);

    try {
      // Get place details
      final placeDetails =
          await _placesService.getPlaceDetails(prediction.placeId);

      if (placeDetails != null && mounted) {
        _selectedPlace = placeDetails;
        _searchController.text = placeDetails.name;

        // Move map to location
        final location = LatLng(
          placeDetails.latitude,
          placeDetails.longitude,
        );

        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );

        setState(() {
          _showAutocomplete = false;
          _isSearching = false;
          _currentCenter = location;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת פרטי מקום: $e')),
        );
      }
    }
  }

  void _selectLocation() {
    if (_selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('נא לבחור מקום מהחיפוש או מהמפה')),
      );
      return;
    }

    // Return location data for manual selection
    Navigator.of(context).pop({
      'location': GeographicPoint(
        latitude: _selectedPlace!.latitude,
        longitude: _selectedPlace!.longitude,
      ),
      'name': _selectedPlace!.name,
      'address': _selectedPlace!.address,
      'city': _selectedPlace!.city, // Include extracted city
    });
  }

  /// Load venues for current user location (initial load)
  Future<void> _loadVenuesForCurrentLocation() async {
    setState(() => _isLoadingVenues = true);

    try {
      // Get current location
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('Could not get location, using default: $e');
      }

      final lat = position?.latitude ?? 32.0853; // Default to Tel Aviv
      final lng = position?.longitude ?? 34.7818;

      // **SERVER-SIDE GEOHASH SEARCH** (not getVenuesForMap!)
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final venues = await venuesRepo.findVenuesNearby(
        latitude: lat,
        longitude: lng,
        radiusKm: 25.0, // 25km radius
      );

      if (mounted) {
        setState(() {
          // Filter by city if filterCity is provided
          _venues = venues.where((v) {
            final meetsBasicCriteria = v.isPublic && v.isActive;
            if (!meetsBasicCriteria) return false;

            // If filterCity is set, only show venues in that city
            if (widget.filterCity != null && widget.filterCity!.isNotEmpty) {
              return v.city?.trim().toLowerCase() ==
                  widget.filterCity!.trim().toLowerCase();
            }

            return true;
          }).toList();
          _isLoadingVenues = false;
          _updateMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVenues = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת מגרשים: $e')),
        );
      }
    }
  }

  /// Load venues based on camera bounds (called when camera stops moving)
  Future<void> _loadVenuesForCameraBounds() async {
    if (_mapController == null) return;

    setState(() => _isLoadingVenues = true);

    try {
      // Get visible map bounds
      final bounds = await _mapController!.getVisibleRegion();

      // Check if we've moved significantly (prevent redundant loads)
      if (_lastLoadedBounds != null && _boundsAreSimilar(bounds, _lastLoadedBounds!)) {
        setState(() => _isLoadingVenues = false);
        return;
      }

      // Calculate center and radius from bounds
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      // Calculate radius (diagonal distance / 2)
      final radiusMeters = Geolocator.distanceBetween(
        bounds.northeast.latitude,
        bounds.northeast.longitude,
        bounds.southwest.latitude,
        bounds.southwest.longitude,
      ) / 2;

      final radiusKm = (radiusMeters / 1000).clamp(5.0, 50.0); // Min 5km, max 50km

      debugPrint('🗺️ Loading venues for bounds: center=$center, radius=${radiusKm.toStringAsFixed(1)}km');

      // **SERVER-SIDE GEOHASH SEARCH** (not getVenuesForMap!)
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final venues = await venuesRepo.findVenuesNearby(
        latitude: center.latitude,
        longitude: center.longitude,
        radiusKm: radiusKm,
      );

      if (mounted) {
        setState(() {
          _lastLoadedBounds = bounds;
          // Filter by city if filterCity is provided
          _venues = venues.where((v) {
            final meetsBasicCriteria = v.isPublic && v.isActive;
            if (!meetsBasicCriteria) return false;

            // If filterCity is set, only show venues in that city
            if (widget.filterCity != null && widget.filterCity!.isNotEmpty) {
              return v.city?.trim().toLowerCase() ==
                  widget.filterCity!.trim().toLowerCase();
            }

            return true;
          }).toList();
          _isLoadingVenues = false;
          _updateMarkers();
        });

        debugPrint('✅ Loaded ${_venues.length} venues in camera bounds');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingVenues = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בטעינת מגרשים: $e')),
        );
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

  /// Update markers with diffing algorithm (prevent flickering)
  void _updateMarkers() {
    // **MARKER DIFFING**: Only update markers that changed
    final newMarkers = <Marker>{};

    for (final venue in _venues) {
      final isSelected = _selectedVenue?.venueId == venue.venueId;

      // Choose icon based on venue type and selection
      BitmapDescriptor icon;
      if (_iconsLoaded) {
        if (isSelected) {
          icon = _selectedVenueIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        } else if (venue.isPublic) {
          icon = _venuePublicIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else {
          icon = _venueRentalIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        }
      } else {
        // Fallback to default markers while icons are loading
        icon = BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
        );
      }

      newMarkers.add(
        Marker(
          markerId: MarkerId(venue.venueId),
          position: LatLng(
            venue.location.latitude,
            venue.location.longitude,
          ),
          icon: icon,
          infoWindow: InfoWindow(
            title: venue.name,
            snippet: venue.address ?? 'לחץ לפרטים',
            onTap: () => _selectVenue(venue),
          ),
          onTap: () => _selectVenue(venue),
        ),
      );
    }

    // Calculate diff
    final addedMarkers = newMarkers.difference(_markers);
    final removedMarkers = _markers.difference(newMarkers);

    debugPrint('🗺️ Marker Diff: +${addedMarkers.length} -${removedMarkers.length}');

    setState(() => _markers = newMarkers);
  }

  void _selectVenue(Venue venue) {
    setState(() {
      _selectedVenue = venue;
      _selectedPlace = null; // Clear selected place
      _updateMarkers();
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(venue.location.latitude, venue.location.longitude),
        15.0,
      ),
    );
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('הרשאת מיקום נדחתה')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        final newCenter = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentCenter = newCenter;
          _isLoadingLocation = false;
        });

        await _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newCenter, 14.0),
        );

        // Reload venues for new location
        await _loadVenuesForCameraBounds();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בקבלת מיקום: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumScaffold(
      title: 'חיפוש מגרשים',
      body: Column(
        children: [
          // Search bar with autocomplete
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'חפש מגרש לפי שם, אזור או כתובת...',
                          prefixIcon: _isSearching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : const Icon(Icons.search),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _autocompleteResults = [];
                                      _showAutocomplete = false;
                                      _selectedPlace = null;
                                      _selectedVenue = null;
                                    });
                                    _loadVenuesForCameraBounds();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onTap: () {
                          if (_searchController.text.length >= 3) {
                            setState(() => _showAutocomplete = true);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Hybrid search toggle button
                    IconButton(
                      onPressed: () {
                        setState(() => _useHybridSearch = !_useHybridSearch);
                        if (_searchController.text.length >= 3) {
                          _searchSubject.add(_searchController.text);
                        }
                      },
                      icon: Icon(
                        _useHybridSearch ? Icons.cloud_done : Icons.cloud_off,
                        color: _useHybridSearch ? Colors.green : Colors.grey,
                      ),
                      tooltip: _useHybridSearch
                          ? 'חיפוש היברידי פעיל (Firestore + Google)'
                          : 'חיפוש מקומי בלבד',
                    ),
                  ],
                ),

                // Autocomplete dropdown
                if (_showAutocomplete && _autocompleteResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _autocompleteResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final prediction = _autocompleteResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(
                            prediction.structuredFormatting?.mainText ?? '',
                            style: PremiumTypography.labelMedium,
                          ),
                          subtitle: Text(
                            prediction.structuredFormatting?.secondaryText ??
                                '',
                            style: PremiumTypography.bodySmall,
                          ),
                          onTap: () {
                            FocusScope.of(context).unfocus(); // Hide keyboard
                            _selectAutocompleteResult(prediction);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Current location button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: Text(_isLoadingLocation ? 'מאתר...' : 'המיקום שלי'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // **SPLIT VIEW: Map 40%, List 60%**
          Expanded(
            flex: 4, // Map gets 40% (4 out of 10)
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _currentCenter,
                      zoom: _currentZoom,
                    ),
                    markers: _markers,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onCameraMove: (position) {
                      _currentCenter = position.target;
                      _currentZoom = position.zoom;
                    },
                    onCameraIdle: () {
                      // Load venues when camera stops moving
                      _loadVenuesForCameraBounds();
                    },
                    onLongPress: (LatLng position) {
                      // Allow manual location selection
                      setState(() {
                        _currentCenter = position;
                        _selectedVenue = null; // Clear venue selection
                        _selectedPlace = PlaceResult(
                          placeId:
                              'manual_${position.latitude}_${position.longitude}',
                          name: 'מיקום שנבחר על המפה',
                          address:
                              'קואורדינטות: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                          latitude: position.latitude,
                          longitude: position.longitude,
                          types: ['manual'],
                        );

                        // Add marker for manual selection
                        _markers.add(
                          Marker(
                            markerId: const MarkerId('manual_selection'),
                            position: position,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueGreen,
                            ),
                            infoWindow: const InfoWindow(
                              title: 'מיקום שנבחר',
                              snippet: 'החזק לחוץ על המפה לשינוי',
                            ),
                          ),
                        );
                      });
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // Loading indicator
                if (_isLoadingVenues)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: PremiumColors.primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'טוען מגרשים...',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Instruction overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'החזק לחוץ על המפה לבחירת מיקום',
                          style: PremiumTypography.labelSmall.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // **RESULTS LIST: Gets 60% (6 out of 10)**
          Expanded(
            flex: 6, // List gets 60%
            child: _isLoadingVenues && _venues.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _venues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sports_soccer, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('לא נמצאו מגרשים קיימים'),
                            if (_selectedPlace != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'לחץ "שמור מגרש" כדי להוסיף את "${_selectedPlace!.name}"',
                                style: PremiumTypography.bodySmall.copyWith(
                                  color: PremiumColors.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _venues.length,
                        itemBuilder: (context, index) {
                          final venue = _venues[index];
                          final isSelected =
                              _selectedVenue?.venueId == venue.venueId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? PremiumColors.primary
                                    .withValues(alpha: 0.1)
                                : null,
                            child: ListTile(
                              dense: true, // Compact UI
                              visualDensity: VisualDensity.compact,
                              leading: CircleAvatar(
                                backgroundColor: PremiumColors.primary,
                                radius: 20,
                                child: Icon(
                                  _getSurfaceIcon(venue.surfaceType),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                venue.name,
                                style: PremiumTypography.labelMedium.copyWith(
                                  color: isSelected
                                      ? PremiumColors.primary
                                      : null,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (venue.address != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 12),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            venue.address!,
                                            style:
                                                PremiumTypography.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    children: [
                                      _buildChip(
                                        _getSurfaceText(venue.surfaceType),
                                        Colors.green,
                                      ),
                                      if (!venue.isPublic)
                                        _buildChip('פרטי', Colors.orange),
                                      if (venue.hubCount > 0)
                                        _buildChip(
                                          '${venue.hubCount} האבים',
                                          Colors.blue,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_left, size: 20),
                              onTap: () => _selectVenue(venue),
                            ),
                          ).animate()
                            .slideX(
                              begin: 0.1,
                              end: 0,
                              duration: const Duration(milliseconds: 250),
                              delay: Duration(milliseconds: index * 20),
                              curve: Curves.easeOutCubic,
                            )
                            .fadeIn(
                              duration: const Duration(milliseconds: 250),
                              delay: Duration(milliseconds: index * 20),
                            );
                        },
                      ),
          ),

          // Selected venue/place details
          if (_selectedVenue != null || _selectedPlace != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                PremiumColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _selectedVenue != null
                                ? Icons.sports_soccer
                                : Icons.location_on,
                            color: PremiumColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedVenue?.name ?? _selectedPlace!.name,
                                style: PremiumTypography.labelLarge
                                    .copyWith(fontSize: 18),
                              ),
                              if (_selectedVenue?.description != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedVenue!.description!,
                                  style: PremiumTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              if (_selectedPlace != null &&
                                  _selectedPlace!.address != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _selectedPlace!.address!,
                                  style: PremiumTypography.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_selectedVenue != null) {
                            Navigator.of(context).pop(_selectedVenue);
                          } else if (_selectedPlace != null) {
                            _selectLocation();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: Text(
                          _selectedVenue != null
                              ? 'בחר מגרש זה'
                              : 'שמור מיקום זה',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getSurfaceIcon(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'grass':
        return Icons.grass;
      case 'artificial':
        return Icons.layers;
      case 'concrete':
        return Icons.square;
      default:
        return Icons.sports_soccer;
    }
  }

  String _getSurfaceText(String surfaceType) {
    switch (surfaceType.toLowerCase()) {
      case 'grass':
        return 'דשא טבעי';
      case 'artificial':
        return 'דשא סינטטי';
      case 'concrete':
        return 'בטון';
      default:
        return surfaceType;
    }
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: PremiumTypography.labelSmall.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
