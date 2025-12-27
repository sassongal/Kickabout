import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/map/unified_map_widget.dart';
import 'package:kattrick/widgets/map/map_mode.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';

/// Discover hubs screen - find hubs nearby
///
/// Refactored to use UnifiedMapWidget for map view while preserving
/// list view and unique features (location fallback, radius selector).
class DiscoverHubsScreen extends ConsumerStatefulWidget {
  const DiscoverHubsScreen({super.key});

  @override
  ConsumerState<DiscoverHubsScreen> createState() => _DiscoverHubsScreenState();
}

enum LocationStatus {
  loading,
  success,
  denied,
  error,
  defaultFallback,
}

class _DiscoverHubsScreenState extends ConsumerState<DiscoverHubsScreen> {
  Position? _currentPosition;
  List<Hub> _nearbyHubs = [];
  bool _isLoading = false;
  bool _isLoadingLocation = false;
  LocationStatus _locationStatus = LocationStatus.loading;
  double _radiusKm = 5.0;
  bool _isMapView = false; // Toggle between List and Map

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = LocationStatus.loading;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          _locationStatus = LocationStatus.success;
        });
        await _searchNearbyHubs();
      } else {
        setState(() {
          _currentPosition = null;
          _locationStatus = LocationStatus.denied;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _currentPosition = null;
        _locationStatus = LocationStatus.error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _useDefaultLocation() async {
    final defaultLocation = Position(
      longitude: 34.7818,
      latitude: 32.0853,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );

    setState(() {
      _currentPosition = defaultLocation;
      _locationStatus = LocationStatus.defaultFallback;
    });
    await _searchNearbyHubs();
  }

  Future<void> _searchNearbyHubs() async {
    if (_currentPosition == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final hubsRepo = ref.read(hubsRepositoryProvider);
      final hubs = await hubsRepo.findHubsNearby(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _radiusKm,
      );

      setState(() {
        _nearbyHubs = hubs;
      });
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'גלה הובים',
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: (_currentPosition != null &&
                  _locationStatus != LocationStatus.denied &&
                  _locationStatus != LocationStatus.error)
              ? _searchNearbyHubs
              : null,
        ),
      ],
      body: _isLoadingLocation
          ? const PremiumLoadingState(message: 'מאתר את המיקום שלך...')
          : _currentPosition == null
              ? _buildLocationErrorState()
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

                    // Location status banner
                    if (_locationStatus == LocationStatus.defaultFallback)
                      _buildLocationBanner(),

                    // Results (List or Map)
                    Expanded(
                      child: _isLoading
                          ? const PremiumLoadingState(message: 'מחפש הובים...')
                          : _nearbyHubs.isEmpty
                              ? PremiumEmptyState(
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
                                  ? UnifiedMapWidget(
                                      mode: MapMode.exploreHubs,
                                      initialPosition: _currentPosition,
                                      initialRadius: _radiusKm,
                                    )
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
        final hubLocation = hub.primaryVenueLocation ?? hub.location;
        double distance = 0;

        if (hubLocation != null && _currentPosition != null) {
          distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                hubLocation.latitude,
                hubLocation.longitude,
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
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${hub.memberCount} חברים',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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

  Widget _buildLocationErrorState() {
    final isDenied = _locationStatus == LocationStatus.denied;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDenied ? Icons.location_disabled : Icons.location_off,
              size: 80,
              color: Colors.orange,
            ),
            const SizedBox(height: 24),
            Text(
              isDenied ? 'הרשאת מיקום נדחתה' : 'שגיאה באיתור המיקום',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isDenied
                  ? 'אנחנו לא יכולים למצוא הובים בקרבתך ללא הרשאת מיקום.\n'
                      'אפשר לחפש בתל אביב כברירת מחדל או לפתוח הגדרות כדי לאפשר מיקום.'
                  : 'לא הצלחנו לאתר את המיקום שלך.\n'
                      'אפשר לחפש בתל אביב כברירת מחדל או לנסות שוב.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDenied)
                  ElevatedButton.icon(
                    onPressed: () => Geolocator.openAppSettings(),
                    icon: const Icon(Icons.settings),
                    label: const Text('פתח הגדרות'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                if (isDenied) const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _useDefaultLocation,
                  icon: const Icon(Icons.location_city),
                  label: const Text('חפש בתל אביב'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _loadCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('נסה שוב'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'מציג תוצאות בתל אביב כברירת מחדל. לחץ על "רענן" כדי לנסות לאתר את המיקום שלך.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _loadCurrentLocation,
            child: Text(
              'נסה שוב',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
