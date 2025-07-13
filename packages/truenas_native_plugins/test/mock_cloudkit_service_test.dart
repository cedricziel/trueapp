import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart';

void main() {
  group('MockCloudKitService', () {
    late MockCloudKitService mockCloudKit;

    setUp(() {
      mockCloudKit = MockCloudKitService();
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        expect(mockCloudKit.isInitialized, isFalse);

        final result = await mockCloudKit.initialize();
        expect(result, isTrue);
        expect(mockCloudKit.isInitialized, isTrue);
      });

      test('should fail initialization when configured', () async {
        mockCloudKit.setShouldFailOperations(true);

        final result = await mockCloudKit.initialize();
        expect(result, isFalse);
        expect(mockCloudKit.isInitialized, isFalse);
      });

      test('should check availability', () async {
        await mockCloudKit.initialize();

        expect(await mockCloudKit.isAvailable(), isTrue);

        mockCloudKit.setIsAvailable(false);
        expect(await mockCloudKit.isAvailable(), isFalse);
      });
    });

    group('Server Configuration Management', () {
      late ServerConfigDTO testConfig;

      setUp(() {
        testConfig = ServerConfigDTO(
          id: 'test-server-id',
          displayName: 'Test Server',
          hostName: '192.168.1.100',
          userName: 'admin',
          useHttps: true,
          allowUntrustedCertificates: false,
        );
      });

      test('should save server configurations', () async {
        await mockCloudKit.initialize();

        final result = await mockCloudKit.saveServerConfig(testConfig);
        expect(result, isTrue);
        expect(mockCloudKit.mockConfigCount, equals(1));
      });

      test('should fetch server configurations', () async {
        await mockCloudKit.initialize();

        // Add mock config
        mockCloudKit.addMockConfig(testConfig);

        final configs = await mockCloudKit.fetchServerConfigs();
        expect(configs.length, equals(1));
        expect(configs.first.id, equals(testConfig.id));
        expect(configs.first.displayName, equals(testConfig.displayName));
      });

      test('should update server configurations', () async {
        await mockCloudKit.initialize();

        // Save initial config
        await mockCloudKit.saveServerConfig(testConfig);

        // Update config
        final updatedConfig = testConfig.copyWith(
          displayName: 'Updated Server Name',
        );
        final result = await mockCloudKit.updateServerConfig(updatedConfig);
        expect(result, isTrue);

        // Verify update
        final configs = await mockCloudKit.fetchServerConfigs();
        expect(configs.length, equals(1));
        expect(configs.first.displayName, equals('Updated Server Name'));
      });

      test('should delete server configurations', () async {
        await mockCloudKit.initialize();

        // Save config
        await mockCloudKit.saveServerConfig(testConfig);
        expect(mockCloudKit.mockConfigCount, equals(1));

        // Delete config
        final result = await mockCloudKit.deleteServerConfig(testConfig.id);
        expect(result, isTrue);
        expect(mockCloudKit.mockConfigCount, equals(0));
      });
    });

    group('Monitoring', () {
      test('should start and stop monitoring', () async {
        await mockCloudKit.initialize();

        expect(mockCloudKit.isMonitoring, isFalse);

        await mockCloudKit.startMonitoring();
        expect(mockCloudKit.isMonitoring, isTrue);

        await mockCloudKit.stopMonitoring();
        expect(mockCloudKit.isMonitoring, isFalse);
      });

      test('should emit updates through stream', () async {
        await mockCloudKit.initialize();
        await mockCloudKit.startMonitoring();

        final testConfig = ServerConfigDTO(
          id: 'test-id',
          displayName: 'Test',
          hostName: 'test.local',
          userName: 'user',
          useHttps: true,
          allowUntrustedCertificates: false,
        );

        // Listen for stream updates
        final updates = <List<ServerConfigDTO>>[];
        final subscription =
            mockCloudKit.serverConfigsStream.listen(updates.add);

        // Trigger update
        await mockCloudKit.saveServerConfig(testConfig);

        // Wait for stream update
        await Future.delayed(const Duration(milliseconds: 10));

        expect(updates.length, equals(1));
        expect(updates.first.length, equals(1));
        expect(updates.first.first.id, equals(testConfig.id));

        await subscription.cancel();
      });

      test('should simulate remote updates', () async {
        await mockCloudKit.initialize();

        final configs = [
          ServerConfigDTO(
            id: 'remote-1',
            displayName: 'Remote Server 1',
            hostName: 'remote1.local',
            userName: 'user',
            useHttps: true,
            allowUntrustedCertificates: false,
          ),
          ServerConfigDTO(
            id: 'remote-2',
            displayName: 'Remote Server 2',
            hostName: 'remote2.local',
            userName: 'user',
            useHttps: true,
            allowUntrustedCertificates: false,
          ),
        ];

        // Listen for updates
        final updates = <List<ServerConfigDTO>>[];
        final subscription =
            mockCloudKit.serverConfigsStream.listen(updates.add);

        // Simulate remote update
        mockCloudKit.simulateRemoteUpdate(configs);

        // Wait for stream update
        await Future.delayed(const Duration(milliseconds: 10));

        expect(updates.length, equals(1));
        expect(updates.first.length, equals(2));

        await subscription.cancel();
      });
    });

    group('Test Helpers', () {
      test('should fail operations when configured', () async {
        mockCloudKit.setShouldFailOperations(true);

        // Initialization should fail
        expect(await mockCloudKit.initialize(), isFalse);

        // All operations should fail
        final testConfig = ServerConfigDTO(
          id: 'test',
          displayName: 'Test',
          hostName: 'test.local',
          userName: 'user',
          useHttps: true,
          allowUntrustedCertificates: false,
        );

        expect(await mockCloudKit.saveServerConfig(testConfig), isFalse);
        expect(await mockCloudKit.updateServerConfig(testConfig), isFalse);
        expect(await mockCloudKit.deleteServerConfig('test'), isFalse);
        expect(await mockCloudKit.fetchServerConfigs(), isEmpty);
      });

      test('should add delay when configured', () async {
        mockCloudKit.setOperationDelay(100);

        final stopwatch = Stopwatch()..start();
        await mockCloudKit.initialize();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(90));
      });

      test('should clear mock configs', () async {
        await mockCloudKit.initialize();

        final testConfig = ServerConfigDTO(
          id: 'test',
          displayName: 'Test',
          hostName: 'test.local',
          userName: 'user',
          useHttps: true,
          allowUntrustedCertificates: false,
        );

        mockCloudKit.addMockConfig(testConfig);
        expect(mockCloudKit.mockConfigCount, equals(1));

        mockCloudKit.clearMockConfigs();
        expect(mockCloudKit.mockConfigCount, equals(0));
      });

      test('should simulate sync errors', () async {
        await mockCloudKit.initialize();

        final errors = <dynamic>[];
        final subscription = mockCloudKit.serverConfigsStream.listen(
          (_) {},
          onError: errors.add,
        );

        mockCloudKit.simulateSyncError('Test sync error');

        // Wait for error
        await Future.delayed(const Duration(milliseconds: 10));

        expect(errors.length, equals(1));
        expect(errors.first, equals('Test sync error'));

        await subscription.cancel();
      });
    });

    group('Disposal', () {
      test('should dispose properly', () async {
        await mockCloudKit.initialize();
        await mockCloudKit.startMonitoring();

        expect(mockCloudKit.isInitialized, isTrue);
        expect(mockCloudKit.isMonitoring, isTrue);

        mockCloudKit.dispose();

        expect(mockCloudKit.isInitialized, isFalse);
        expect(mockCloudKit.isMonitoring, isFalse);
      });
    });
  });
}
