import Flutter
import UIKit
import GoogleSignIn

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle URL opens from Google Sign-In and other OAuth providers.
  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    // Let Google Sign-In SDK attempt to handle the URL first.
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    // Fallback to the Flutter delegate handler.
    return super.application(app, open: url, options: options)
  }
}
