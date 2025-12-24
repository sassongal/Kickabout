import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kattrick/widgets/common/premium_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/data/repositories.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/common/premium_card.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/widgets/premium/empty_state.dart';
import 'package:kattrick/widgets/premium/empty_state_illustrations.dart';
import 'package:kattrick/widgets/premium/skeleton_loader.dart';
import 'package:kattrick/services/location_service.dart';
import 'package:kattrick/services/error_handler_service.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/widgets/animations/scan_in_animation.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:kattrick/data/hubs_repository.dart' show HubCreationCheckResult;

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

  // Pagination state for list view
  final ScrollController _scrollController = ScrollController();
  List<Hub> _displayedHubs = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
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

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreHubs();
    }
  }

  Future<void> _loadMoreHubs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    // Get all hubs again (in a real app, you'd use cursor-based pagination)
    final hubsRepo = ref.read(hubsRepositoryProvider);
    final locationService = ref.read(locationServiceProvider);
    final allHubs = await _getHubs(hubsRepo, locationService);

    final nextIndex = _displayedHubs.length;
    final endIndex = (nextIndex + _pageSize).clamp(0, allHubs.length);

    if (nextIndex < allHubs.length) {
      setState(() {
        _displayedHubs.addAll(allHubs.sublist(nextIndex, endIndex));
        _hasMore = endIndex < allHubs.length;
        _isLoadingMore = false;
      });
    } else {
      setState(() {
        _hasMore = false;
        _isLoadingMore = false;
      });
    }
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

    final currentUserId = ref.watch(currentUserIdProvider);

    return PremiumScaffold(
      title: 'לוח הובים',
      showBottomNav: true,
      floatingActionButton: currentUserId != null
          ? FutureBuilder<HubCreationCheckResult>(
              future: hubsRepo.canCreateHub(currentUserId),
              builder: (context, snapshot) {
                final checkResult = snapshot.data;
                final canCreate = checkResult?.canCreate ?? false;
                return FloatingActionButton.extended(
                  onPressed: canCreate
                      ? () => context.push('/hubs/create')
                      : () {
                          final message = checkResult?.message ?? 
                              'הגעת למגבלה של 3 הובים שנוצרו על ידך. מחק הוב קיים כדי ליצור חדש.';
                          SnackbarHelper.showError(context, message);
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('צור הוב'),
                  backgroundColor: PremiumColors.primary,
                  foregroundColor: Colors.white,
                  tooltip: canCreate
                      ? null
                      : 'הגעת למגבלה של 3 הובים שנוצרו על ידך',
                );
              },
            )
          : null,
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
                fillColor: PremiumColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: PremiumColors.primary.withValues(alpha: 0.3),
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

  Widget _buildHubsList(
      HubsRepository hubsRepo, LocationService locationService) {
    return FutureBuilder<List<Hub>>(
      future: _getHubs(hubsRepo, locationService),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonHubCard(),
          );
        }

        if (snapshot.hasError) {
          return PremiumEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת הובים',
            message: ErrorHandlerService().handleException(
              snapshot.error,
              context: 'Hubs board screen',
            ),
          );
        }

        final allHubs = snapshot.data ?? [];

        // Initialize displayed hubs on first load or when data changes
        if (_displayedHubs.isEmpty ||
            _displayedHubs.length != allHubs.length ||
            (_displayedHubs.isNotEmpty &&
                _displayedHubs.first.hubId != allHubs.first.hubId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _displayedHubs = allHubs.take(_pageSize).toList();
                _hasMore = allHubs.length > _pageSize;
              });
            }
          });
        }

        // Use displayed hubs if available, otherwise use first page
        final hubsToShow = _displayedHubs.isNotEmpty
            ? _displayedHubs
            : allHubs.take(_pageSize).toList();
        final hasMoreToShow =
            _displayedHubs.isNotEmpty ? _hasMore : allHubs.length > _pageSize;

        if (hubsToShow.isEmpty && allHubs.isEmpty) {
          return PremiumEmptyState(
            icon: Icons.group_outlined,
            title: 'אין הובים',
            message: 'לא נמצאו הובים התואמים לחיפוש',
            illustration: const EmptyHubsIllustration(),
            action: ElevatedButton.icon(
              onPressed: () => context.push('/hubs/create'),
              icon: const Icon(Icons.add),
              label: const Text('צור הוב'),
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: hubsToShow.length + (hasMoreToShow ? 1 : 0),
          itemBuilder: (context, index) {
            // Show loading indicator at the bottom
            if (index == hubsToShow.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: KineticLoadingAnimation(size: 32)),
              );
            }
            final hub = hubsToShow[index];
            return ScanInAnimation(
              delay: Duration(milliseconds: index * 100),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Hero(
                  tag: 'hub_card_${hub.hubId}',
                  child: PremiumCard(
                    onTap: () {
                      if (hub.hubId.isNotEmpty) {
                        context.push('/hubs/${hub.hubId}');
                      }
                    },
                    child: Stack(
                      children: [
                        if (hub.bannerUrl != null)
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                hub.bannerUrl!,
                                fit: BoxFit.cover,
                                color: Colors.black.withValues(alpha: 0.6),
                                colorBlendMode: BlendMode.darken,
                              ),
                            ),
                          ),
                        Padding(
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
                                      gradient:
                                          PremiumColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      image: hub.profileImageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(
                                                  hub.profileImageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: hub.profileImageUrl == null
                                        ? const Icon(
                                            Icons.group,
                                            color: Colors.white,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          hub.name,
                                          style: PremiumTypography.heading3
                                              .copyWith(
                                            color: hub.bannerUrl != null
                                                ? Colors.white
                                                : null,
                                          ),
                                        ),
                                        if (hub.description != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            hub.description!,
                                            style: PremiumTypography
                                                .bodySmall
                                                .copyWith(
                                              color: hub.bannerUrl != null
                                                  ? Colors.white
                                                      .withValues(alpha: 0.8)
                                                  : PremiumColors
                                                      .textSecondary,
                                            ),
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
                                    color: hub.bannerUrl != null
                                        ? Colors.white70
                                        : PremiumColors.textTertiary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${hub.memberCount} חברים',
                                    style:
                                        PremiumTypography.bodySmall.copyWith(
                                      color: hub.bannerUrl != null
                                          ? Colors.white70
                                          : null,
                                    ),
                                  ),
                                  if (hub.location != null &&
                                      _currentPosition != null) ...[
                                    const SizedBox(width: 16),
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: hub.bannerUrl != null
                                          ? Colors.white70
                                          : PremiumColors.textTertiary,
                                    ),
                                    const SizedBox(width: 4),
                                    FutureBuilder<double>(
                                      future: _calculateDistance(
                                          hub.location!, _currentPosition!),
                                      builder: (context, distanceSnapshot) {
                                        final distance = distanceSnapshot.data;
                                        if (distance == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Text(
                                          '${distance.toStringAsFixed(1)} ק"מ',
                                          style: PremiumTypography.bodySmall
                                              .copyWith(
                                            color: hub.bannerUrl != null
                                                ? Colors.white70
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHubsMap(
      HubsRepository hubsRepo, LocationService locationService) {
    return FutureBuilder<List<Hub>>(
      future: _getHubs(hubsRepo, locationService).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ Timeout loading hubs for map');
          return <Hub>[]; // Return empty list on timeout
        },
      ),
      builder: (context, snapshot) {
        // Handle error state
        if (snapshot.hasError) {
          debugPrint('❌ Error loading hubs for map: ${snapshot.error}');
          return PremiumEmptyState(
            icon: Icons.error_outline,
            title: 'שגיאה בטעינת המפה',
            message: 'לא ניתן לטעון את הנתונים. נסה שוב מאוחר יותר.',
            action: ElevatedButton.icon(
              onPressed: () {
                // Force rebuild by invalidating
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
              label: const Text('נסה שוב'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PremiumLoadingState(
            message: 'טוען מפה...',
          );
        }

        final hubs = snapshot.data ?? [];
        final initialPosition = _currentPosition != null
            ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
            : const LatLng(31.7683, 35.2137); // Default to Jerusalem

        return LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialPosition,
                  zoom: 12.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: hubs.where((hub) => hub.location != null).map((hub) {
                  return Marker(
                    markerId: MarkerId(hub.hubId),
                    position: LatLng(
                      hub.location!.latitude,
                      hub.location!.longitude,
                    ),
                    infoWindow: InfoWindow(
                      title: hub.name,
                      snippet: '${hub.memberCount} חברים',
                    ),
                    onTap: () {
                      if (hub.hubId.isNotEmpty) {
                        context.push('/hubs/${hub.hubId}');
                      }
                    },
                  );
                }).toSet(),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Hub>> _getHubs(
    HubsRepository hubsRepo,
    LocationService locationService,
  ) async {
    try {
      // Add timeout to location service call
      final position = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout getting current location');
          return null;
        },
      );

      if (position == null) {
        // Fallback: get all hubs (limited to reduce load)
        return await hubsRepo.getAllHubs(limit: 50).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('⚠️ Timeout loading all hubs');
            return <Hub>[];
          },
        );
      }

      final hubs = await hubsRepo
          .findHubsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 50.0, // 50km radius
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Timeout finding nearby hubs');
          return <Hub>[];
        },
      );

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        return hubs.where((hub) {
          return hub.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (hub.description != null &&
                  hub.description!
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()));
        }).toList();
      }

      return hubs;
    } catch (e) {
      debugPrint('❌ Error in _getHubs: $e');
      // Return empty list instead of throwing
      return <Hub>[];
    }
  }

  Future<double> _calculateDistance(
      GeoPoint hubLocation, Position userPosition) async {
    return Geolocator.distanceBetween(
          userPosition.latitude,
          userPosition.longitude,
          hubLocation.latitude,
          hubLocation.longitude,
        ) /
        1000; // Convert to km
  }
}
