import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/core/providers/repositories_providers.dart';
import 'package:kattrick/services/google_places_service.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/theme/premium_theme.dart';

/// Screen for discovering and searching football venues in Israel
class DiscoverVenuesScreen extends ConsumerStatefulWidget {
  final String? filterCity;

  const DiscoverVenuesScreen({super.key, this.filterCity});

  @override
  ConsumerState<DiscoverVenuesScreen> createState() =>
      _DiscoverVenuesScreenState();
}

class _DiscoverVenuesScreenState extends ConsumerState<DiscoverVenuesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GooglePlacesService _placesService = GooglePlacesService();
  GoogleMapController? _mapController;

  // Default center: Israel center (approximately Tel Aviv)
  LatLng _currentCenter = const LatLng(32.0853, 34.7818);
  double _currentZoom = 12.0;

  List<Venue> _venues = [];
  List<Venue> _filteredVenues = [];
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

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _loadVenues();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
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

  void _onSearchChanged() {
    if (_searchController.text.length >= 3) {
      _performAutocomplete(_searchController.text);
    } else {
      setState(() {
        _autocompleteResults = [];
        _showAutocomplete = false;
      });
      _searchVenues(_searchController.text);
    }
  }

  Future<void> _performAutocomplete(String query) async {
    setState(() => _isSearching = true);

    try {
      final results = await _placesService.getAutocomplete(query);

      if (mounted) {
        setState(() {
          _autocompleteResults = results;
          _showAutocomplete = results.isNotEmpty;
          _isSearching = false;
        });
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

        _mapController?.animateCamera(
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

  Future<void> _loadVenues() async {
    setState(() => _isLoadingVenues = true);

    try {
      final venuesRepo = ref.read(venuesRepositoryProvider);
      final venues = await venuesRepo.getVenuesForMap();

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
          _filteredVenues = _venues;
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

  void _updateMarkers() {
    final markers = <Marker>{};

    for (final venue in _filteredVenues) {
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

      markers.add(
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

    setState(() => _markers = markers);
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

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(newCenter, 14.0),
        );
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

  void _searchVenues(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredVenues = _venues;
        _updateMarkers();
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredVenues = _venues.where((venue) {
        return venue.name.toLowerCase().contains(lowerQuery) ||
            (venue.address?.toLowerCase().contains(lowerQuery) ?? false) ||
            (venue.description?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
      _updateMarkers();
    });
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
                TextField(
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
                              _searchVenues('');
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
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: 8),
                // Save new venue button (if place is selected from autocomplete)
                // Removed redundant button here, moved to bottom sheet
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Map
          Expanded(
            flex: 2,
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

                // Instruction overlay
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
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
                        Flexible(
                          child: Text(
                            'החזק לחוץ על המפה לבחירת מיקום ידני',
                            style: PremiumTypography.labelSmall.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results list
          Expanded(
            flex: 1,
            child: _isLoadingVenues
                ? const Center(child: CircularProgressIndicator())
                : _filteredVenues.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                        itemCount: _filteredVenues.length,
                        itemBuilder: (context, index) {
                          final venue = _filteredVenues[index];
                          final isSelected =
                              _selectedVenue?.venueId == venue.venueId;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isSelected
                                ? PremiumColors.primary
                                    .withValues(alpha: 0.1)
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: PremiumColors.primary,
                                child: Icon(
                                  _getSurfaceIcon(venue.surfaceType),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                venue.name,
                                style: PremiumTypography.labelLarge.copyWith(
                                  color: isSelected
                                      ? PremiumColors.primary
                                      : null,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (venue.address != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 14),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            venue.address!,
                                            style:
                                                PremiumTypography.bodySmall,
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
                              trailing: const Icon(Icons.chevron_left),
                              onTap: () => _selectVenue(venue),
                            ),
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
        style: PremiumTypography.labelSmall.copyWith(color: color),
      ),
    );
  }
}
