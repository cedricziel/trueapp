import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'mock_cloudkit_service.dart';
import 'mock_keychain_service.dart';

/// Test helpers for TrueNAS native plugins
class TruenasPluginTestHelpers {
  /// Set up method channel mocks for testing
  ///
  /// This method configures the Flutter test environment to handle
  /// platform channel calls with mock responses.
  static void setupMethodChannelMocks({
    String channelPrefix = 'com.cedricziel.truehub',
    Map<String, dynamic>? cloudKitResponses,
    Map<String, dynamic>? keychainResponses,
  }) {
    TestWidgetsFlutterBinding.ensureInitialized();

    // CloudKit method channel
    final cloudKitChannel = MethodChannel('$channelPrefix/cloudkit');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(cloudKitChannel,
            (MethodCall methodCall) async {
      final responses = cloudKitResponses ?? _defaultCloudKitResponses;
      return responses[methodCall.method] ?? false;
    });

    // Keychain method channel
    final keychainChannel = MethodChannel('$channelPrefix/keychain');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(keychainChannel,
            (MethodCall methodCall) async {
      final responses = keychainResponses ?? _defaultKeychainResponses;

      if (methodCall.method == 'getPassword') {
        final args = (methodCall.arguments as Map).cast<String, dynamic>();
        final serverId = args['account'] as String;
        return responses['passwords']?[serverId];
      }

      return responses[methodCall.method] ?? false;
    });
  }

  static final Map<String, dynamic> _defaultCloudKitResponses = {
    'initialize': true,
    'isAvailable': true,
    'saveServerConfig': true,
    'updateServerConfig': true,
    'fetchServerConfigs': <Map<String, dynamic>>[],
    'deleteServerConfig': true,
    'startMonitoring': null,
    'stopMonitoring': null,
  };

  static final Map<String, dynamic> _defaultKeychainResponses = {
    'storePassword': true,
    'deletePassword': true,
    'hasPassword': false,
    'getAllServerIds': <String>[],
    'deleteAllPasswords': true,
    'passwords': <String, String>{},
  };

  /// Create a pre-configured mock CloudKit service
  static MockCloudKitService createMockCloudKitService({
    bool isInitialized = false,
    bool isAvailable = true,
    bool shouldFailOperations = false,
    int operationDelay = 0,
  }) {
    final mock = MockCloudKitService();

    if (isInitialized) {
      mock.initialize();
    }

    mock.setIsAvailable(isAvailable);
    mock.setShouldFailOperations(shouldFailOperations);
    mock.setOperationDelay(operationDelay);

    return mock;
  }

  /// Create a pre-configured mock Keychain service
  static MockKeychainService createMockKeychainService({
    bool shouldFailOperations = false,
    int operationDelay = 0,
    Map<String, String>? initialPasswords,
  }) {
    final mock = MockKeychainService();

    mock.setShouldFailOperations(shouldFailOperations);
    mock.setOperationDelay(operationDelay);

    if (initialPasswords != null) {
      initialPasswords.forEach((serverId, password) {
        mock.addPassword(serverId, password);
      });
    }

    return mock;
  }

  /// Clean up method channel mocks
  static void tearDownMethodChannelMocks({
    String channelPrefix = 'com.cedricziel.truehub',
  }) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel('$channelPrefix/cloudkit'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      MethodChannel('$channelPrefix/keychain'),
      null,
    );
  }
}

/// Extension methods for test assertions
extension ServerConfigDTOTestExtensions on List<dynamic> {
  /// Convert a list of JSON maps to ServerConfigDTO objects
  List<Map<String, dynamic>> toServerConfigJsonList() {
    return whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
