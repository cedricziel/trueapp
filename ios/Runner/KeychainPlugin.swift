// KeychainPlugin.swift
// Native Keychain implementation for iOS/macOS using Security framework
// Implements Apple's recommended keychain pattern with synchronization

#if canImport(Flutter)
import Flutter
#else
import FlutterMacOS
#endif
import Security

public class KeychainPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if canImport(Flutter)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        
        let channel = FlutterMethodChannel(name: "com.cedricziel.truehub/keychain", binaryMessenger: messenger)
        let instance = KeychainPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "storePassword":
            if let args = call.arguments as? [String: Any] {
                storePassword(args: args, result: result)
            } else {
                result(false)
            }
        case "getPassword":
            if let args = call.arguments as? [String: Any] {
                getPassword(args: args, result: result)
            } else {
                result(nil)
            }
        case "deletePassword":
            if let args = call.arguments as? [String: Any] {
                deletePassword(args: args, result: result)
            } else {
                result(false)
            }
        case "hasPassword":
            if let args = call.arguments as? [String: Any] {
                hasPassword(args: args, result: result)
            } else {
                result(false)
            }
        case "getAllServerIds":
            if let args = call.arguments as? [String: Any] {
                getAllServerIds(args: args, result: result)
            } else {
                result([])
            }
        case "deleteAllPasswords":
            if let args = call.arguments as? [String: Any] {
                deleteAllPasswords(args: args, result: result)
            } else {
                result(false)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func storePassword(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String,
              let account = args["account"] as? String,
              let password = args["password"] as? String,
              let synchronizable = args["synchronizable"] as? Bool,
              let accessible = args["accessible"] as? String else {
            print("KeychainPlugin: Invalid arguments for storePassword")
            result(false)
            return
        }
        
        guard let passwordData = password.data(using: .utf8) else {
            print("KeychainPlugin: Could not convert password to data")
            result(false)
            return
        }
        
        // Convert accessible string to Security constant
        let accessibleAttribute: CFString
        switch accessible {
        case "WhenUnlocked":
            accessibleAttribute = kSecAttrAccessibleWhenUnlocked
        case "WhenUnlockedThisDeviceOnly":
            accessibleAttribute = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        default:
            accessibleAttribute = kSecAttrAccessibleWhenUnlocked
        }
        
        // Create a delete query that can find items regardless of synchronizable status
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: kSecAttrSynchronizableAny
        ]
        
        // First try to delete existing item (easier than checking if it exists)
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Build keychain query for storing the new item
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: accessibleAttribute,
            kSecValueData as String: passwordData
        ]
        
        // Add synchronization if requested (for iCloud Keychain)
        if synchronizable {
            query[kSecAttrSynchronizable as String] = kCFBooleanTrue
        }
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            print("KeychainPlugin: Successfully stored password for account: \(account)")
            result(true)
        case errSecDuplicateItem:
            // If it already exists, update it
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account
            ]
            
            let updateAttributes: [String: Any] = [
                kSecValueData as String: passwordData,
                kSecAttrAccessible as String: accessibleAttribute,
                kSecAttrSynchronizable as String: synchronizable ? kCFBooleanTrue : kCFBooleanFalse
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus == errSecSuccess {
                print("KeychainPlugin: Successfully updated password for account: \(account)")
                result(true)
            } else {
                print("KeychainPlugin: Failed to update password. Status: \(updateStatus)")
                result(false)
            }
        default:
            print("KeychainPlugin: Failed to store password. Status: \(status)")
            result(false)
        }
    }
    
    private func getPassword(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String,
              let account = args["account"] as? String else {
            result(nil)
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: kCFBooleanTrue
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            if let data = dataTypeRef as? Data,
               let password = String(data: data, encoding: .utf8) {
                print("KeychainPlugin: Successfully retrieved password for account: \(account)")
                result(password)
            } else {
                print("KeychainPlugin: Could not convert password data to string")
                result(nil)
            }
        case errSecItemNotFound:
            print("KeychainPlugin: Password not found for account: \(account) (may still be syncing)")
            result(nil)
        default:
            print("KeychainPlugin: Failed to retrieve password. Status: \(status)")
            result(nil)
        }
    }
    
    private func deletePassword(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String,
              let account = args["account"] as? String else {
            result(false)
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("KeychainPlugin: Successfully deleted password for account: \(account)")
            result(true)
        case errSecItemNotFound:
            print("KeychainPlugin: Password not found for deletion (already deleted?): \(account)")
            result(true) // Consider this success
        default:
            print("KeychainPlugin: Failed to delete password. Status: \(status)")
            result(false)
        }
    }
    
    private func hasPassword(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String,
              let account = args["account"] as? String else {
            result(false)
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            result(true)
        case errSecItemNotFound:
            result(false)
        default:
            print("KeychainPlugin: Error checking password existence. Status: \(status)")
            result(false)
        }
    }
    
    private func getAllServerIds(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String else {
            result([])
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: kCFBooleanTrue
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        switch status {
        case errSecSuccess:
            if let items = dataTypeRef as? [[String: Any]] {
                let serverIds = items.compactMap { item in
                    return item[kSecAttrAccount as String] as? String
                }
                print("KeychainPlugin: Found \(serverIds.count) server IDs")
                result(serverIds)
            } else {
                result([])
            }
        case errSecItemNotFound:
            print("KeychainPlugin: No items found for service: \(service)")
            result([])
        default:
            print("KeychainPlugin: Error getting all server IDs. Status: \(status)")
            result([])
        }
    }
    
    private func deleteAllPasswords(args: [String: Any], result: @escaping FlutterResult) {
        guard let service = args["service"] as? String else {
            result(false)
            return
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        switch status {
        case errSecSuccess:
            print("KeychainPlugin: Successfully deleted all passwords for service: \(service)")
            result(true)
        case errSecItemNotFound:
            print("KeychainPlugin: No passwords found to delete for service: \(service)")
            result(true) // Consider this success
        default:
            print("KeychainPlugin: Failed to delete all passwords. Status: \(status)")
            result(false)
        }
    }
}