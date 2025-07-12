import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {

  override func applicationDidFinishLaunching(_ notification: Notification) {
    let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    
    // Register our custom plugins for macOS
    CloudKitPlugin.register(with: controller.registrar(forPlugin: "CloudKitPlugin"))
    KeychainPlugin.register(with: controller.registrar(forPlugin: "KeychainPlugin"))
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't terminate when window is closed - let the tray handle it
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
