/// Environment configuration flags
/// 
/// Controls app behavior based on Firebase availability and development mode
class Env {
  /// Set to true if Firebase initialization failed
  /// App will run in limited mode without Firebase features
  static bool limitedMode = false;

  /// Set to true to use local Firebase emulators
  /// Requires emulators to be running locally
  static bool useEmulators = false;

  /// Google Maps API Key
  /// Set this in your environment or config file
  static String? googleMapsApiKey;

  /// Custom API base URL (for your custom API integration)
  static String? customApiBaseUrl;

  /// Custom API key (for your custom API integration)
  static String? customApiKey;

  /// Check if Firebase is available
  static bool get isFirebaseAvailable => !limitedMode;

  /// Check if running with emulators
  static bool get isUsingEmulators => useEmulators && !limitedMode;
}

