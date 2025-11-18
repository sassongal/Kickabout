import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kickadoor/widgets/app_scaffold.dart';
import 'package:kickadoor/widgets/futuristic/loading_state.dart';
import 'package:kickadoor/data/repositories_providers.dart';
import 'package:kickadoor/models/models.dart';
import 'package:kickadoor/utils/snackbar_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Players map screen - shows all active players on the map
class PlayersMapScreen extends ConsumerStatefulWidget {
  const PlayersMapScreen({super.key});

  @override
  ConsumerState<PlayersMapScreen> createState() => _PlayersMapScreenState();
}

class _PlayersMapScreenState extends ConsumerState<PlayersMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  BitmapDescriptor? _playerMarkerIcon;
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _loadCurrentLocation();
  }

  /// Load custom icon for player markers
  Future<void> _loadCustomIcons() async {
    try {
      // Player marker should be smaller - 60x60
      final ImageConfiguration imageConfig = const ImageConfiguration(size: Size(60, 60));
      
      _playerMarkerIcon = await BitmapDescriptor.fromAssetImage(
        imageConfig,
        'assets/icons/player_marker.png',
      );
      
      setState(() {
        _iconsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading player marker icon: $e');
      // Fallback to default marker if custom icon fails
      _iconsLoaded = true;
    }
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
      
      // Load players markers
      await _loadPlayersMarkers();
    } catch (e) {
      // If location fails, still try to load players with default location
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
      await _loadPlayersMarkers();
      
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

  Future<void> _loadPlayersMarkers() async {
    final markers = <Marker>{};

    try {
      final usersRepo = ref.read(usersRepositoryProvider);
      
      // Get all active players with location
      // We'll get users that are active and have a location set
      final List<User> players;
      
      if (_currentPosition != null) {
        // Get players nearby (within 50km radius)
        // Note: This is a simplified approach - in production you might want to use geohash queries
        final allUsers = await usersRepo.getAllUsers(limit: 1000);
        players = allUsers.where((user) {
          // Filter: active users with location
          if (!user.isActive || user.location == null) return false;
          
          // Calculate distance
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            user.location!.latitude,
            user.location!.longitude,
          ) / 1000; // Convert to km
          
          return distance <= 50.0; // 50km radius
        }).toList();
      } else {
        // Get all active players with location
        final allUsers = await usersRepo.getAllUsers(limit: 1000);
        players = allUsers.where((user) {
          return user.isActive && user.location != null;
        }).toList();
      }

      // Create markers for each player
      for (final player in players) {
        if (player.location != null) {
          // Create custom icon with player's photo if available
          BitmapDescriptor icon;
          
          if (player.photoUrl != null && player.photoUrl!.isNotEmpty) {
            try {
              // Try to create custom icon from network image
              // Note: This is a simplified approach - for better performance,
              // you might want to cache these icons or use a different approach
              icon = await _createPlayerIconFromUrl(player.photoUrl!);
            } catch (e) {
              debugPrint('Error creating player icon from URL: $e');
              // Fallback to default player marker
              icon = _playerMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet,
              );
            }
          } else {
            // Use default player marker
            icon = _playerMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueViolet,
            );
          }
          
          markers.add(
            Marker(
              markerId: MarkerId('player_${player.uid}'),
              position: LatLng(
                player.location!.latitude,
                player.location!.longitude,
              ),
              infoWindow: InfoWindow(
                title: player.displayName,
                snippet: player.region != null 
                  ? '${player.region} - דירוג: ${player.currentRankScore.toStringAsFixed(1)}'
                  : 'דירוג: ${player.currentRankScore.toStringAsFixed(1)}',
              ),
              icon: icon,
              onTap: () {
                context.push('/profile/${player.uid}');
              },
            ),
          );
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
        SnackbarHelper.showError(context, 'שגיאה בטעינת שחקנים: $e');
      }
    }
  }

  /// Create a custom marker icon from player's photo URL
  /// Note: This is a simplified approach - for production, consider caching
  Future<BitmapDescriptor> _createPlayerIconFromUrl(String photoUrl) async {
    // For now, we'll use the default player marker
    // Creating custom icons from network images requires more complex handling
    // You might want to use a package like `flutter_cache_manager` and `image` package
    // to download, resize, and convert the image to a BitmapDescriptor
    return _playerMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueViolet,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'שחקנים על המפה',
      showBottomNav: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _loadPlayersMarkers,
        ),
      ],
      body: _isLoading || !_iconsLoaded
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
                    // Info card
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_markers.length - 1} שחקנים פעילים באזור',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
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

  @override
  void dispose() {
    // Safely dispose map controller
    if (_mapController != null) {
      try {
        _mapController!.dispose();
      } catch (e) {
        debugPrint('Error disposing map controller (expected on Web): $e');
      }
    }
    super.dispose();
  }
}

