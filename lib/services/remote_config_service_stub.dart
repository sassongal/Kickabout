// Stub for Remote Config on web (not supported)
// This file is used as a fallback when firebase_remote_config is not available

class FirebaseRemoteConfig {
  static FirebaseRemoteConfig get instance => FirebaseRemoteConfig();
  
  Future<void> setConfigSettings(dynamic settings) async {}
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}
  Future<bool> fetchAndActivate() async => false;
  Future<void> fetch() async {}
  Future<void> activate() async {}
  
  int getInt(String key) => 0;
  double getDouble(String key) => 0.0;
  bool getBool(String key) => false;
  String getString(String key) => '';
}

// Alias for compatibility
typedef RemoteConfig = FirebaseRemoteConfig;

class RemoteConfigSettings {
  final Duration fetchTimeout;
  final Duration minimumFetchInterval;
  
  const RemoteConfigSettings({
    required this.fetchTimeout,
    required this.minimumFetchInterval,
  });
}

