import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'interfaces/cloudkit_service_interface.dart';
import 'models/server_config_dto.dart';

/// CloudKit service for syncing server configurations across devices
/// Follows Apple's two-layer pattern: CloudKit for metadata, Keychain for passwords
class NativeCloudKitService implements CloudKitServiceInterface {
  final String _channelPrefix;
  late final MethodChannel _methodChannel;
  late final EventChannel _eventChannel;

  static NativeCloudKitService? _instance;
  static NativeCloudKitService get instance =>
      _instance ??= NativeCloudKitService();

  NativeCloudKitService({String channelPrefix = 'com.cedricziel.truehub'})
      : _channelPrefix = channelPrefix {
    _methodChannel = MethodChannel('$_channelPrefix/cloudkit');
    _eventChannel = EventChannel('$_channelPrefix/cloudkit_events');
  }

  StreamSubscription<dynamic>? _syncEventsSubscription;
  final StreamController<List<ServerConfigDTO>> _serverConfigsController =
      StreamController<List<ServerConfigDTO>>.broadcast();

  @override
  Stream<List<ServerConfigDTO>> get serverConfigsStream =>
      _serverConfigsController.stream;

  bool _isInitialized = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  Future<bool> initialize() async {
    try {
      if (_isInitialized) return true;

      // Only initialize on iOS/macOS
      if (!Platform.isIOS && !Platform.isMacOS) {
        if (kDebugMode) {
          print('CloudKitService: CloudKit not available on this platform');
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>('initialize');
      _isInitialized = result ?? false;

      if (_isInitialized) {
        // Start listening for sync events
        _syncEventsSubscription = _eventChannel.receiveBroadcastStream().listen(
          _handleSyncEvent,
          onError: (error) {
            if (kDebugMode) {
              print('CloudKitService: Sync event error: $error');
            }
          },
        );

        if (kDebugMode) {
          print('CloudKitService: Successfully initialized');
        }
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Failed to initialize: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    try {
      if (!_isInitialized) return false;
      return await _methodChannel.invokeMethod<bool>('isAvailable') ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error checking availability: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> saveServerConfig(ServerConfigDTO config) async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print('CloudKitService: Not initialized, cannot save server config');
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>(
        'saveServerConfig',
        config.toJson(),
      );

      if (kDebugMode) {
        print(
          'CloudKitService: Save server config ${config.id}: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error saving server config: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> updateServerConfig(ServerConfigDTO config) async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print(
            'CloudKitService: Not initialized, cannot update server config',
          );
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>(
        'updateServerConfig',
        config.toJson(),
      );

      if (kDebugMode) {
        print(
          'CloudKitService: Update server config ${config.id}: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error updating server config: $e');
      }
      return false;
    }
  }

  @override
  Future<List<ServerConfigDTO>> fetchServerConfigs() async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print(
            'CloudKitService: Not initialized, cannot fetch server configs',
          );
        }
        return [];
      }

      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'fetchServerConfigs',
      );

      if (result == null) return [];

      final configs = result
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((json) => ServerConfigDTO.fromJson(json))
          .toList();

      if (kDebugMode) {
        print('CloudKitService: Fetched ${configs.length} server configs');
      }

      return configs;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error fetching server configs: $e');
      }
      return [];
    }
  }

  @override
  Future<bool> deleteServerConfig(String serverId) async {
    try {
      if (!_isInitialized) {
        if (kDebugMode) {
          print(
            'CloudKitService: Not initialized, cannot delete server config',
          );
        }
        return false;
      }

      final result = await _methodChannel.invokeMethod<bool>(
        'deleteServerConfig',
        {'id': serverId},
      );

      if (kDebugMode) {
        print(
          'CloudKitService: Delete server config $serverId: ${result == true ? 'success' : 'failed'}',
        );
      }

      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error deleting server config: $e');
      }
      return false;
    }
  }

  /// Handle sync events from CloudKit
  void _handleSyncEvent(dynamic event) {
    try {
      if (event is Map<String, dynamic>) {
        final eventType = event['type'] as String?;

        switch (eventType) {
          case 'serverConfigsUpdated':
            final configsData = event['configs'] as List<dynamic>?;
            if (configsData != null) {
              final configs = configsData
                  .cast<Map<String, dynamic>>()
                  .map((json) => ServerConfigDTO.fromJson(json))
                  .toList();

              _serverConfigsController.add(configs);

              if (kDebugMode) {
                print(
                  'CloudKitService: Received ${configs.length} updated server configs',
                );
              }
            }
            break;
          case 'syncError':
            final error = event['error'] as String?;
            if (kDebugMode) {
              print('CloudKitService: Sync error: $error');
            }
            break;
          default:
            if (kDebugMode) {
              print('CloudKitService: Unknown sync event type: $eventType');
            }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error handling sync event: $e');
      }
    }
  }

  @override
  Future<void> startMonitoring() async {
    try {
      if (!_isInitialized) return;

      await _methodChannel.invokeMethod('startMonitoring');

      if (kDebugMode) {
        print('CloudKitService: Started monitoring CloudKit changes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error starting monitoring: $e');
      }
    }
  }

  @override
  Future<void> stopMonitoring() async {
    try {
      if (!_isInitialized) return;

      await _methodChannel.invokeMethod('stopMonitoring');

      if (kDebugMode) {
        print('CloudKitService: Stopped monitoring CloudKit changes');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CloudKitService: Error stopping monitoring: $e');
      }
    }
  }

  @override
  void dispose() {
    _syncEventsSubscription?.cancel();
    _serverConfigsController.close();
    stopMonitoring();
  }
}
