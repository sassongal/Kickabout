import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

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
          // Add hub marker (if has primary location)
          if (hub.location != null) {
            markers.add(
              Marker(
                markerId: MarkerId('hub_${hub.hubId}'),
                position: LatLng(
                  hub.location!.latitude,
                  hub.location!.longitude,
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

      // Load venues only
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
          : Stack(
                  children: [
                    GoogleMap(
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

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

