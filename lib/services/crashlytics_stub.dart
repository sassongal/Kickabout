// Stub file for Firebase Crashlytics on Web platform
// This file is used when compiling for Web to avoid import errors

/// Stub class for Firebase Crashlytics (not available on Web)
class FirebaseCrashlytics {
  static FirebaseCrashlytics get instance => FirebaseCrashlytics();

  void recordError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    // No-op on Web
  }

  void recordFlutterFatalError(dynamic errorDetails) {
    // No-op on Web
  }

  void log(String message) {
    // No-op on Web
  }

  void setUserIdentifier(String userId) {
    // No-op on Web
  }

  void setCustomKey(String key, dynamic value) {
    // No-op on Web
  }
}

