import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register our custom plugins
    let controller = window?.rootViewController as! FlutterViewController
    CloudKitPlugin.register(with: registrar(forPlugin: "CloudKitPlugin")!)
    KeychainPlugin.register(with: registrar(forPlugin: "KeychainPlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle CloudKit push notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Forward CloudKit notifications to our plugin
    if let cloudKitPlugin = registrar(forPlugin: "CloudKitPlugin")?.valuePublished(byPlugin: "CloudKitPlugin") as? CloudKitPlugin {
      cloudKitPlugin.handleCloudKitNotification(userInfo)
    }
    
    completionHandler(.newData)
  }
}
