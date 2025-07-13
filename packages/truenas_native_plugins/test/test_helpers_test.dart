import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart';

void main() {
  group('TruenasPluginTestHelpers', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    tearDown(() {
      TruenasPluginTestHelpers.tearDownMethodChannelMocks();
    });

    group('Method Channel Mocking', () {
      test('should setup CloudKit method channel mocks', () async {
        TruenasPluginTestHelpers.setupMethodChannelMocks();

        const cloudKitChannel =
            MethodChannel('com.cedricziel.truehub/cloudkit');

        // Test initialize method
        final initResult =
            await cloudKitChannel.invokeMethod<bool>('initialize');
        expect(initResult, isTrue);

        // Test isAvailable method
        final availableResult =
            await cloudKitChannel.invokeMethod<bool>('isAvailable');
        expect(availableResult, isTrue);

        // Test fetchServerConfigs method
        final configsResult = await cloudKitChannel
            .invokeMethod<List<dynamic>>('fetchServerConfigs');
        expect(configsResult, isA<List<dynamic>>());
        expect(configsResult, isEmpty);
      });

      test('should setup Keychain method channel mocks', () async {
        TruenasPluginTestHelpers.setupMethodChannelMocks();

        const keychainChannel =
            MethodChannel('com.cedricziel.truehub/keychain');

        // Test storePassword method
        final storeResult = await keychainChannel.invokeMethod<bool>(
          'storePassword',
          {
            'service': 'com.cedricziel.truehub.server',
            'account': 'test-server-id',
            'password': 'test-password',
            'synchronizable': true,
            'accessible': 'WhenUnlocked',
          },
        );
        expect(storeResult, isTrue);

        // Test hasPassword method
        final hasResult = await keychainChannel.invokeMethod<bool>(
          'hasPassword',
          {
            'service': 'com.cedricziel.truehub.server',
            'account': 'test-server-id',
          },
        );
        expect(hasResult, isFalse);
      });

      test('should support custom responses', () async {
        final customCloudKitResponses = {
          'initialize': false,
          'isAvailable': false,
          'fetchServerConfigs': [
            {
              'id': 'test-server',
              'displayName': 'Test Server',
              'hostName': 'test.local',
              'userName': 'admin',
              'useHttps': true,
              'allowUntrustedCertificates': false,
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }
          ],
        };

        final customKeychainResponses = {
          'storePassword': false,
          'hasPassword': true,
          'passwords': {'test-server': 'test-password'},
        };

        TruenasPluginTestHelpers.setupMethodChannelMocks(
          cloudKitResponses: customCloudKitResponses,
          keychainResponses: customKeychainResponses,
        );

        const cloudKitChannel =
            MethodChannel('com.cedricziel.truehub/cloudkit');
        const keychainChannel =
            MethodChannel('com.cedricziel.truehub/keychain');

        // Test custom CloudKit responses
        expect(await cloudKitChannel.invokeMethod<bool>('initialize'), isFalse);
        expect(
            await cloudKitChannel.invokeMethod<bool>('isAvailable'), isFalse);

        final configs = await cloudKitChannel
            .invokeMethod<List<dynamic>>('fetchServerConfigs');
        expect(configs, hasLength(1));
        expect(configs!.first['displayName'], equals('Test Server'));

        // Test custom Keychain responses
        expect(await keychainChannel.invokeMethod<bool>('storePassword', {}),
            isFalse);
        expect(await keychainChannel.invokeMethod<bool>('hasPassword', {}),
            isTrue);

        final password = await keychainChannel.invokeMethod<String>(
          'getPassword',
          {'account': 'test-server'},
        );
        expect(password, equals('test-password'));
      });
    });

    group('Mock Service Creation', () {
      test('should create mock CloudKit service with defaults', () {
        final mockService =
            TruenasPluginTestHelpers.createMockCloudKitService();

        expect(mockService.isInitialized, isFalse);
        expect(mockService.mockConfigCount, equals(0));
      });

      test('should create mock CloudKit service with custom configuration', () {
        final mockService = TruenasPluginTestHelpers.createMockCloudKitService(
          isInitialized: true,
          isAvailable: false,
          shouldFailOperations: true,
          operationDelay: 100,
        );

        expect(mockService.isInitialized, isTrue);
        expect(mockService.mockConfigCount, equals(0));
      });

      test('should create mock Keychain service with defaults', () {
        final mockService =
            TruenasPluginTestHelpers.createMockKeychainService();

        expect(mockService.passwordCount, equals(0));
      });

      test('should create mock Keychain service with initial passwords', () {
        final initialPasswords = {
          'server1': 'password1',
          'server2': 'password2',
        };

        final mockService = TruenasPluginTestHelpers.createMockKeychainService(
          shouldFailOperations: false,
          operationDelay: 50,
          initialPasswords: initialPasswords,
        );

        expect(mockService.passwordCount, equals(2));
        expect(mockService.hasStoredPassword('server1'), isTrue);
        expect(mockService.hasStoredPassword('server2'), isTrue);
        expect(mockService.getStoredPassword('server1'), equals('password1'));
        expect(mockService.getStoredPassword('server2'), equals('password2'));
      });
    });

    group('Teardown', () {
      test('should clear method channel handlers', () async {
        TruenasPluginTestHelpers.setupMethodChannelMocks();
        TruenasPluginTestHelpers.tearDownMethodChannelMocks();

        const cloudKitChannel =
            MethodChannel('com.cedricziel.truehub/cloudkit');

        // Should throw an exception when no handler is set
        expect(
          () => cloudKitChannel.invokeMethod('initialize'),
          throwsA(isA<MissingPluginException>()),
        );
      });
    });
  });
}
