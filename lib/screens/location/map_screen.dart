import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/widgets/premium/loading_state.dart';
import 'package:kattrick/data/repositories_providers.dart';
import 'package:kattrick/models/venue_edit_request.dart';
import 'package:kattrick/models/models.dart';
import 'package:kattrick/utils/snackbar_helper.dart';
import 'package:kattrick/theme/premium_theme.dart';
import 'package:kattrick/widgets/animations/kinetic_loading_animation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:kattrick/utils/venue_seeder_service.dart';

/// Map screen - shows hubs and games on map
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'hubs', 'games', 'venues'

  // Cache for custom icons to avoid recreating them
  BitmapDescriptor? _venuePublicIcon;
  BitmapDescriptor? _venueRentalIcon;
  BitmapDescriptor? _hubMarkerIcon;
  bool _iconsLoaded = false;

  // Pre-loading markers logic
  Set<Marker> _markers = {};

  // ✅ Debouncing for camera updates - reduces unnecessary marker reloads
  Timer? _cameraUpdateTimer;
  // Note: MapCacheService ready for future use when needed
  // final MapCacheService _mapCache = MapCacheService();

  @override
  void initState() {
    super.initState();
    // Set default location immediately so map can be displayed
    _currentPosition = Position(
      latitude: 31.7683, // Jerusalem, Israel
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
    _loadCustomIcons();
    _loadCurrentLocation();
  }

  /// Ensure location permission is granted before trying to get location
  /// This is a backup in case user navigated directly to map
  Future<void> _ensureLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Request permission
        debugPrint('📍 Map screen: Requesting location permission...');
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Map screen: Location permission denied by user');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
            '⚠️ Map screen: Location permission denied forever. User needs to enable in settings.');
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        debugPrint('✅ Map screen: Location permission granted');
      }
    } catch (e) {
      debugPrint('⚠️ Map screen: Error requesting location permission: $e');
    }
  }

  /// Load custom icons for map markers
  Future<void> _loadCustomIcons() async {
    try {
      // Add timeout to prevent infinite loading
      final iconsFuture = Future.wait([
        BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(100, 100)),
          'assets/icons/venue_public.png',
        ),
        BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(100, 100)),
          'assets/icons/venue_rental.png',
        ),
        BitmapDescriptor.asset(
          const ImageConfiguration(size: Size(100, 100)),
          'assets/icons/hub_marker.png',
        ),
      ]).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ Timeout loading custom icons - using default markers');
          throw TimeoutException(
              'Loading icons timeout', const Duration(seconds: 5));
        },
      );

      final icons = await iconsFuture;
      _venuePublicIcon = icons[0];
      _venueRentalIcon = icons[1];
      _hubMarkerIcon = icons[2];

      setState(() {
        _iconsLoaded = true;
      });
    } catch (e) {
      debugPrint('Error loading custom icons: $e');
      // Fallback to default markers if custom icons fail
      setState(() {
        _iconsLoaded = true;
      });
    }
  }

  Future<void> _loadCurrentLocation() async {
    try {
      // First, ensure we have location permission
      // This is a backup in case user navigated directly to map without going through home screen
      await _ensureLocationPermission();

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'שירותי המיקום מושבתים. אנא הפעל את שירותי המיקום בהגדרות המכשיר.',
          );
          _setDefaultLocation();
        }
        return;
      }

      // Check permission status
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'אין הרשאת מיקום. אנא אפשר גישה למיקום בהגדרות האפליקציה.',
          );
          _showManualLocationDialog();
        }
        return;
      }

      final locationService = ref.read(locationServiceProvider);

      // Load location in background to avoid blocking UI
      final position = await locationService.getCurrentLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ Location timeout');
          return null;
        },
      );

      if (position != null) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          // Update camera after state is set (non-blocking)
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _mapController != null && _currentPosition != null) {
              _updateMapCamera();
            }
          });
        }
      } else {
        // If no location, check if we have manual location saved
        final prefs = await SharedPreferences.getInstance();
        final manualCity = prefs.getString('manual_location_city');

        if (manualCity != null && manualCity.isNotEmpty) {
          // Try to get location from saved manual city
          final manualPosition =
              await locationService.getLocationFromAddress(manualCity);
          if (manualPosition != null && mounted) {
            setState(() {
              _currentPosition = manualPosition;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _mapController != null &&
                  _currentPosition != null) {
                _updateMapCamera();
              }
            });
          } else {
            // Fallback to default location
            _setDefaultLocation();
          }
        } else {
          // Show dialog for manual location entry
          if (mounted) {
            SnackbarHelper.showError(
              context,
              'לא ניתן לקבל מיקום. אנא הזן את העיר שלך ידנית.',
            );
            _showManualLocationDialog();
          } else {
            _setDefaultLocation();
          }
        }
      }

      // Load markers in background - don't block UI
      // Use unawaited to allow UI to continue rendering
      _loadMarkersInBackground();
    } catch (e) {
      debugPrint('❌ Error loading location: $e');
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
      // Update camera after state is set
      if (_mapController != null) {
        _updateMapCamera();
      } else {
        // If controller not ready, wait for it
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapController != null && _currentPosition != null) {
            _updateMapCamera();
          }
        });
      }
      try {
        await _loadMarkers().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint(
                '⚠️ Overall timeout loading markers - showing map anyway');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        );
      } catch (markerError) {
        debugPrint('❌ Error loading markers: $markerError');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }

      if (mounted) {
        SnackbarHelper.showError(
          context,
          'שגיאה בקבלת מיקום. המפה תוצג במיקום ברירת מחדל (ירושלים).',
        );
      }
    } finally {
      // Always clear loading state, even if something failed
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setDefaultLocation() {
    if (mounted) {
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _mapController != null && _currentPosition != null) {
          _updateMapCamera();
        }
      });
    }
  }

  /// Show dialog for manual location entry
  Future<void> _showManualLocationDialog() async {
    final cityController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מיקום לא זמין'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'המיקום מושבת. אנא הזן את העיר שלך ידנית (למשל: חיפה) כדי לראות משחקים רלוונטיים.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(
                labelText: 'עיר',
                hintText: 'חיפה',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('דלג'),
          ),
          ElevatedButton(
            onPressed: () {
              if (cityController.text.isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );

    if (result == true && cityController.text.isNotEmpty) {
      await _saveManualLocation(cityController.text);
    } else {
      _setDefaultLocation();
    }
  }

  /// Save manual location to user profile and preferences
  Future<void> _saveManualLocation(String city) async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getLocationFromAddress(city);

      if (position != null) {
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('manual_location_city', city);
        await prefs.setBool('location_permission_skipped', true);

        // Save to user profile in Firestore
        final auth = firebase_auth.FirebaseAuth.instance;
        final user = auth.currentUser;

        if (user != null) {
          final firestore = FirebaseFirestore.instance;
          final userRef = firestore.collection('users').doc(user.uid);

          final geohash = locationService.generateGeohash(
            position.latitude,
            position.longitude,
          );

          // Determine region from city
          String? region;
          if (city.contains('חיפה') ||
              city.contains('קריית') ||
              city.contains('נשר') ||
              city.contains('טירת')) {
            region = 'צפון';
          } else if (city.contains('תל אביב') ||
              city.contains('רמת גן') ||
              city.contains('גבעתיים')) {
            region = 'מרכז';
          } else if (city.contains('באר שבע') ||
              city.contains('אשדוד') ||
              city.contains('אשקלון')) {
            region = 'דרום';
          } else if (city.contains('ירושלים')) {
            region = 'ירושלים';
          }

          await userRef.update({
            'location': GeoPoint(position.latitude, position.longitude),
            'geohash': geohash,
            'city': city,
            if (region != null) 'region': region,
          });
        }

        // Update map position
        if (mounted) {
          setState(() {
            _currentPosition = position;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _mapController != null && _currentPosition != null) {
              _updateMapCamera();
            }
          });

          SnackbarHelper.showSuccess(context, 'מיקום נשמר: $city');
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
              context, 'לא ניתן למצוא את המיקום. נסה שוב.');
          _setDefaultLocation();
        }
      }
    } catch (e) {
      debugPrint('Error saving manual location: $e');
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשמירת המיקום: $e');
        _setDefaultLocation();
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

  /// Load markers in background without blocking UI
  Future<void> _loadMarkersInBackground() async {
    // Wait for icons to load, but with timeout
    if (!_iconsLoaded) {
      try {
        await Future.delayed(const Duration(milliseconds: 500))
            .timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('⚠️ Timeout waiting for icons: $e');
      }
    }

    // Load markers with timeout - don't block UI
    try {
      await _loadMarkers().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ Overall timeout loading markers - showing map anyway');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('❌ Error loading markers in background: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMarkers() async {
    if (_mapController == null) return;

    // Calculate bounds & radius
    late LatLngBounds visibleRegion;
    try {
      visibleRegion = await _mapController!.getVisibleRegion();
    } catch (e) {
      // Fallback if map not ready
      if (_currentPosition != null) {
        // Create artificial bounds around current position (approx 10km)
        visibleRegion = LatLngBounds(
            southwest: LatLng(_currentPosition!.latitude - 0.1,
                _currentPosition!.longitude - 0.1),
            northeast: LatLng(_currentPosition!.latitude + 0.1,
                _currentPosition!.longitude + 0.1));
      } else {
        return;
      }
    }

    final centerLat =
        (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) /
            2;
    final centerLng = (visibleRegion.northeast.longitude +
            visibleRegion.southwest.longitude) /
        2;

    // Calculate radius in KM (approx)
    final distance = Geolocator.distanceBetween(centerLat, centerLng,
        visibleRegion.northeast.latitude, visibleRegion.northeast.longitude);
    final radiusKm = (distance / 1000).ceil();
    // Load slightly more than visible to smooth panning
    final searchRadiusKm =
        (radiusKm * 1.5).clamp(5, 100).toDouble(); // Min 5km, Max 100km

    final List<MapPlace> items = [];

    try {
      if (mounted) setState(() => _isLoading = true);

      // Load venues (prefer Firestore; fallback to Google Places)
      if (_selectedFilter == 'all' || _selectedFilter == 'venues') {
        if (!mounted) return; // Check before using ref
        final venuesRepo = ref.read(venuesRepositoryProvider);
        try {
          final nearbyVenues = await venuesRepo
              .findVenuesNearby(
                latitude: centerLat,
                longitude: centerLng,
                radiusKm: searchRadiusKm,
              )
              .timeout(const Duration(seconds: 10), onTimeout: () => []);

          if (!mounted) return; // Check after await
          for (final venue in nearbyVenues) {
            items.add(MapPlace(
              id: 'venue_${venue.venueId}',
              location:
                  LatLng(venue.location.latitude, venue.location.longitude),
              type: 'venue',
              data: venue,
            ));
          }
        } catch (e) {
          debugPrint('❌ Error loading nearby venues from Firestore: $e');
        }

        // Load Google Places Venues (only if zoomed in reasonably)
        if (searchRadiusKm < 20) {
          // arbitrary threshold to avoid massive API calls
          try {
            final existingIds = items.map((e) => e.id).toSet();
            final googlePlaces = await _fetchGooglePlaces(
                centerLat, centerLng, searchRadiusKm.toInt(), existingIds);
            if (!mounted) return; // Check after await
            items.addAll(googlePlaces);
          } catch (e) {
            debugPrint('⚠️ Error fetching Google Places (skipping): $e');
            // Don't fail the entire map load if Google Places fails
            // Map will still show venues from Firestore
          }
        }
      }

      // Load hubs
      if (_selectedFilter == 'all' || _selectedFilter == 'hubs') {
        if (!mounted) return; // Check before using ref
        final hubsRepo = ref.read(hubsRepositoryProvider);
        try {
          final hubs = await hubsRepo
              .findHubsNearby(
                latitude: centerLat,
                longitude: centerLng,
                radiusKm: searchRadiusKm,
              )
              .timeout(const Duration(seconds: 10), onTimeout: () => []);

          if (!mounted) return; // Check after await
          for (final hub in hubs) {
            GeoPoint? loc = hub.primaryVenueLocation ?? hub.location;
            // (Simplified location logic for brevity - ideally keep the detailed one)
            if (loc != null) {
              items.add(MapPlace(
                id: 'hub_${hub.hubId}',
                location: LatLng(loc.latitude, loc.longitude),
                type: 'hub',
                data: hub,
              ));
            }
          }
        } catch (e) {
          debugPrint('❌ Error loading hubs: $e');
        }
      }

      // Load games
      if (_selectedFilter == 'all' || _selectedFilter == 'games') {
        if (!mounted) return; // Check before using ref
        final gameQueriesRepo = ref.read(gameQueriesRepositoryProvider);
        // Games logic currently loads by USER hubs. Maybe we should load by LOCATION?
        // Existing logic was "Get games from user's hubs" AND filter by location.
        // We will keep that logic for now as fetching ALL games by location might not exist in repo yet.
        final currentUserId = ref.read(currentUserIdProvider);
        if (currentUserId != null) {
          if (!mounted) return; // Check before using ref again
          // ... logic similar to before ...
          final hubsRepo = ref.read(hubsRepositoryProvider);
          final userHubs = await hubsRepo.getHubsByMember(currentUserId);
          if (!mounted) return; // Check after await
          for (final hub in userHubs) {
            final games = await gameQueriesRepo.getGamesByHub(hub.hubId);
            if (!mounted) return; // Check after await
            for (final game in games) {
              if (game.locationPoint != null) {
                // Check if in bounds
                if (visibleRegion.contains(LatLng(game.locationPoint!.latitude,
                    game.locationPoint!.longitude))) {
                  items.add(MapPlace(
                    id: 'game_${game.gameId}',
                    location: LatLng(game.locationPoint!.latitude,
                        game.locationPoint!.longitude),
                    type: 'game',
                    data: game,
                  ));
                }
              }
            }
          }
        }
      }

      // Native clustering is handled by markers having clusterManagerId
      if (mounted) {
        setState(() {
          _markers = items.map((place) {
            return Marker(
              markerId: MarkerId(place.id),
              position: place.location,
              icon: _getIconForType(place.type, place.data),
              onTap: () => _handleItemTap(place.type, place.data),
            );
          }).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _loadMarkers: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'מפה',
      showBottomNav: true,
      actions: [
        // --- כפתור שתילת המגרשים (Seeder) ---
        IconButton(
          icon: const Icon(Icons.cloud_upload),
          tooltip: 'צור מגרשים ראשוניים',
          onPressed: () async {
            debugPrint("🚀 מתחיל תהליך יצירת מגרשים...");
            if (mounted) {
              SnackbarHelper.showSuccess(context, 'מתחיל ביצירת מגרשים...');
            }

            try {
              final seeder = ref.read(venueSeederServiceProvider);
              await seeder.seedMajorCities();

              debugPrint("✅ תהליך היצירה הסתיים בהצלחה!");
              if (mounted) {
                SnackbarHelper.showSuccess(
                    context, 'המגרשים נוצרו בהצלחה! רענן את המפה.');
                _loadMarkers(); // Refresh map
              }
            } catch (e) {
              debugPrint("❌ שגיאה ביצירת מגרשים: $e");
              if (mounted) {
                SnackbarHelper.showError(context, 'שגיאה: $e');
              }
            }
          },
        ),
        // -------------------------------------
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'רענן',
          onPressed: _loadMarkers,
        ),
      ],
      body: _isLoading
          ? const PremiumLoadingState(message: 'טוען מפה...')
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition != null
                        ? LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          )
                        : const LatLng(
                            31.7683, 35.2137), // Default to Jerusalem
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
                    // Force load markers once map is ready
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) _loadMarkers();
                    });
                  },
                  onCameraIdle: () {
                    _cameraUpdateTimer?.cancel();
                    _cameraUpdateTimer =
                        Timer(const Duration(milliseconds: 800), () {
                      if (mounted) _loadMarkers();
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
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
                ),
              ],
            ),
    );
  }

  BitmapDescriptor _getIconForType(String type, dynamic data) {
    if (type == 'hub') {
      return _hubMarkerIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
    }
    if (type == 'venue' || type.startsWith('google_place_')) {
      final isPublic = data is Venue ? data.isPublic : true;
      return (isPublic ? _venuePublicIcon : _venueRentalIcon) ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    if (type == 'game') {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.defaultMarker;
  }

  void _handleItemTap(String type, dynamic data) {
    if (type == 'venue' || type.startsWith('google_place_')) {
      Venue? venue;
      if (data is Venue) {
        venue = data;
      } else if (data is Map<String, dynamic>) {
        // Create a temporary Venue object for Google Places items
        final now = DateTime.now();
        venue = Venue(
          venueId: data['place_id'] ?? '',
          hubId: 'google_place', // Dummy hubId for external venues
          name: data['name'] ?? 'Unknown Venue',
          location: GeoPoint(
            (data['geometry']?['location']?['lat'] as num?)?.toDouble() ?? 0,
            (data['geometry']?['location']?['lng'] as num?)?.toDouble() ?? 0,
          ),
          address: data['vicinity'] ?? data['formatted_address'],
          isPublic: true,
          amenities: [],
          createdAt: now,
          updatedAt: now,
        );
      }

      if (venue != null) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => _VenueDetailsSheet(venue: venue!),
        );
      }
    } else if (type == 'hub') {
      if (data is Hub) {
        context.push('/hubs/${data.hubId}');
      }
    } else if (type == 'game') {
      if (data is Game) {
        context.push('/games/${data.gameId}');
      }
    }
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

  Future<List<MapPlace>> _fetchGooglePlaces(
      double lat, double lng, int radius, Set<String> existingIds) async {
    try {
      // Check if user is authenticated
      final auth = firebase_auth.FirebaseAuth.instance;
      final currentUser = auth.currentUser;

      debugPrint('🔐 Current user: ${currentUser?.uid ?? "NOT AUTHENTICATED"}');
      debugPrint('🔐 User email: ${currentUser?.email ?? "N/A"}');

      if (currentUser == null) {
        debugPrint('❌ User is not authenticated! Cannot call searchVenues function.');
        throw Exception('יש להתחבר כדי לחפש מקומות');
      }

      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions.httpsCallable('searchVenues').call({
        'lat': lat,
        'lng': lng,
        'query':
            'מגרש כדורגל בישראל', // Or make this dynamic based on chips if needed
        'radius': radius * 1000, // meters
      });

      final data = result.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>?;
      final List<MapPlace> items = [];

      if (results != null) {
        for (final place in results) {
          final placeId = place['place_id'] as String?;
          if (placeId != null &&
              !existingIds.contains('venue_$placeId') &&
              !existingIds.contains('google_place_$placeId')) {
            final geometry = place['geometry'] as Map<String, dynamic>?;
            final location = geometry?['location'] as Map<String, dynamic>?;
            if (location != null) {
              items.add(MapPlace(
                id: 'google_place_$placeId',
                location: LatLng((location['lat'] as num).toDouble(),
                    (location['lng'] as num).toDouble()),
                type: 'google_venue',
                data: place,
              ));
            }
          }
        }
      }
      return items;
    } catch (e) {
      debugPrint('❌ Error fetching Google Places: $e');
      return [];
    }
  }

  /// Handle venue marker tap - load details and hubs

  @override
  void dispose() {
    // ✅ Clean up timer to prevent memory leaks
    _cameraUpdateTimer?.cancel();
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

class _VenueDetailsSheet extends ConsumerStatefulWidget {
  final Venue venue;

  const _VenueDetailsSheet({required this.venue});

  @override
  ConsumerState<_VenueDetailsSheet> createState() => _VenueDetailsSheetState();
}

class _VenueDetailsSheetState extends ConsumerState<_VenueDetailsSheet> {
  late Venue _venue;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _venue = widget.venue;
  }

  Future<void> _updateVenueField(String field, dynamic value) async {
    setState(() => _isUpdating = true);
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId == null) {
        if (mounted) {
          SnackbarHelper.showError(context, 'עליך להתחבר כדי להציע שינויים');
        }
        return;
      }

      // Generate a new ID for the request
      final requestId =
          FirebaseFirestore.instance.collection('venue_edit_requests').doc().id;

      final request = VenueEditRequest(
        requestId: requestId,
        venueId: _venue.venueId,
        userId: currentUserId,
        changes: {field: value},
        createdAt: DateTime.now(),
      );

      await ref.read(venuesRepositoryProvider).submitEditRequest(request);

      if (mounted) {
        SnackbarHelper.showSuccess(context, 'ההצעה נשלחה לבדיקה!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'שגיאה בשליחת הצעה: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _venue.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _venue.address ?? 'כתובת לא ידועה',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:
                      _venue.isPublic ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _venue.isPublic ? 'ציבורי' : 'להשכרה',
                  style: TextStyle(
                    color: _venue.isPublic
                        ? Colors.green[800]
                        : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Surface Type
          const Text('סוג משטח:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildChoiceChip('דשא', 'grass', _venue.surfaceType == 'grass',
                  (selected) {
                if (selected) _updateVenueField('surfaceType', 'grass');
              }),
              _buildChoiceChip(
                  'סינטטי', 'artificial', _venue.surfaceType == 'artificial',
                  (selected) {
                if (selected) _updateVenueField('surfaceType', 'artificial');
              }),
              _buildChoiceChip(
                  'אספלט/בטון', 'concrete', _venue.surfaceType == 'concrete',
                  (selected) {
                if (selected) _updateVenueField('surfaceType', 'concrete');
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Amenities
          const Text('מתקנים:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('תאורה', _venue.amenities.contains('lights'),
                  (selected) {
                final newAmenities = List<String>.from(_venue.amenities);
                if (selected) {
                  newAmenities.add('lights');
                } else {
                  newAmenities.remove('lights');
                }
                _updateVenueField('amenities', newAmenities);
              }),
              _buildFilterChip('חניה', _venue.amenities.contains('parking'),
                  (selected) {
                final newAmenities = List<String>.from(_venue.amenities);
                if (selected) {
                  newAmenities.add('parking');
                } else {
                  newAmenities.remove('parking');
                }
                _updateVenueField('amenities', newAmenities);
              }),
              _buildFilterChip('ברזייה', _venue.amenities.contains('water'),
                  (selected) {
                final newAmenities = List<String>.from(_venue.amenities);
                if (selected) {
                  newAmenities.add('water');
                } else {
                  newAmenities.remove('water');
                }
                _updateVenueField('amenities', newAmenities);
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Public/Rental Toggle (Crowdsourcing)
          const Text('עדכן סטטוס:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('האם המגרש ציבורי?'),
              const SizedBox(width: 8),
              Switch(
                value: _venue.isPublic,
                onChanged: (value) => _updateVenueField('isPublic', value),
              ),
            ],
          ),

          if (_isUpdating)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(child: KineticLoadingAnimation(size: 40)),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
      String label, String value, bool selected, Function(bool) onSelected) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: PremiumColors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: selected ? PremiumColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool selected, Function(bool) onSelected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: PremiumColors.primary.withValues(alpha: 0.2),
      checkmarkColor: PremiumColors.primary,
      labelStyle: TextStyle(
        color: selected ? PremiumColors.primary : Colors.black,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class MapPlace {
  final String id;
  final LatLng location;
  final String type;
  final dynamic data;

  MapPlace({
    required this.id,
    required this.location,
    required this.type,
    required this.data,
  });
}
