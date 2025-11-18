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
  static const String googleMapsApiKey = 'AIzaSyDhe0LjsJYUlntwSE7ich3Id4lCOJNilcE';

  /// Custom API base URL (for your custom API integration)
  static String? customApiBaseUrl;

  /// Custom API key (for your custom API integration)
  static String? customApiKey;

  /// Auto-login email for debug mode (emulator/device only)
  /// Set to null to disable auto-login
  static const String? autoLoginEmail = 'gal@joya-tech.net'; // Set to 'gal@joya-tech.net' for auto-login
  
  /// Auto-login password for debug mode (emulator/device only)
  /// WARNING: Only use in debug mode! Never commit passwords to git!
  static const String? autoLoginPassword = '123456'; // Set password here for auto-login

  /// Check if Firebase is available
  static bool get isFirebaseAvailable => !limitedMode;

  /// Check if running with emulators
  static bool get isUsingEmulators => useEmulators && !limitedMode;
  
  /// Check if auto-login is enabled
  static bool get isAutoLoginEnabled => autoLoginEmail != null && autoLoginPassword != null;
}

