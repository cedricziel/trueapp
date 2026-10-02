import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/services_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late ServicesProvider provider;
  late FakeApiClient fakeClient;
  late FakeTelemetryService telemetryService;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    telemetryService = FakeTelemetryService();
    provider = ServicesProvider(
      serverService,
      clientManager: TestProviders.mockApiClientManager,
      telemetryService: telemetryService,
    );
    fakeClient = FakeApiClient()
      ..services = [
        {'service': 'ssh', 'state': 'STOPPED', 'enable': false},
        {'service': 'cifs', 'state': 'RUNNING', 'enable': true},
      ];

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );
    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    provider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  test('starts empty and idle', () {
    expect(provider.services, isEmpty);
    expect(provider.isLoading, isFalse);
    expect(provider.hasLoaded, isFalse);
    expect(provider.connectionError, isNull);
    expect(provider.actionError, isNull);
  });

  group('loadServices', () {
    test('lists services sorted by display name', () async {
      await provider.setServer(testServer);

      await provider.loadServices();

      expect(provider.services.map((s) => s.id), ['cifs', 'ssh']);
      expect(provider.hasLoaded, isTrue);
      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNull);
    });

    test(
      'reports a connection error and records telemetry on failure',
      () async {
        await provider.setServer(testServer);
        fakeClient.failingMethods.add('getServices');

        await provider.loadServices();

        expect(provider.services, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.connectionError?.type, ConnectionErrorType.unknown);
        expect(
          telemetryService.recordedErrors.single.context,
          'ServicesProvider.loadServices',
        );
      },
    );

    test('is a no-op without a connected server', () async {
      await provider.loadServices();

      expect(fakeClient.calls, isNot(contains('getServices')));
    });
  });

  group('service control', () {
    setUp(() async {
      await provider.setServer(testServer);
      await provider.loadServices();
    });

    test('startService starts the unit and refreshes the list', () async {
      fakeClient.services = [
        {'service': 'ssh', 'state': 'RUNNING', 'enable': false},
        {'service': 'cifs', 'state': 'RUNNING', 'enable': true},
      ];

      await provider.startService('ssh');

      expect(fakeClient.serviceControlCalls, [('start', 'ssh')]);
      expect(provider.services.every((s) => s.isRunning), isTrue);
      expect(provider.actionError, isNull);
    });

    test('stopService stops the unit', () async {
      await provider.stopService('cifs');

      expect(fakeClient.serviceControlCalls, [('stop', 'cifs')]);
    });

    test('restartService restarts the unit', () async {
      await provider.restartService('cifs');

      expect(fakeClient.serviceControlCalls, [('restart', 'cifs')]);
    });

    test('marks the service busy for the duration of the call', () async {
      final busyDuring = <bool>[];
      provider.addListener(() => busyDuring.add(provider.isBusy('ssh')));

      await provider.startService('ssh');

      expect(busyDuring.first, isTrue);
      expect(provider.isBusy('ssh'), isFalse);
      expect(provider.isBusy('cifs'), isFalse);
    });

    test(
      'keeps the list and reports actionError when the call fails',
      () async {
        fakeClient.failingMethods.add('stopService');

        await provider.stopService('cifs');

        expect(provider.services, hasLength(2));
        expect(provider.actionError, isNotNull);
        expect(provider.isBusy('cifs'), isFalse);
        expect(
          telemetryService.recordedErrors.single.context,
          'ServicesProvider.stopService',
        );
      },
    );

    test('clearActionError dismisses the error', () async {
      fakeClient.failingMethods.add('stopService');
      await provider.stopService('cifs');

      provider.clearActionError();

      expect(provider.actionError, isNull);
    });

    test('ignores a second action while the service is busy', () async {
      final first = provider.restartService('cifs');
      final second = provider.restartService('cifs');
      await Future.wait([first, second]);

      expect(fakeClient.serviceControlCalls, [('restart', 'cifs')]);
    });
  });
}
