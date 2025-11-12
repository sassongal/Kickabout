import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kickabout/widgets/futuristic/futuristic_scaffold.dart';
import 'package:kickabout/data/repositories_providers.dart';
import 'package:kickabout/data/repositories.dart';
import 'package:kickabout/models/models.dart';
import 'package:kickabout/theme/futuristic_theme.dart';
import 'package:kickabout/widgets/futuristic/futuristic_card.dart';
import 'package:kickabout/widgets/futuristic/loading_state.dart';
import 'package:kickabout/widgets/futuristic/empty_state.dart';
import 'package:kickabout/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Hubs Board Screen - לוח הובים עם מפה
class HubsBoardScreen extends ConsumerStatefulWidget {
  const HubsBoardScreen({super.key});

  @override
  ConsumerState<HubsBoardScreen> createState() => _HubsBoardScreenState();
}

class _HubsBoardScreenState extends ConsumerState<HubsBoardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  GoogleMapController? _mapController;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            12.0,
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = ref.watch(locationServiceProvider);
    final hubsRepo = ref.watch(hubsRepositoryProvider);

    return FuturisticScaffold(
      title: 'לוח הובים',
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'חפש הוב...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: FuturisticColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: FuturisticColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'רשימה'),
              Tab(icon: Icon(Icons.map), text: 'מפה'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // List view
                _buildHubsList(hubsRepo, locationService),
                // Map view
                _buildHubsMap(hubsRepo, locationService),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubsList(HubsRepository hubsRepo, LocationService locationService) {
    return FutureBuilder<List<Hub>>(
      future: _getHubs(hubsRepo, locationService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(
            message: 'טוען הובים...',
          );
        }

        if (snapshot.hasError) {
          return FuturisticEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת הובים',
            message: snapshot.error.toString(),
          );
        }

        final hubs = snapshot.data ?? [];
        if (hubs.isEmpty) {
          return FuturisticEmptyState(
            icon: Icons.group_outlined,
            title: 'אין הובים',
            message: 'לא נמצאו הובים התואמים לחיפוש',
            action: ElevatedButton.icon(
              onPressed: () => context.push('/hubs/create'),
              icon: const Icon(Icons.add),
              label: const Text('צור הוב'),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: hubs.length,
          itemBuilder: (context, index) {
            final hub = hubs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: FuturisticCard(
                onTap: () => context.push('/hubs/${hub.hubId}'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: FuturisticColors.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hub.name,
                                  style: FuturisticTypography.heading3,
                                ),
                                if (hub.description != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    hub.description!,
                                    style: FuturisticTypography.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: FuturisticColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${hub.memberIds.length} חברים',
                            style: FuturisticTypography.bodySmall,
                          ),
                          if (hub.location != null && _currentPosition != null) ...[
                            const SizedBox(width: 16),
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: FuturisticColors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            FutureBuilder<double>(
                              future: _calculateDistance(hub.location!, _currentPosition!),
                              builder: (context, distanceSnapshot) {
                                final distance = distanceSnapshot.data;
                                if (distance == null) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${distance.toStringAsFixed(1)} ק"מ',
                                  style: FuturisticTypography.bodySmall,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHubsMap(HubsRepository hubsRepo, LocationService locationService) {
    return FutureBuilder<List<Hub>>(
      future: _getHubs(hubsRepo, locationService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FuturisticLoadingState(
            message: 'טוען מפה...',
          );
        }

        final hubs = snapshot.data ?? [];
        final initialPosition = _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(31.7683, 35.2137); // Default to Jerusalem

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 12.0,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          markers: hubs
              .where((hub) => hub.location != null)
              .map((hub) {
                return Marker(
                  markerId: MarkerId(hub.hubId),
                  position: LatLng(
                    hub.location!.latitude,
                    hub.location!.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: hub.name,
                    snippet: '${hub.memberIds.length} חברים',
                  ),
                  onTap: () {
                    context.push('/hubs/${hub.hubId}');
                  },
                );
              })
              .toSet(),
        );
      },
    );
  }

  Future<List<Hub>> _getHubs(
    HubsRepository hubsRepo,
    LocationService locationService,
  ) async {
    try {
      final position = await locationService.getCurrentLocation();
      if (position == null) {
        // Fallback: get all hubs (limited)
        return [];
      }

      final hubs = await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0, // 50km radius
      );

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return hubs.where((hub) {
          return hub.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (hub.description != null &&
                  hub.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
        }).toList();
      }

      return hubs;
    } catch (e) {
      return [];
    }
  }

  Future<double> _calculateDistance(GeoPoint hubLocation, Position userPosition) async {
    return Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      hubLocation.latitude,
      hubLocation.longitude,
    ) / 1000; // Convert to km
  }
}

