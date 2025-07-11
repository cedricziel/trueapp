import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)
    
    // Set up method channel for window management
    if let controller = mainFlutterWindow?.contentViewController as? FlutterViewController {
      methodChannel = FlutterMethodChannel(
        name: "com.truenas.manager/window",
        binaryMessenger: controller.engine.binaryMessenger
      )
      
      methodChannel?.setMethodCallHandler { [weak self] (call, result) in
        switch call.method {
        case "showWindow":
          self?.showWindow()
          result(nil)
        case "hideWindow":
          self?.hideWindow()
          result(nil)
        case "quitApp":
          NSApplication.shared.terminate(nil)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }
  
  private func showWindow() {
    DispatchQueue.main.async {
      if let window = self.mainFlutterWindow {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
      }
    }
  }
  
  private func hideWindow() {
    DispatchQueue.main.async {
      if let window = self.mainFlutterWindow {
        window.orderOut(nil)
      }
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Don't terminate when window is closed - let the tray handle it
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
