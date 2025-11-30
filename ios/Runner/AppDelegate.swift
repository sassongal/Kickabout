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
    // Application restrictions: Add iOS bundle ID
    // API restrictions: Only Maps SDK for iOS, Places API
    // TODO: Move to Info.plist or use environment variable for better security
    GMSServices.provideAPIKey("AIzaSyAapcK84BybKhuATK6n9YEtBlENgJ068tM")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
