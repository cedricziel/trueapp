#if canImport(Flutter)
import Flutter
#else
import FlutterMacOS
#endif

public class TruenasNativePlugins: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        // Register CloudKit plugin
        CloudKitPlugin.register(with: registrar)
        
        // Register Keychain plugin
        KeychainPlugin.register(with: registrar)
    }
}