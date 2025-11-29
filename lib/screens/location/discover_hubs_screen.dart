import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/widgets/futuristic/empty_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';

/// Discover hubs screen - find hubs nearby
class DiscoverHubsScreen extends ConsumerStatefulWidget {
  const DiscoverHubsScreen({super.key});

  @override
  ConsumerState<DiscoverHubsScreen> createState() => _DiscoverHubsScreenState();
}

class _DiscoverHubsScreenState extends ConsumerState<DiscoverHubsScreen> {
  Position? _currentPosition;
  List<Hub> _nearbyHubs = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  double _radiusKm = 5.0; // Default 5km radius
  bool _isMapView = false; // Toggle between List and Map
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
        });
        await _searchNearbyHubs();
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
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _searchNearbyHubs() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);

      // Get all hubs and sort by distance from user location
      final allHubs = await hubsRepo.getAllHubs(limit: 1000);

      // Calculate distances and filter by radius
      final hubsWithDistance = allHubs
          .map((hub) {
            double? distance;
            if (hub.location != null) {
              distance = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    hub.location!.latitude,
                    hub.location!.longitude,
                  ) /
                  1000; // Convert to km
            } else if (hub.mainVenueId != null) {
              // If hub has main venue, we'll need to fetch it
              // For now, we'll use a large distance
              distance = 999999;
            } else {
              distance = 999999;
            }
            return MapEntry(hub, distance);
          })
          .where((entry) => entry.value <= _radiusKm)
          .toList();

      // Sort by distance (closest first)
      hubsWithDistance.sort((a, b) => a.value.compareTo(b.value));

      final hubs = hubsWithDistance.map((entry) => entry.key).toList();

      setState(() {
        _nearbyHubs = hubs;
      });

      // Update map markers if in map view
      if (_isMapView) {
        _updateMapMarkers();
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בחיפוש הובים: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} מ\'';
    }
    return '${distanceKm.toStringAsFixed(1)} ק"מ';
  }

  void _updateMapMarkers() {
    final markers = <Marker>{};

    for (final hub in _nearbyHubs) {
      if (hub.location != null) {
        final distance = _currentPosition != null
            ? Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  hub.location!.latitude,
                  hub.location!.longitude,
                ) /
                1000
            : 0.0;

        markers.add(
          Marker(
            markerId: MarkerId(hub.hubId),
            position: LatLng(
              hub.location!.latitude,
              hub.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: hub.name,
              snippet:
                  '${hub.memberCount} חברים • ${_formatDistance(distance)}',
            ),
            onTap: () {
              context.push('/hubs/${hub.hubId}');
            },
          ),
        );
      }
    }

    setState(() {
      _markers = markers;
    });

    // Update camera to show all markers
    if (_mapController != null && _markers.isNotEmpty) {
      final bounds = _calculateBounds();
      if (bounds != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 100),
        );
      }
    }
  }

  LatLngBounds? _calculateBounds() {
    if (_nearbyHubs.isEmpty || _currentPosition == null) return null;

    double minLat = _currentPosition!.latitude;
    double maxLat = _currentPosition!.latitude;
    double minLng = _currentPosition!.longitude;
    double maxLng = _currentPosition!.longitude;

    for (final hub in _nearbyHubs) {
      if (hub.location != null) {
        final lat = hub.location!.latitude;
        final lng = hub.location!.longitude;
        minLat = minLat < lat ? minLat : lat;
        maxLat = maxLat > lat ? maxLat : lat;
        minLng = minLng < lng ? minLng : lng;
        maxLng = maxLng > lng ? maxLng : lng;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'גלה הובים',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _currentPosition != null ? _searchNearbyHubs : null,
        ),
      ],
      body: _isLoadingLocation
          ? const FuturisticLoadingState(message: 'מאתר את המיקום שלך...')
          : _currentPosition == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off,
                          size: 64, color: Colors.grey),
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
              : Column(
                  children: [
                    // View Toggle (List/Map)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('רשימה'),
                            icon: Icon(Icons.list),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('מפה'),
                            icon: Icon(Icons.map),
                          ),
                        ],
                        selected: {_isMapView},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _isMapView = newSelection.first;
                            if (_isMapView) {
                              _updateMapMarkers();
                            }
                          });
                        },
                      ),
                    ),
                    // Radius selector
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'רדיוס חיפוש: ${_radiusKm.toStringAsFixed(1)} ק"מ'),
                          Slider(
                            value: _radiusKm,
                            min: 1.0,
                            max: 50.0,
                            divisions: 49,
                            label: '${_radiusKm.toStringAsFixed(1)} ק"מ',
                            onChanged: (value) {
                              setState(() {
                                _radiusKm = value;
                              });
                            },
                            onChangeEnd: (value) {
                              _searchNearbyHubs();
                            },
                          ),
                        ],
                      ),
                    ),
                    // Results (List or Map)
                    Expanded(
                      child: _isLoading
                          ? const FuturisticLoadingState(
                              message: 'מחפש הובים...')
                          : _nearbyHubs.isEmpty
                              ? FuturisticEmptyState(
                                  icon: Icons.search_off,
                                  title: 'לא נמצאו הובים',
                                  message:
                                      'לא נמצאו הובים ברדיוס של ${_radiusKm.toStringAsFixed(1)} ק"מ',
                                  action: ElevatedButton.icon(
                                    onPressed: _searchNearbyHubs,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('נסה שוב'),
                                  ),
                                )
                              : _isMapView
                                  ? _buildMapView()
                                  : _buildListView(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      itemCount: _nearbyHubs.length,
      itemBuilder: (context, index) {
        final hub = _nearbyHubs[index];
        double distance = 0;
        if (hub.location != null && _currentPosition != null) {
          distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                hub.location!.latitude,
                hub.location!.longitude,
              ) /
              1000;
        }

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: ListTile(
            leading: const Icon(Icons.group),
            title: Text(hub.name),
            subtitle: hub.description != null ? Text(hub.description!) : null,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDistance(distance),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${hub.memberCount} חברים',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            onTap: () {
              context.push('/hubs/${hub.hubId}');
            },
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return const Center(child: Text('לא ניתן להציג מפה ללא מיקום'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GoogleMap(
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
            _mapController = controller;
            _updateMapMarkers();
          },
        );
      },
    );
  }
}
