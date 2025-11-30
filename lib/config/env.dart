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
  /// Set via environment variable: GOOGLE_MAPS_API_KEY
  /// For production, use: flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
  /// Or create .env file (NOT committed to git!)
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '', // Empty in production - must be set via environment!
  );

  /// Custom API base URL (for your custom API integration)
  static String? customApiBaseUrl;

  /// Custom API key (for your custom API integration)
  static String? customApiKey;

  /// Auto-login email for debug mode (emulator/device only)
  /// Set to null to disable auto-login
  /// WARNING: Set your email here for local development only - never commit real credentials!
  static const String? autoLoginEmail =
      null; // Set to your email for auto-login in debug mode

  /// Auto-login password for debug mode (emulator/device only)
  /// WARNING: Only use in debug mode! Never commit passwords to git!
  static const String? autoLoginPassword =
      null; // Set password here for auto-login in debug mode

  /// Check if Firebase is available
  static bool get isFirebaseAvailable => !limitedMode;

  /// Check if running with emulators
  static bool get isUsingEmulators => useEmulators && !limitedMode;

  /// Check if auto-login is enabled
  static bool get isAutoLoginEnabled =>
      autoLoginEmail != null && autoLoginPassword != null;
}
