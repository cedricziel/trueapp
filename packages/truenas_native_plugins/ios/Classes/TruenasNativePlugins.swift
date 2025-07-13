import Flutter
import UIKit

public class TruenasNativePlugins: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register CloudKit plugin
        CloudKitPlugin.register(with: registrar)
        
        // Register Keychain plugin
        KeychainPlugin.register(with: registrar)
    }
}