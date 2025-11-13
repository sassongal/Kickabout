import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/services/location_service.dart';
import 'package:kickadoor/services/hub_venue_matcher_service.dart';
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
      // Use HubVenueMatcherService for smarter matching
      final matcherService = ref.read(hubVenueMatcherServiceProvider);
      final results = await matcherService.findRelevantHubs(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: _radiusKm,
        maxResults: 50,
      );

      // Extract hubs from results
      final hubs = results.map((r) => r.hub).toList();

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
          onPressed: _currentPosition != null ? _searchNearbyHubs : null,
        ),
      ],
      body: _isLoadingLocation
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
              : Column(
                  children: [
                    // Radius selector
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('רדיוס חיפוש: ${_radiusKm.toStringAsFixed(1)} ק"מ'),
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
                    // Results
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _nearbyHubs.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.search_off,
                                          size: 64, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      Text('לא נמצאו הובים ברדיוס של ${_radiusKm.toStringAsFixed(1)} ק"מ'),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _nearbyHubs.length,
                                  itemBuilder: (context, index) {
                                    final hub = _nearbyHubs[index];
                                    final distance = Geolocator.distanceBetween(
                                      _currentPosition!.latitude,
                                      _currentPosition!.longitude,
                                      hub.location?.latitude ?? 0,
                                      hub.location?.longitude ?? 0,
                                    ) / 1000;

                                    return Card(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        leading: const Icon(Icons.group),
                                        title: Text(hub.name),
                                        subtitle: hub.description != null
                                            ? Text(hub.description!)
                                            : null,
                                        trailing: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              _formatDistance(distance),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              '${hub.memberIds.length} חברים',
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
                                ),
                    ),
                  ],
                ),
    );
  }
}

