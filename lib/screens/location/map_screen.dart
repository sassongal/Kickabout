import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickabout/widgets/app_scaffold.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/services/location_service.dart';
import 'package:kickabout/utils/snackbar_helper.dart';

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
  String _selectedFilter = 'all'; // 'all', 'hubs', 'games'

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
        await _loadMarkers();
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'לא ניתן לקבל מיקום. אנא בדוק את ההרשאות.',
          );
        }
      }
    } catch (e) {
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
    final position = _currentPosition;
    if (position == null) return;

    final markers = <Marker>{};

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Load hubs (parallel with games fetching where possible)
      List<Hub> nearbyHubs = const [];
      if (_selectedFilter == 'all' || _selectedFilter == 'hubs') {
        nearbyHubs = await hubsRepo.findHubsNearby(
          latitude: position.latitude,
          longitude: position.longitude,
          radiusKm: 50.0,
        );

        for (final hub in nearbyHubs) {
          final hubLocation = hub.location;
          if (hubLocation == null) continue;
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
              onTap: () => context.push('/hubs/${hub.hubId}'),
            ),
          );
        }
      }

      // Load games (deferred and batched)
      if (_selectedFilter == 'all' || _selectedFilter == 'games') {
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          final gamesRepo = ref.read(gamesRepositoryProvider);
          final userHubs = await hubsRepo.getHubsByMember(currentUserId);
          if (userHubs.isNotEmpty) {
            final gameLists = await Future.wait(
              userHubs.map((hub) => gamesRepo.getGamesByHub(hub.hubId)),
            );

            final seenGameIds = <String>{};

            for (var i = 0; i < userHubs.length; i++) {
              final games = gameLists[i];
              for (final game in games) {
                if (game.locationPoint == null ||
                    !seenGameIds.add(game.gameId)) {
                  continue;
                }

                final distanceKm = Geolocator.distanceBetween(
                      position.latitude,
                      position.longitude,
                      game.locationPoint!.latitude,
                      game.locationPoint!.longitude,
                    ) /
                    1000;

                if (distanceKm <= 50.0) {
                  final dateFormat =
                      '${game.gameDate.day}/${game.gameDate.month}';
                  final timeFormat =
                      '${game.gameDate.hour}:${game.gameDate.minute.toString().padLeft(2, '0')}';

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
                      onTap: () => context.push('/games/${game.gameId}'),
                    ),
                  );
                }
              }
            }
          }
        }
      }

      // Add current location marker
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            position.latitude,
            position.longitude,
          ),
          infoWindow: const InfoWindow(title: 'מיקום נוכחי'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
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
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _loadMarkers,
        ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('לא ניתן לקבל מיקום'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCurrentLocation,
                        child: const Text('נסה שוב'),
                      ),
                    ],
                  ),
                )
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

