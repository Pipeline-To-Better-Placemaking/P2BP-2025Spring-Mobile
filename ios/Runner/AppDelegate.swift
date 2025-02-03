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
    GeneratedPluginRegistrant.register(with: self)
    // Use Firebase library to configure APIs
    FirebaseApp.configure()
    GMSServices.provideAPIKey(ProcessInfo.processInfo.environment["MAPS_API_KEY"] )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
