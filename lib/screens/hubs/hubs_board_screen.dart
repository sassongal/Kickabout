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

  final List<Hub> _allHubs = [];
  List<Hub> _filteredHubs = [];
  bool _isLoadingHubs = true;
  Object? _hubsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _loadCurrentLocation();
    if (mounted) {
      await _loadHubs();
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();
      if (mounted && position != null) {
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
      if (mounted) {
        setState(() {
          _hubsError = e;
        });
      }
    }
  }

  Future<void> _loadHubs() async {
    setState(() {
      _isLoadingHubs = true;
      _hubsError = null;
    });

    final hubsRepo = ref.read(hubsRepositoryProvider);
    final position = _currentPosition;

    if (position == null) {
      setState(() {
        _allHubs.clear();
        _filteredHubs = const [];
        _isLoadingHubs = false;
        _hubsError ??= Exception('לא ניתן היה לאתר את מיקומך לצורך הצגת הובים קרובים.');
      });
      return;
    }

    try {
      final hubs = await hubsRepo.findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0,
      );

      if (!mounted) return;

      final filtered = _filterHubs(hubs, _searchQuery);
      setState(() {
        _allHubs
          ..clear()
          ..addAll(hubs);
        _filteredHubs = filtered;
        _isLoadingHubs = false;
        _hubsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allHubs.clear();
        _filteredHubs = const [];
        _isLoadingHubs = false;
        _hubsError = e;
      });
    }
  }

  List<Hub> _filterHubs(List<Hub> hubs, String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return List<Hub>.of(hubs);
    }

    return hubs.where((hub) {
      final name = hub.name.toLowerCase();
      final description = hub.description?.toLowerCase();
      return name.contains(normalized) ||
          (description != null && description.contains(normalized));
    }).toList();
  }

  double? _distanceFromUser(GeoPoint location) {
    final userPosition = _currentPosition;
    if (userPosition == null) return null;

    final meters = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      location.latitude,
      location.longitude,
    );

    return meters / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticScaffold(
      title: 'לוח הובים',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filteredHubs = _filterHubs(_allHubs, value);
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
                            _filteredHubs = _filterHubs(_allHubs, '');
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
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.list), text: 'רשימה'),
              Tab(icon: Icon(Icons.map), text: 'מפה'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHubsList(),
                _buildHubsMap(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubsList() {
    if (_isLoadingHubs) {
      return const FuturisticLoadingState(message: 'טוען הובים...');
    }

    if (_hubsError != null) {
      return FuturisticEmptyState(
        icon: Icons.error_outline,
        title: 'שגיאה בטעינת הובים',
        message: _hubsError.toString(),
        action: ElevatedButton.icon(
          onPressed: _loadHubs,
          icon: const Icon(Icons.refresh),
          label: const Text('נסה שוב'),
        ),
      );
    }

    if (_filteredHubs.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadHubs,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filteredHubs.length,
        itemBuilder: (context, index) {
          final hub = _filteredHubs[index];
          final distanceKm =
              hub.location != null ? _distanceFromUser(hub.location!) : null;

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
                        if (distanceKm != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: FuturisticColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} ק"מ',
                            style: FuturisticTypography.bodySmall,
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
      ),
    );
  }

  Widget _buildHubsMap() {
    if (_isLoadingHubs) {
      return const FuturisticLoadingState(message: 'טוען מפה...');
    }

    if (_hubsError != null) {
      return FuturisticEmptyState(
        icon: Icons.error_outline,
        title: 'שגיאה בטעינת מפה',
        message: _hubsError.toString(),
        action: ElevatedButton.icon(
          onPressed: () async {
            await _loadCurrentLocation();
            await _loadHubs();
          },
          icon: const Icon(Icons.my_location),
          label: const Text('נסה שוב'),
        ),
      );
    }

    if (_filteredHubs.isEmpty) {
      return FuturisticEmptyState(
        icon: Icons.map_outlined,
        title: 'אין הובים להצגה במפה',
        message: 'שנה את החיפוש או צור הוב חדש.',
        action: ElevatedButton.icon(
          onPressed: () => context.push('/hubs/create'),
          icon: const Icon(Icons.add),
          label: const Text('צור הוב'),
        ),
      );
    }

    final initialPosition = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(
            _filteredHubs.first.location?.latitude ?? 31.7683,
            _filteredHubs.first.location?.longitude ?? 35.2137,
          );

    final markers = _filteredHubs
        .where((hub) => hub.location != null)
        .map(
          (hub) => Marker(
            markerId: MarkerId(hub.hubId),
            position: LatLng(
              hub.location!.latitude,
              hub.location!.longitude,
            ),
            infoWindow: InfoWindow(
              title: hub.name,
              snippet: '${hub.memberIds.length} חברים',
            ),
            onTap: () => context.push('/hubs/${hub.hubId}'),
          ),
        )
        .toSet();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 12.0,
      ),
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: _currentPosition != null,
      myLocationButtonEnabled: true,
      markers: markers,
    );
  }
}

