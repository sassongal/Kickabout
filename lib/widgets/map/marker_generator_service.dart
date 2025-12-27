import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kattrick/widgets/map/stadium_marker_painter.dart';
import 'package:kattrick/widgets/map/map_mode.dart';

/// Service for generating custom map markers with caching
///
/// This service:
/// - Generates premium 3D markers using CustomPainter
/// - Caches BitmapDescriptors to avoid recreating them
/// - Detects device capability and uses simple markers on low-end devices
/// - Provides fallback to default markers if generation fails
class MarkerGeneratorService {
  // Singleton pattern
  static final MarkerGeneratorService _instance =
      MarkerGeneratorService._internal();
  factory MarkerGeneratorService() => _instance;
  MarkerGeneratorService._internal();

  // Cache for generated markers
  final Map<String, BitmapDescriptor> _cache = {};

  // Device capability flag (set to false on low-end devices)
  bool _usePremiumMarkers = true;

  /// Set whether to use premium markers (default: true)
  /// Set to false on low-end devices to improve performance
  void setUsePremiumMarkers(bool value) {
    _usePremiumMarkers = value;
    if (!value) {
      // Clear cache if switching to simple markers
      _cache.clear();
    }
  }

  /// Generate or retrieve cached marker for a map mode
  Future<BitmapDescriptor> getMarkerForMode(
    MapMode mode, {
    IconData? icon,
    String? label,
    bool forceRegenerate = false,
  }) async {
    final cacheKey = _getCacheKey(mode, icon, label);

    // Return cached marker if available and not forcing regeneration
    if (!forceRegenerate && _cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      BitmapDescriptor marker;

      if (_usePremiumMarkers) {
        // Generate premium 3D marker
        marker = await _generatePremiumMarker(
          primaryColor: mode.primaryColor,
          icon: icon ?? mode.icon,
          label: label,
        );
      } else {
        // Generate simple marker
        marker = await _generateSimpleMarker(
          color: mode.primaryColor,
          icon: icon ?? mode.icon,
        );
      }

      // Cache the marker
      _cache[cacheKey] = marker;
      return marker;
    } catch (e) {
      debugPrint('Error generating marker for ${mode.label}: $e');
      // Fallback to default marker with mode-specific hue
      return BitmapDescriptor.defaultMarkerWithHue(mode.fallbackMarkerHue);
    }
  }

  /// Generate premium 3D marker using StadiumMarkerPainter
  Future<BitmapDescriptor> _generatePremiumMarker({
    required Color primaryColor,
    required IconData icon,
    String? label,
  }) async {
    const size = Size(120, 120);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use StadiumMarkerPainter to draw the marker
    final painter = StadiumMarkerPainter(
      primaryColor: primaryColor,
      icon: icon,
      label: label,
      showShadow: true,
      elevation: 8.0,
    );

    painter.paint(canvas, size);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  /// Generate simple circular marker for low-end devices
  Future<BitmapDescriptor> _generateSimpleMarker({
    required Color color,
    required IconData icon,
  }) async {
    const size = Size(80, 80);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use SimpleMarkerPainter to draw the marker
    final painter = SimpleMarkerPainter(
      color: color,
      icon: icon,
    );

    painter.paint(canvas, size);

    // Convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.bytes(bytes);
  }

  /// Generate cache key for marker
  String _getCacheKey(MapMode mode, IconData? icon, String? label) {
    return '${mode.name}_${icon?.codePoint}_${label ?? ""}';
  }

  /// Preload markers for a specific mode
  /// Call this on app startup to avoid first-load delays
  Future<void> preloadMarkersForMode(MapMode mode) async {
    try {
      await getMarkerForMode(mode);
      debugPrint('✅ Preloaded markers for ${mode.label}');
    } catch (e) {
      debugPrint('⚠️ Failed to preload markers for ${mode.label}: $e');
    }
  }

  /// Preload all markers for all modes
  Future<void> preloadAllMarkers() async {
    for (final mode in MapMode.values) {
      await preloadMarkersForMode(mode);
    }
  }

  /// Clear marker cache
  void clearCache() {
    _cache.clear();
    debugPrint('🗑️ Marker cache cleared');
  }

  /// Get cache size (number of cached markers)
  int getCacheSize() => _cache.length;

  /// Load marker from asset image (fallback method)
  Future<BitmapDescriptor> loadMarkerFromAsset(
    String assetPath, {
    Size? targetSize,
  }) async {
    try {
      final imageConfiguration = ImageConfiguration(
        size: targetSize ?? const Size(100, 100),
      );
      return await BitmapDescriptor.asset(imageConfiguration, assetPath);
    } catch (e) {
      debugPrint('Error loading marker from asset $assetPath: $e');
      // Return default marker
      return BitmapDescriptor.defaultMarker;
    }
  }

  /// Detect if device can handle premium markers
  /// This is a simple heuristic - you can make it more sophisticated
  Future<bool> detectDeviceCapability() async {
    try {
      // Try generating a test marker and measure time
      final stopwatch = Stopwatch()..start();

      await _generatePremiumMarker(
        primaryColor: Colors.blue,
        icon: Icons.stadium,
      );

      stopwatch.stop();

      // If generation takes more than 500ms, consider device low-end
      final isPremiumCapable = stopwatch.elapsedMilliseconds < 500;

      if (!isPremiumCapable) {
        debugPrint(
            '⚠️ Device may struggle with premium markers (${stopwatch.elapsedMilliseconds}ms)');
        debugPrint('   Switching to simple markers for better performance');
        setUsePremiumMarkers(false);
      } else {
        debugPrint('✅ Device capable of premium markers (${stopwatch.elapsedMilliseconds}ms)');
      }

      return isPremiumCapable;
    } catch (e) {
      debugPrint('Error detecting device capability: $e');
      // If detection fails, assume device can't handle premium markers
      setUsePremiumMarkers(false);
      return false;
    }
  }
}
