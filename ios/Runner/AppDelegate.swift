import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var cloudKitPluginInstance: CloudKitPlugin?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register our custom plugins and store CloudKit instance for notifications
    let controller = window?.rootViewController as! FlutterViewController
    let cloudKitRegistrar = registrar(forPlugin: "CloudKitPlugin")!
    CloudKitPlugin.register(with: cloudKitRegistrar)
    
    KeychainPlugin.register(with: registrar(forPlugin: "KeychainPlugin")!)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Handle CloudKit push notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // CloudKit push notifications are handled automatically by the plugin's subscription system
    // No need to manually forward them since they're handled via the event channel
    completionHandler(.newData)
  }
}
