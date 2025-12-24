import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Google Maps API Key (Client-side SDK key for displaying maps)
    // SECURITY: This key should be restricted in Google Cloud Console
    // Application restrictions: Add iOS bundle ID (com.joyatech.kattrick)
    // API restrictions: Only Maps SDK for iOS, Places API
    // 
    // The API key is read from Info.plist, which can be populated at build time
    // via dart-define or Xcode build settings
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
       !apiKey.isEmpty {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // Fallback: Try to read from environment variable (for development)
      // This allows using: flutter run --dart-define=GOOGLE_MAPS_API_KEY=YOUR_KEY
      if let envKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"],
         !envKey.isEmpty {
        GMSServices.provideAPIKey(envKey)
      } else {
        // In production, this should never happen - fail fast to catch configuration issues
        #if DEBUG
        print("⚠️ WARNING: GOOGLE_MAPS_API_KEY not found in Info.plist or environment")
        print("⚠️ Google Maps will not work. Set GOOGLE_MAPS_API_KEY in Info.plist or use --dart-define")
        #else
        fatalError("Google Maps API Key not configured. Set GOOGLE_MAPS_API_KEY in Info.plist")
        #endif
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
