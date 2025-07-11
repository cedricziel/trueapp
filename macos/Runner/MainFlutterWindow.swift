import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var methodChannel: FlutterMethodChannel?
  
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    
    // Set up method channel for window management
    setupMethodChannel(flutterViewController: flutterViewController)

    super.awakeFromNib()
  }
  
  private func setupMethodChannel(flutterViewController: FlutterViewController) {
    methodChannel = FlutterMethodChannel(
      name: "com.truenas.manager/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
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
      case "setDockVisibility":
        if let args = call.arguments as? [String: Any],
           let visible = args["visible"] as? Bool {
          self?.setDockVisibility(visible)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    print("Method channel set up successfully in MainFlutterWindow")
  }
  
  private func showWindow() {
    DispatchQueue.main.async {
      self.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
  
  private func hideWindow() {
    DispatchQueue.main.async {
      self.orderOut(nil)
    }
  }
  
  private func setDockVisibility(_ visible: Bool) {
    DispatchQueue.main.async {
      if visible {
        // Show app in dock
        NSApp.setActivationPolicy(.regular)
      } else {
        // Hide app from dock
        NSApp.setActivationPolicy(.accessory)
      }
      print("Set dock visibility to: \(visible)")
    }
  }
}
