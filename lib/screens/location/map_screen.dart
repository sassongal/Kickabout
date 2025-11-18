import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/futuristic_card.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:kickadoor/theme/futuristic_theme.dart';

/// Map screen - shows hubs and games on map
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'hubs', 'games', 'venues'

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        _updateMapCamera();
      } else {
        // If no location, set default to Israel center (Jerusalem)
        setState(() {
          _currentPosition = Position(
            latitude: 31.7683,
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
        });
        _updateMapCamera();
      }
      
      // Load markers regardless of location
      await _loadMarkers();
    } catch (e) {
      // If location fails, still try to load hubs with default location
      setState(() {
        _currentPosition = Position(
          latitude: 31.7683,
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
      });
      _updateMapCamera();
      await _loadMarkers();
      
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בקבלת מיקום: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMapCamera() {
    if (_mapController != null && _currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          13.0,
        ),
      );
    }
  }

  Future<void> _loadMarkers() async {
    final markers = <Marker>{};

    try {
      // Load Google Places venues (football fields in Israel)
      if (_selectedFilter == 'all' || _selectedFilter == 'venues') {
        await _loadGooglePlacesVenues(markers);
      }

      // Load hubs and their venues
      if (_selectedFilter == 'all' || _selectedFilter == 'hubs') {
        final hubsRepo = ref.read(hubsRepositoryProvider);
        final venuesRepo = ref.read(venuesRepositoryProvider);
        
        // Get all hubs (or nearby if we have location)
        final List<Hub> hubs;
        if (_currentPosition != null) {
          hubs = await hubsRepo.findHubsNearby(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 50.0, // 50km radius
          );
        } else {
          // Load all hubs if no location available
          hubs = await hubsRepo.getAllHubs(limit: 200);
        }

        for (final hub in hubs) {
          // Add hub marker - use mainVenueId location if available, otherwise use hub.location
          GeoPoint? hubLocation = hub.location;
          
          // If hub has mainVenueId but no location, get location from main venue
          if (hubLocation == null && hub.mainVenueId != null && hub.mainVenueId!.isNotEmpty) {
            try {
              final mainVenue = await venuesRepo.getVenue(hub.mainVenueId!);
              if (mainVenue != null) {
                hubLocation = mainVenue.location;
              }
            } catch (e) {
              debugPrint('Error loading main venue for hub ${hub.hubId}: $e');
            }
          }
          
          if (hubLocation != null) {
            markers.add(
              Marker(
                markerId: MarkerId('hub_${hub.hubId}'),
                position: LatLng(
                  hubLocation.latitude,
                  hubLocation.longitude,
                ),
                infoWindow: InfoWindow(
                  title: hub.name,
                  snippet: hub.description ?? '${hub.memberIds.length} חברים',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                onTap: () {
                  context.push('/hubs/${hub.hubId}');
                },
              ),
            );
          }

          // Add venue markers for this hub
          if (hub.venueIds.isNotEmpty) {
            final venues = await venuesRepo.getVenuesByHub(hub.hubId);
            for (final venue in venues) {
              markers.add(
                Marker(
                  markerId: MarkerId('venue_${venue.venueId}'),
                  position: LatLng(
                    venue.location.latitude,
                    venue.location.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: venue.name,
                    snippet: '${hub.name} - ${venue.address ?? "מגרש"}',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueOrange, // Orange for venues
                  ),
                  onTap: () {
                    context.push('/hubs/${hub.hubId}');
                  },
                ),
              );
            }
          }
        }
      }

      // Load internal venues (from our database)
      if (_selectedFilter == 'venues') {
        final venuesRepo = ref.read(venuesRepositoryProvider);
        final List<Venue> venues;
        if (_currentPosition != null) {
          venues = await venuesRepo.findVenuesNearby(
            latitude: _currentPosition!.latitude,
            longitude: _currentPosition!.longitude,
            radiusKm: 50.0,
          );
        } else {
          // If no location, get venues from all hubs
          final hubsRepo = ref.read(hubsRepositoryProvider);
          final allHubs = await hubsRepo.getAllHubs(limit: 200);
          venues = [];
          for (final hub in allHubs) {
            final hubVenues = await venuesRepo.getVenuesByHub(hub.hubId);
            venues.addAll(hubVenues);
          }
        }

        for (final venue in venues) {
          markers.add(
            Marker(
              markerId: MarkerId('venue_${venue.venueId}'),
              position: LatLng(
                venue.location.latitude,
                venue.location.longitude,
              ),
              infoWindow: InfoWindow(
                title: venue.name,
                snippet: venue.address ?? 'מגרש',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                // Navigate to hub that owns this venue
                if (venue.hubId.isNotEmpty) {
                  context.push('/hubs/${venue.hubId}');
                }
              },
            ),
          );
        }
      }

      // Load games
      if (_selectedFilter == 'all' || _selectedFilter == 'games') {
        final gamesRepo = ref.read(gamesRepositoryProvider);
        // Get games from user's hubs
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          final hubsRepo = ref.read(hubsRepositoryProvider);
          final userHubs = await hubsRepo.getHubsByMember(currentUserId);
          
          for (final hub in userHubs) {
            final games = await gamesRepo.getGamesByHub(hub.hubId);
            for (final game in games) {
              if (game.locationPoint != null) {
                // If we have current position, filter by distance
                if (_currentPosition != null) {
                  final distance = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    game.locationPoint!.latitude,
                    game.locationPoint!.longitude,
                  ) / 1000;

                  if (distance > 50.0) continue;
                }
                
                final dateFormat = '${game.gameDate.day}/${game.gameDate.month}';
                final timeFormat = '${game.gameDate.hour}:${game.gameDate.minute.toString().padLeft(2, '0')}';
                markers.add(
                  Marker(
                    markerId: MarkerId('game_${game.gameId}'),
                    position: LatLng(
                      game.locationPoint!.latitude,
                      game.locationPoint!.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title: 'משחק',
                      snippet: '$dateFormat $timeFormat',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ),
                    onTap: () {
                      context.push('/games/${game.gameId}');
                    },
                  ),
                );
              }
            }
          }
        }
      }

      // Add current location marker
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(title: 'מיקום נוכחי'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בטעינת מגרשים: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'מפה',
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _loadMarkers,
        ),
      ],
      body: _isLoading
          ? const FuturisticLoadingState(message: 'טוען מפה...')
          : LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: _currentPosition != null
                          ? GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 13.0,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              mapType: MapType.normal,
                              onMapCreated: (controller) {
                                setState(() {
                                  _mapController = controller;
                                });
                              },
                            )
                          : const Center(
                              child: CircularProgressIndicator(),
                            ),
                    ),
                    // Filter buttons
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildFilterChip('all', 'הכל'),
                              const SizedBox(width: 8),
                              _buildFilterChip('hubs', 'הובים'),
                              const SizedBox(width: 8),
                              _buildFilterChip('games', 'משחקים'),
                              const SizedBox(width: 8),
                              _buildFilterChip('venues', 'מגרשים'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
          _loadMarkers();
        }
      },
    );
  }

  /// Load Google Places venues (football fields)
  Future<void> _loadGooglePlacesVenues(Set<Marker> markers) async {
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      
      // Build query based on location
      String query = 'מגרש כדורגל בישראל';
      Map<String, dynamic> callData = {'query': query};
      
      if (_currentPosition != null) {
        callData['lat'] = _currentPosition!.latitude;
        callData['lng'] = _currentPosition!.longitude;
      }

      final result = await functions.httpsCallable('searchVenues').call(callData);
      final data = result.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;

      if (results != null) {
        for (final place in results) {
          final placeId = place['place_id'] as String?;
          final name = place['name'] as String?;
          final geometry = place['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;

          if (placeId != null && name != null && location != null) {
            markers.add(
              Marker(
                markerId: MarkerId('google_place_$placeId'),
                position: LatLng(
                  (location['lat'] as num).toDouble(),
                  (location['lng'] as num).toDouble(),
                ),
                infoWindow: InfoWindow(
                  title: name,
                  snippet: 'לחץ לפרטים',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen, // Green for Google Places venues
                ),
                onTap: () => _onVenueMarkerTapped(placeId),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading Google Places venues: $e');
      // Don't show error to user - just log it
    }
  }

  /// Handle venue marker tap - load details and hubs
  Future<void> _onVenueMarkerTapped(String placeId) async {
    // Show loading indicator
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      
      // Call both functions in parallel
      final detailsCall = functions.httpsCallable('getPlaceDetails').call({
        'placeId': placeId,
      });
      final hubsCall = functions.httpsCallable('getHubsForPlace').call({
        'placeId': placeId,
      });

      final results = await Future.wait([detailsCall, hubsCall]);

      final detailsData = results[0].data as Map<String, dynamic>;
      final hubsData = results[1].data;
      
      final Map<String, dynamic> placeDetails = Map<String, dynamic>.from(
        detailsData['result'] as Map<String, dynamic>,
      );
      final List<dynamic> hubs = hubsData is List<dynamic>
          ? List<dynamic>.from(hubsData)
          : <dynamic>[];

      // Close loading indicator
      if (!mounted) return;
      Navigator.pop(context);

      // Show venue details sheet
      _showVenueDetailsSheet(context, placeDetails, hubs);
    } catch (e) {
      // Handle error
      if (!mounted) return;
      Navigator.pop(context);
      SnackbarHelper.showError(context, 'שגיאה בטעינת פרטי המגרש: $e');
    }
  }

  /// Show venue details in a bottom sheet
  void _showVenueDetailsSheet(
    BuildContext context,
    Map<String, dynamic> placeDetails,
    List<dynamic> hubs,
  ) {
    final name = placeDetails['name'] as String? ?? 'מגרש';
    final address = placeDetails['formatted_address'] as String?;
    final phone = placeDetails['formatted_phone_number'] as String?;
    
    // Note: Google Places Photo API requires API key and photo_reference
    // For now, we'll skip displaying photos directly (would need backend endpoint)
    // In production, you could create a Cloud Function that returns photo URLs

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: FuturisticColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FuturisticColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo placeholder (Google Places photos require API key)
                      FuturisticCard(
                        padding: const EdgeInsets.all(40),
                        margin: EdgeInsets.zero,
                        child: Icon(
                          Icons.sports_soccer,
                          size: 80,
                          color: FuturisticColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Name
                      Text(
                        name,
                        style: FuturisticTypography.heading2,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Address
                      if (address != null && address.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 20,
                              color: FuturisticColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                address,
                                style: FuturisticTypography.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Phone
                      if (phone != null && phone.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 20,
                              color: FuturisticColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              phone,
                              style: FuturisticTypography.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Hubs section
                      if (hubs.isNotEmpty) ...[
                        Divider(color: FuturisticColors.surfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'האבים שמשחקים כאן',
                          style: FuturisticTypography.techHeadline,
                        ),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: hubs.length,
                          itemBuilder: (context, index) {
                            final hub = hubs[index] as Map<String, dynamic>;
                            final hubId = hub['hubId'] as String;
                            final hubName = hub['name'] as String? ?? 'האב';
                            final logoUrl = hub['logoUrl'] as String?;
                            
                            return FuturisticCard(
                              margin: const EdgeInsets.only(bottom: 8),
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/hubs/$hubId');
                              },
                              child: ListTile(
                                leading: logoUrl != null
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(logoUrl),
                                        radius: 24,
                                      )
                                    : CircleAvatar(
                                        backgroundColor: FuturisticColors.primary,
                                        radius: 24,
                                        child: Text(
                                          hubName[0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                title: Text(
                                  hubName,
                                  style: FuturisticTypography.labelLarge,
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: FuturisticColors.textSecondary,
                                ),
                              ),
                            );
                          },
                        ),
                      ] else ...[
                        Divider(color: FuturisticColors.surfaceVariant),
                        const SizedBox(height: 12),
                        Text(
                          'אין האבים שמשחקים במגרש זה',
                          style: FuturisticTypography.bodyMedium.copyWith(
                            color: FuturisticColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Safely dispose map controller - handle web platform issue
    // On Web, the map might not be fully initialized when dispose is called
    if (_mapController != null) {
      try {
        // Check if controller is still valid before disposing
        // On Web, the controller might already be disposed by the map widget
        _mapController!.dispose();
      } catch (e) {
        // Ignore errors during dispose (web platform may throw if map not fully initialized)
        // This is expected behavior on Web when the map is disposed before controller is ready
        debugPrint('Error disposing map controller (expected on Web): $e');
      }
    }
    super.dispose();
  }
}

