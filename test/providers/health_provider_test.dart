import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/alert_event.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late HealthProvider provider;
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
    provider = HealthProvider(
      clientManager: TestProviders.mockApiClientManager,
      serverService,
      telemetryService: telemetryService,
    );
    fakeClient = FakeApiClient();

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

  group('HealthProvider - initial state', () {
    test('starts empty and not loading', () {
      expect(provider.alerts, isEmpty);
      expect(provider.activeAlerts, isEmpty);
      expect(provider.services, isEmpty);
      expect(provider.serverHealth, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNull);
      expect(provider.error, isNull);
    });
  });

  group('HealthProvider - setServer', () {
    test('with a known server obtains an API client', () async {
      await provider.setServer(testServer);
      await provider.loadHealth();

      expect(provider.connectionError, isNull);
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await provider.setServer(orphanServer);
      await provider.loadHealth();

      // loadHealth is a no-op without a client.
      expect(provider.alerts, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('swallows a getClient failure', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await provider.setServer(testServer);
      await provider.loadHealth();

      expect(provider.alerts, isEmpty);
      expect(telemetryService.recordedErrors, hasLength(1));
      expect(
        telemetryService.recordedErrors.single.context,
        'HealthProvider.connect',
      );
    });

    test('releases the previous client before switching', () async {
      await provider.setServer(testServer);

      final secondServer = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: secondServer,
        password: 'password',
      );
      TestProviders.mockApiClientManager.addMockClient(
        secondServer.id,
        FakeApiClient(),
      );

      await provider.setServer(secondServer);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });

    test(
      'a superseded setServer call does not overwrite the newer one',
      () async {
        // Regression coverage: two setServer() calls in flight for the
        // same provider must settle on the second one's client rather than
        // racing to install whichever resolves last.
        final first = provider.setServer(testServer);
        final second = provider.setServer(testServer);
        await Future.wait([first, second]);

        await provider.loadHealth();

        expect(provider.connectionError, isNull);
      },
    );

    test('a call superseded while releasing the previous client does not '
        'overwrite the newer selection', () async {
      // Regression coverage: once a provider already has a current
      // server, switching to two different servers back-to-back races
      // both calls through the same releaseClient() await for that
      // shared previous server - the older one must recognize it has
      // been superseded there and never touch _currentServerId again.
      await provider.setServer(testServer);

      final secondServer = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      final thirdServer = NasServer.create(
        name: 'Third Server',
        host: '192.168.1.102',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: secondServer,
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: thirdServer,
        password: 'password',
      );
      final olderClient = FakeApiClient()
        ..serverHealth = ServerHealth(
          serverId: secondServer.id,
          timestamp: DateTime(2026),
          cpuUsage: 11,
          memoryUsage: 0,
          diskUsage: 0,
          temperature: 0,
          isOnline: true,
          disks: const [],
          network: const NetworkInfo(
            downloadSpeed: 0,
            uploadSpeed: 0,
            totalDownload: 0,
            totalUpload: 0,
          ),
        );
      final newerClient = FakeApiClient()
        ..serverHealth = ServerHealth(
          serverId: thirdServer.id,
          timestamp: DateTime(2026),
          cpuUsage: 99,
          memoryUsage: 0,
          diskUsage: 0,
          temperature: 0,
          isOnline: true,
          disks: const [],
          network: const NetworkInfo(
            downloadSpeed: 0,
            uploadSpeed: 0,
            totalDownload: 0,
            totalUpload: 0,
          ),
        );
      TestProviders.mockApiClientManager.addMockClient(
        secondServer.id,
        olderClient,
      );
      TestProviders.mockApiClientManager.addMockClient(
        thirdServer.id,
        newerClient,
      );

      final older = provider.setServer(secondServer);
      final newer = provider.setServer(thirdServer);
      await Future.wait([older, newer]);

      await provider.loadHealth();

      expect(provider.connectionError, isNull);
      expect(provider.serverHealth?.cpuUsage, 99);

      await olderClient.dispose();
      await newerClient.dispose();
    });
  });

  group('HealthProvider - loadHealth', () {
    test('populates alerts, services and server health on success', () async {
      fakeClient.alerts = [
        {'id': '1', 'level': 'CRITICAL', 'formatted': 'Pool degraded'},
      ];
      fakeClient.services = [
        {'service': 'cifs', 'state': 'RUNNING'},
      ];

      await provider.setServer(testServer);
      await provider.loadHealth();

      expect(provider.alerts, hasLength(1));
      expect(provider.activeAlerts, hasLength(1));
      expect(provider.services, hasLength(1));
      expect(provider.serverHealth, isNotNull);
      expect(provider.connectionError, isNull);
    });

    test('without a client is a no-op', () async {
      await provider.loadHealth();

      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNull);
    });

    test('a getAlerts failure surfaces a connection error', () async {
      fakeClient.failingMethods.add('getAlerts');

      await provider.setServer(testServer);
      await provider.loadHealth();

      expect(provider.isLoading, isFalse);
      expect(provider.connectionError, isNotNull);
      expect(telemetryService.recordedErrors, hasLength(1));
      expect(
        telemetryService.recordedErrors.single.context,
        'HealthProvider.loadHealth',
      );
    });

    test('a load failure is exposed as the tray health error', () async {
      expect(provider.healthError, isNull);
      fakeClient.failingMethods.add('getAlerts');

      await provider.setServer(testServer);
      await provider.loadHealth();

      expect(provider.healthError, provider.error);
      expect(provider.healthError, isNotNull);
    });

    test('refreshHealth re-runs loadHealth', () async {
      await provider.setServer(testServer);
      await provider.refreshHealth();

      expect(provider.connectionError, isNull);
      expect(fakeClient.calls, contains('getAlerts'));
    });
  });

  group('HealthProvider - live alerts', () {
    Map<String, dynamic> alertJson(String id, {bool dismissed = false}) => {
      'uuid': id,
      'level': 'WARNING',
      'formatted': 'Alert $id',
      'dismissed': dismissed,
    };

    AlertEvent event(
      AlertEventType type,
      String id, {
      bool dismissed = false,
    }) => AlertEvent(
      type: type,
      id: id,
      alert: type == AlertEventType.removed
          ? null
          : Alert.fromJson(alertJson(id, dismissed: dismissed)),
    );

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    Future<void> loadWith(List<Map<String, dynamic>> alerts) async {
      fakeClient.alerts = alerts;
      await provider.setServer(testServer);
      await provider.loadHealth();
    }

    test(
      'subscribes to alert changes once, however often health loads',
      () async {
        await loadWith([]);
        await provider.refreshHealth();

        expect(
          fakeClient.calls.where((c) => c == 'subscribeToAlerts'),
          hasLength(1),
        );
      },
    );

    test('an ADDED event appends the alert', () async {
      await loadWith([alertJson('a1')]);

      fakeClient.emitAlertEvent(event(AlertEventType.added, 'a2'));
      await settle();

      expect(provider.alerts.map((a) => a.id), ['a1', 'a2']);
    });

    test('an ADDED event for a known alert replaces it', () async {
      await loadWith([alertJson('a1')]);

      fakeClient.emitAlertEvent(event(AlertEventType.added, 'a1'));
      await settle();

      expect(provider.alerts, hasLength(1));
    });

    test('a CHANGED event updates the alert in place', () async {
      await loadWith([alertJson('a1'), alertJson('a2')]);

      fakeClient.emitAlertEvent(
        event(AlertEventType.changed, 'a1', dismissed: true),
      );
      await settle();

      expect(provider.alerts.map((a) => a.id), ['a1', 'a2']);
      expect(provider.alerts.first.dismissed, isTrue);
      expect(provider.activeAlerts.map((a) => a.id), ['a2']);
    });

    test('a REMOVED event drops the alert', () async {
      await loadWith([alertJson('a1'), alertJson('a2')]);

      fakeClient.emitAlertEvent(event(AlertEventType.removed, 'a1'));
      await settle();

      expect(provider.alerts.map((a) => a.id), ['a2']);
    });

    test('notifies listeners when an event arrives', () async {
      await loadWith([]);
      var notified = 0;
      provider.addListener(() => notified++);

      fakeClient.emitAlertEvent(event(AlertEventType.added, 'a1'));
      await settle();

      expect(notified, 1);
    });

    test('a failing subscription does not fail the health load', () async {
      fakeClient.failingMethods.add('subscribeToAlerts');

      await loadWith([alertJson('a1')]);

      expect(provider.alerts, hasLength(1));
      expect(provider.connectionError, isNull);
      expect(
        telemetryService.recordedErrors.single.context,
        'HealthProvider.subscribeToAlerts',
      );
    });

    test('switching server unsubscribes from the previous client', () async {
      await loadWith([alertJson('a1')]);
      final secondServer = NasServer.create(
        name: 'Second Server',
        host: '192.168.1.101',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: secondServer,
        password: 'password',
      );
      final secondClient = FakeApiClient();
      TestProviders.mockApiClientManager.addMockClient(
        secondServer.id,
        secondClient,
      );

      await provider.setServer(secondServer);

      expect(fakeClient.calls, contains('unsubscribeFromAlerts'));
      expect(provider.alerts, isEmpty);

      fakeClient.emitAlertEvent(event(AlertEventType.added, 'stale'));
      await settle();
      expect(provider.alerts, isEmpty);

      await provider.loadHealth();
      expect(secondClient.calls, contains('subscribeToAlerts'));
      await secondClient.dispose();
    });

    test('dispose unsubscribes from alert changes', () async {
      final scoped = HealthProvider(
        clientManager: TestProviders.mockApiClientManager,
        serverService,
      );
      await scoped.setServer(testServer);
      await scoped.loadHealth();

      scoped.dispose();
      await settle();

      expect(fakeClient.calls, contains('unsubscribeFromAlerts'));
    });

    group('dismiss and restore', () {
      test(
        'dismissAlert hides the alert before the request completes',
        () async {
          await loadWith([alertJson('a1'), alertJson('a2')]);
          final gate = Completer<void>();
          fakeClient.alertActionGate = gate.future;

          final result = provider.dismissAlert('a1');

          expect(provider.activeAlerts.map((a) => a.id), ['a2']);
          expect(provider.alerts.first.dismissed, isTrue);

          gate.complete();
          expect(await result, isTrue);
          expect(fakeClient.dismissedAlertIds, ['a1']);
          expect(provider.activeAlerts.map((a) => a.id), ['a2']);
        },
      );

      test('dismissAlert rolls back and reports a failed request', () async {
        await loadWith([alertJson('a1')]);
        fakeClient.failingMethods.add('dismissAlert');

        final ok = await provider.dismissAlert('a1');

        expect(ok, isFalse);
        expect(provider.activeAlerts.map((a) => a.id), ['a1']);
        expect(
          telemetryService.recordedErrors.single.context,
          'HealthProvider.dismissAlert',
        );
      });

      test('restoreAlert brings a dismissed alert back', () async {
        await loadWith([alertJson('a1', dismissed: true)]);
        expect(provider.activeAlerts, isEmpty);

        final ok = await provider.restoreAlert('a1');

        expect(ok, isTrue);
        expect(fakeClient.restoredAlertIds, ['a1']);
        expect(provider.activeAlerts.map((a) => a.id), ['a1']);
      });

      test('restoreAlert rolls back a failed request', () async {
        await loadWith([alertJson('a1', dismissed: true)]);
        fakeClient.failingMethods.add('restoreAlert');

        final ok = await provider.restoreAlert('a1');

        expect(ok, isFalse);
        expect(provider.activeAlerts, isEmpty);
        expect(provider.alerts.single.dismissed, isTrue);
      });

      test(
        'a failed dismiss does not resurrect an alert removed meanwhile',
        () async {
          await loadWith([alertJson('a1')]);
          final gate = Completer<void>();
          fakeClient
            ..alertActionGate = gate.future
            ..failingMethods.add('dismissAlert');

          final result = provider.dismissAlert('a1');
          fakeClient.emitAlertEvent(event(AlertEventType.removed, 'a1'));
          await settle();
          gate.complete();
          await result;

          expect(provider.alerts, isEmpty);
        },
      );

      test('dismissing an unknown alert still asks the server', () async {
        await loadWith([]);

        expect(await provider.dismissAlert('ghost'), isTrue);
        expect(fakeClient.dismissedAlertIds, ['ghost']);
      });

      test('without a client reports failure', () async {
        expect(await provider.dismissAlert('a1'), isFalse);
        expect(await provider.restoreAlert('a1'), isFalse);
      });
    });

    group('showing dismissed alerts', () {
      test('are hidden by default and shown on request', () async {
        await loadWith([alertJson('a1'), alertJson('a2', dismissed: true)]);

        expect(provider.showDismissed, isFalse);
        expect(provider.visibleAlerts.map((a) => a.id), ['a1']);
        expect(provider.hasDismissedAlerts, isTrue);

        provider.showDismissed = true;

        expect(provider.visibleAlerts.map((a) => a.id), ['a1', 'a2']);
        expect(provider.activeAlerts.map((a) => a.id), ['a1']);
      });
    });
  });

  group('HealthProvider - dispose', () {
    test('releases the active client', () async {
      final scoped = HealthProvider(
        clientManager: TestProviders.mockApiClientManager,
        serverService,
      );
      await scoped.setServer(testServer);

      scoped.dispose();
      await Future<void>.delayed(Duration.zero);

      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });
}
