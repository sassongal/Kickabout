// Service for injecting Google Maps API key on web platform
// This file uses conditional imports to only work on web

import 'package:flutter/foundation.dart';
import 'package:kattrick/config/env.dart';

/// Inject Google Maps API key to window object for web platform
/// This allows index.html JavaScript to access it
/// 
/// Note: The actual injection is done via JavaScript in index.html
/// This function only validates that the key is set
void injectGoogleMapsApiKeyForWeb() {
  // Only run on web platform
  if (!kIsWeb) return;

  try {
    final apiKey = Env.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      debugPrint('✅ Google Maps API key is set for web');
      // The key will be injected by JavaScript in index.html
      // which reads from window.GOOGLE_MAPS_API_KEY or meta tag
    } else {
      debugPrint('⚠️ Google Maps API key not set - maps will not work on web');
      debugPrint('⚠️ Set it via: flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY');
    }
  } catch (e) {
    debugPrint('⚠️ Failed to validate Google Maps API key for web: $e');
  }
}

