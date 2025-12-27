import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kattrick/shared/domain/models/value_objects/geographic_point.dart';
import 'package:kattrick/widgets/app_scaffold.dart';
import 'package:kattrick/data/repositories_providers.dart';

/// Map picker screen - allows user to select location on map
class MapPickerScreen extends ConsumerStatefulWidget {
  final GeographicPoint? initialLocation;

  const MapPickerScreen({super.key, this.initialLocation});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String? _selectedAddress;
  bool _isLoadingAddress = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          if (_selectedLocation == null) {
            _selectedLocation = LatLng(position.latitude, position.longitude);
            _updateAddress();
          }
        });
        _updateMapCamera();
      }
    } catch (e) {
      // Ignore errors
    }
  }

  void _updateMapCamera() {
    if (_mapController != null && _selectedLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15.0),
      );
    }
  }

  Future<void> _updateAddress() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final address = await locationService.coordinatesToAddress(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      setState(() {
        _selectedAddress = address;
      });
    } catch (e) {
      // Ignore errors
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateAddress();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_selectedLocation != null) {
      _updateMapCamera();
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      final geoPoint = GeographicPoint(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
      );
      Navigator.of(context).pop({
        'location': geoPoint,
        'address': _selectedAddress ??
            '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}',
      });
    } else {
      // Show error if no location selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('אנא בחר מיקום במפה'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCameraPosition = _selectedLocation != null
        ? CameraPosition(
            target: _selectedLocation!,
            zoom: 15.0,
          )
        : _currentPosition != null
            ? CameraPosition(
                target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                zoom: 13.0,
              )
            : const CameraPosition(
                target: LatLng(31.7683, 35.2137), // Jerusalem default
                zoom: 10.0,
              );

    return AppScaffold(
      title: 'בחר מיקום',
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: GoogleMap(
                  initialCameraPosition: initialCameraPosition,
                  onMapCreated: _onMapCreated,
                  onTap: _onMapTap,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (newPosition) {
                              setState(() {
                                _selectedLocation = newPosition;
                              });
                              _updateAddress();
                            },
                          ),
                        }
                      : {},
                ),
              ),
              // Address display
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'מיקום נבחר:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingAddress)
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 8),
                              Text('טוען כתובת...'),
                            ],
                          )
                        else
                          Text(
                            _selectedAddress ?? 
                            (_selectedLocation != null
                                ? '${_selectedLocation!.latitude.toStringAsFixed(6)}, ${_selectedLocation!.longitude.toStringAsFixed(6)}'
                                : 'לא נבחר מיקום'),
                            style: TextStyle(
                              color: Colors.grey[700],
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('ביטול'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _selectedLocation != null
                                    ? _confirmSelection
                                    : null,
                                child: const Text('אישור'),
                              ),
                            ),
                          ],
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

