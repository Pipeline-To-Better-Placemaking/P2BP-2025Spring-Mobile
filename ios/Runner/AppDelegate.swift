import Flutter
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "MAPS_API_KEY") as? String {
      GMSServices.provideAPIKey(apiKey)
    } else {
      fatalError("Missing or invalid Google Maps API key in Info.plist")
    }

    GeneratedPluginRegistrant.register(with: self)
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["MAPS_API_KEY"] )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}