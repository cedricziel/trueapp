// CloudKitPlugin.swift
// Native CloudKit implementation for iOS/macOS
// Implements Apple's recommended two-layer sync pattern

#if canImport(Flutter)
import Flutter
#else
import FlutterMacOS
#endif
import CloudKit

public class CloudKitPlugin: NSObject, FlutterPlugin {
    private let container = CKContainer(identifier: "iCloud.com.cedricziel.truehub")
    private lazy var privateDatabase = container.privateCloudDatabase
    private var eventSink: FlutterEventSink?
    private var subscriptionID: String?
    
    private static let recordType = "ServerConfig"
    private static let subscriptionKey = "ServerConfigSubscription"
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        #if canImport(Flutter)
        let messenger = registrar.messenger()
        #else
        let messenger = registrar.messenger
        #endif
        
        let channel = FlutterMethodChannel(name: "com.cedricziel.truehub/cloudkit", binaryMessenger: messenger)
        let eventChannel = FlutterEventChannel(name: "com.cedricziel.truehub/cloudkit_events", binaryMessenger: messenger)
        
        let instance = CloudKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initialize(result: result)
        case "isAvailable":
            checkAvailability(result: result)
        case "saveServerConfig":
            if let args = call.arguments as? [String: Any] {
                saveServerConfig(args: args, result: result)
            } else {
                result(false)
            }
        case "fetchServerConfigs":
            fetchServerConfigs(result: result)
        case "updateServerConfig":
            if let args = call.arguments as? [String: Any] {
                updateServerConfig(args: args, result: result)
            } else {
                result(false)
            }
        case "deleteServerConfig":
            if let args = call.arguments as? [String: Any] {
                deleteServerConfig(args: args, result: result)
            } else {
                result(false)
            }
        case "startMonitoring":
            startMonitoring(result: result)
        case "stopMonitoring":
            stopMonitoring(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(result: @escaping FlutterResult) {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                switch status {
                case .available:
                    print("CloudKitPlugin: iCloud account available")
                    result(true)
                case .noAccount:
                    print("CloudKitPlugin: No iCloud account")
                    result(false)
                case .restricted:
                    print("CloudKitPlugin: iCloud account restricted")
                    result(false)
                case .couldNotDetermine:
                    print("CloudKitPlugin: Could not determine iCloud status")
                    result(false)
                case .temporarilyUnavailable:
                    print("CloudKitPlugin: iCloud temporarily unavailable")
                    result(false)
                @unknown default:
                    print("CloudKitPlugin: Unknown iCloud status")
                    result(false)
                }
            }
        }
    }
    
    private func checkAvailability(result: @escaping FlutterResult) {
        container.accountStatus { status, error in
            DispatchQueue.main.async {
                result(status == .available)
            }
        }
    }
    
    private func saveServerConfig(args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["id"] as? String else {
            result(false)
            return
        }
        
        let recordID = CKRecord.ID(recordName: id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        
        // Map all fields from ServerConfigDTO
        record["displayName"] = args["displayName"] as? String
        record["hostName"] = args["hostName"] as? String
        record["userName"] = args["userName"] as? String
        record["useHttps"] = (args["useHttps"] as? Bool) ?? true
        record["allowUntrustedCertificates"] = (args["allowUntrustedCertificates"] as? Bool) ?? false
        record["port"] = args["port"] as? Int
        record["localUrl"] = args["localUrl"] as? String
        record["isActive"] = (args["isActive"] as? Bool) ?? true
        record["isDefault"] = (args["isDefault"] as? Bool) ?? false
        
        // Handle arrays and dates
        if let wifiSsids = args["trustedWifiSsids"] as? [String] {
            record["trustedWifiSsids"] = wifiSsids
        }
        
        if let lastConnectedStr = args["lastConnected"] as? String {
            let formatter = ISO8601DateFormatter()
            record["lastConnected"] = formatter.date(from: lastConnectedStr)
        }
        
        if let createdAtStr = args["createdAt"] as? String {
            let formatter = ISO8601DateFormatter()
            record["createdAt"] = formatter.date(from: createdAtStr)
        }
        
        if let updatedAtStr = args["updatedAt"] as? String {
            let formatter = ISO8601DateFormatter()
            record["updatedAt"] = formatter.date(from: updatedAtStr)
        }
        
        privateDatabase.save(record) { [weak self] savedRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error saving server config: \(error)")
                    result(false)
                } else {
                    print("CloudKitPlugin: Successfully saved server config: \(id)")
                    result(true)
                }
            }
        }
    }
    
    private func updateServerConfig(args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["id"] as? String else {
            result(false)
            return
        }
        
        let recordID = CKRecord.ID(recordName: id)
        
        // First fetch the existing record
        privateDatabase.fetch(withRecordID: recordID) { [weak self] existingRecord, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error fetching existing record for update: \(error)")
                    result(false)
                    return
                }
                
                guard let record = existingRecord else {
                    print("CloudKitPlugin: No existing record found for update: \(id)")
                    result(false)
                    return
                }
                
                // Update the existing record with new values
                record["displayName"] = args["displayName"] as? String
                record["hostName"] = args["hostName"] as? String
                record["userName"] = args["userName"] as? String
                record["useHttps"] = (args["useHttps"] as? Bool) ?? true
                record["allowUntrustedCertificates"] = (args["allowUntrustedCertificates"] as? Bool) ?? false
                record["port"] = args["port"] as? Int
                record["localUrl"] = args["localUrl"] as? String
                record["isActive"] = (args["isActive"] as? Bool) ?? true
                record["isDefault"] = (args["isDefault"] as? Bool) ?? false
                
                // Handle arrays and dates
                if let wifiSsids = args["trustedWifiSsids"] as? [String] {
                    record["trustedWifiSsids"] = wifiSsids
                }
                
                if let lastConnectedStr = args["lastConnected"] as? String {
                    let formatter = ISO8601DateFormatter()
                    record["lastConnected"] = formatter.date(from: lastConnectedStr)
                }
                
                // Always update the updatedAt timestamp
                if let updatedAtStr = args["updatedAt"] as? String {
                    let formatter = ISO8601DateFormatter()
                    record["updatedAt"] = formatter.date(from: updatedAtStr)
                }
                
                // Save the updated record
                self?.privateDatabase.save(record) { savedRecord, saveError in
                    DispatchQueue.main.async {
                        if let saveError = saveError {
                            print("CloudKitPlugin: Error updating server config: \(saveError)")
                            result(false)
                        } else {
                            print("CloudKitPlugin: Successfully updated server config: \(id)")
                            result(true)
                        }
                    }
                }
            }
        }
    }
    
    private func fetchServerConfigs(result: @escaping FlutterResult) {
        let query = CKQuery(recordType: Self.recordType, predicate: NSPredicate(value: true))
        // Remove sorting to avoid needing sortable index
        // query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] records, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error fetching server configs: \(error)")
                    result([])
                    return
                }
                
                guard let records = records else {
                    result([])
                    return
                }
                
                let configs = records.compactMap { record -> [String: Any]? in
                    return self?.recordToDict(record)
                }
                
                print("CloudKitPlugin: Fetched \(configs.count) server configs")
                result(configs)
            }
        }
    }
    
    private func deleteServerConfig(args: [String: Any], result: @escaping FlutterResult) {
        guard let id = args["id"] as? String else {
            result(false)
            return
        }
        
        let recordID = CKRecord.ID(recordName: id)
        
        privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error deleting server config: \(error)")
                    result(false)
                } else {
                    print("CloudKitPlugin: Successfully deleted server config: \(id)")
                    result(true)
                }
            }
        }
    }
    
    private func startMonitoring(result: @escaping FlutterResult) {
        // Create subscription for push notifications
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: Self.recordType,
            predicate: predicate,
            subscriptionID: Self.subscriptionKey,
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        privateDatabase.save(subscription) { [weak self] savedSubscription, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error creating subscription: \(error)")
                } else {
                    print("CloudKitPlugin: Successfully created subscription")
                    self?.subscriptionID = savedSubscription?.subscriptionID
                }
                result(error == nil)
            }
        }
    }
    
    private func stopMonitoring(result: @escaping FlutterResult) {
        guard let subscriptionID = subscriptionID else {
            result(true)
            return
        }
        
        privateDatabase.delete(withSubscriptionID: subscriptionID) { deletedID, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("CloudKitPlugin: Error deleting subscription: \(error)")
                } else {
                    print("CloudKitPlugin: Successfully deleted subscription")
                }
                result(error == nil)
            }
        }
    }
    
    private func recordToDict(_ record: CKRecord) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        dict["id"] = record.recordID.recordName
        dict["displayName"] = record["displayName"] as? String
        dict["hostName"] = record["hostName"] as? String
        dict["userName"] = record["userName"] as? String
        dict["useHttps"] = record["useHttps"] as? Bool ?? true
        dict["allowUntrustedCertificates"] = record["allowUntrustedCertificates"] as? Bool ?? false
        dict["port"] = record["port"] as? Int
        dict["localUrl"] = record["localUrl"] as? String
        dict["isActive"] = record["isActive"] as? Bool ?? true
        dict["isDefault"] = record["isDefault"] as? Bool ?? false
        dict["trustedWifiSsids"] = record["trustedWifiSsids"] as? [String] ?? []
        
        let formatter = ISO8601DateFormatter()
        if let lastConnected = record["lastConnected"] as? Date {
            dict["lastConnected"] = formatter.string(from: lastConnected)
        }
        if let createdAt = record["createdAt"] as? Date {
            dict["createdAt"] = formatter.string(from: createdAt)
        }
        if let updatedAt = record["updatedAt"] as? Date {
            dict["updatedAt"] = formatter.string(from: updatedAt)
        }
        
        return dict
    }
    
    // Handle CloudKit push notifications
    public func handleCloudKitNotification(_ userInfo: [AnyHashable: Any]) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
            return
        }
        
        if notification.subscriptionID == Self.subscriptionKey {
            // Refetch all configs when we get a push notification
            fetchServerConfigs { [weak self] configs in
                if let configs = configs as? [[String: Any]] {
                    self?.eventSink?([
                        "type": "serverConfigsUpdated",
                        "configs": configs
                    ])
                }
            }
        }
    }
}

extension CloudKitPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
}