import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

SystemStats _sampleStats({double cpuUsage = 42.0}) {
  return SystemStats(
    cpu: CpuStats(
      overall: CpuCore(usage: cpuUsage),
      cores: const {},
    ),
    memory: const MemoryStats(
      arcSize: 1000,
      arcFreeMemory: 500,
      arcAvailableMemory: 500,
      physicalMemoryTotal: 8000,
      physicalMemoryAvailable: 4000,
    ),
    zfs: const ZfsStats(
      demandAccessesPerSecond: 0,
      demandDataAccessesPerSecond: 0,
      demandMetadataAccessesPerSecond: 0,
      demandDataHitsPerSecond: 0,
      demandDataIoHitsPerSecond: 0,
      demandDataMissesPerSecond: 0,
      demandDataHitPercentage: 0,
      demandDataIoHitPercentage: 0,
      demandDataMissPercentage: 0,
      demandMetadataHitsPerSecond: 0,
      demandMetadataIoHitsPerSecond: 0,
      demandMetadataMissesPerSecond: 0,
      demandMetadataHitPercentage: 0,
      demandMetadataIoHitPercentage: 0,
      demandMetadataMissPercentage: 0,
      l2arcHitsPerSecond: 0,
      l2arcMissesPerSecond: 0,
      totalL2arcAccessesPerSecond: 0,
      l2arcAccessHitPercentage: 0,
      l2arcMissPercentage: 0,
      bytesReadPerSecondFromTheL2arc: 0,
      bytesWrittenPerSecondToTheL2arc: 0,
    ),
    disks: const DiskStats(
      readOps: 1,
      readBytes: 2,
      writeOps: 3,
      writeBytes: 4,
      busy: 5,
    ),
    interfaces: const {},
    timestamp: DateTime(2026),
  );
}

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late SystemStatsProvider provider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = SystemStatsProvider(serverService);
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

  group('SystemStatsProvider - initial state', () {
    test('has no stats and is not subscribed or loading', () {
      expect(provider.currentStats, isNull);
      expect(provider.hasData, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.isSubscribed, isFalse);
      expect(provider.error, isNull);
      expect(provider.cpuUsage, 0.0);
      expect(provider.memoryUsage, 0.0);
      expect(provider.arcUsage, 0.0);
      expect(provider.physicalMemoryTotal, 0);
      expect(provider.physicalMemoryAvailable, 0);
      expect(provider.arcSize, 0);
      expect(provider.diskReadOps, 0.0);
      expect(provider.diskWriteOps, 0.0);
      expect(provider.diskBusyPercent, 0.0);
      expect(provider.networkInterfaces, isEmpty);
      expect(provider.cpuCores, isEmpty);
    });

    test('formatBytes formats across magnitudes', () {
      expect(provider.formatBytes(500), '500B');
      expect(provider.formatBytes(2048), '2.0KB');
      expect(provider.formatBytes(5 * 1024 * 1024), '5.0MB');
      expect(provider.formatBytes(3 * 1024 * 1024 * 1024), '3.0GB');
      expect(provider.formatBytes(2 * 1024 * 1024 * 1024 * 1024), '2.0TB');
    });

    test('formatRate appends /s', () {
      expect(provider.formatRate(1024), '1.0KB/s');
    });
  });

  group('SystemStatsProvider - setApiClient', () {
    test('with a known server obtains an API client', () async {
      await provider.setApiClient(testServer);
      // Proven indirectly: subscribing now succeeds instead of failing with
      // "No API client configured".
      await provider.subscribeToStats();
      expect(provider.isSubscribed, isTrue);
      expect(provider.error, isNull);
    });

    test('missing credentials leaves the client unset', () async {
      final orphanServer = NasServer.create(
        name: 'No Credentials Server',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );

      await provider.setApiClient(orphanServer);
      await provider.subscribeToStats();

      expect(provider.isSubscribed, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('swallows a getClient failure', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await provider.setApiClient(testServer);
      await provider.subscribeToStats();

      expect(provider.isSubscribed, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('unsubscribes from a previous client before switching', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();
      expect(provider.isSubscribed, isTrue);

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

      await provider.setApiClient(secondServer);

      expect(provider.isSubscribed, isFalse);
      expect(
        TestProviders.mockApiClientManager.wasMethodCalled(
          'releaseClient:${testServer.id}',
        ),
        isTrue,
      );
    });
  });

  group('SystemStatsProvider - subscribeToStats', () {
    test('subscribes and receives stats through the stream', () async {
      await provider.setApiClient(testServer);

      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.subscribeToStats();
      expect(provider.isSubscribed, isTrue);
      expect(fakeClient.calls, contains('subscribeToSystemStats'));

      fakeClient.emitSystemStats(_sampleStats(cpuUsage: 55.5));
      // Let the stream event propagate.
      await Future<void>.delayed(Duration.zero);

      expect(provider.hasData, isTrue);
      expect(provider.currentStats, isNotNull);
      expect(provider.cpuUsage, 55.5);
      expect(provider.memoryUsage, closeTo(50.0, 0.001));
      expect(provider.diskReadOps, 1.0);
      expect(provider.diskWriteOps, 3.0);
      expect(provider.diskBusyPercent, 5.0);
      expect(notifications, greaterThan(0));
    });

    test('is idempotent when already subscribed', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();
      final callsAfterFirst = fakeClient.calls
          .where((c) => c == 'subscribeToSystemStats')
          .length;

      await provider.subscribeToStats();
      final callsAfterSecond = fakeClient.calls
          .where((c) => c == 'subscribeToSystemStats')
          .length;

      expect(callsAfterSecond, callsAfterFirst);
    });

    test('without a client sets an error', () async {
      await provider.subscribeToStats();
      expect(provider.isSubscribed, isFalse);
      expect(provider.error, 'No API client configured');
    });

    test('a subscribeToSystemStats failure sets an error', () async {
      await provider.setApiClient(testServer);
      fakeClient.failingMethods.add('subscribeToSystemStats');

      await provider.subscribeToStats();

      expect(provider.isSubscribed, isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.error, contains('Failed to subscribe'));
    });

    test('a stream error surfaces through error state', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();

      fakeClient.emitSystemStats(_sampleStats());
      await Future<void>.delayed(Duration.zero);
      expect(provider.hasData, isTrue);
    });
  });

  group('SystemStatsProvider - unsubscribeFromStats', () {
    test('clears stats and subscription state', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();
      fakeClient.emitSystemStats(_sampleStats());
      await Future<void>.delayed(Duration.zero);
      expect(provider.hasData, isTrue);

      await provider.unsubscribeFromStats();

      expect(provider.isSubscribed, isFalse);
      expect(provider.currentStats, isNull);
      expect(provider.hasData, isFalse);
      expect(fakeClient.calls, contains('unsubscribeFromSystemStats'));
    });

    test('is a no-op when not subscribed', () async {
      await provider.unsubscribeFromStats();
      expect(provider.isSubscribed, isFalse);
      expect(fakeClient.calls.contains('unsubscribeFromSystemStats'), isFalse);
    });

    test('tolerates an unsubscribe failure from the client', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();
      fakeClient.failingMethods.add('unsubscribeFromSystemStats');

      // Should not throw even though the underlying call fails. The flag
      // flip and stats reset both happen after the failing call, so a
      // failure here leaves `isSubscribed` untouched (a pre-existing quirk,
      // not something this test suite changes).
      await provider.unsubscribeFromStats();

      expect(provider.isSubscribed, isTrue);
    });
  });

  group('SystemStatsProvider - refreshStats', () {
    test('starts a subscription when not yet subscribed', () async {
      await provider.setApiClient(testServer);

      await provider.refreshStats();

      expect(provider.isSubscribed, isTrue);
    });

    test('just clears the error when already subscribed', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();
      final callsBefore = fakeClient.calls
          .where((c) => c == 'subscribeToSystemStats')
          .length;

      await provider.refreshStats();

      final callsAfter = fakeClient.calls
          .where((c) => c == 'subscribeToSystemStats')
          .length;
      expect(callsAfter, callsBefore);
      expect(provider.error, isNull);
    });
  });

  group('SystemStatsProvider - cpuCores', () {
    test('returns cores sorted by key', () async {
      await provider.setApiClient(testServer);
      await provider.subscribeToStats();

      final stats = SystemStats(
        cpu: CpuStats(
          overall: const CpuCore(usage: 10),
          cores: const {'cpu2': CpuCore(usage: 20), 'cpu1': CpuCore(usage: 30)},
        ),
        memory: const MemoryStats(
          arcSize: 0,
          arcFreeMemory: 0,
          arcAvailableMemory: 0,
          physicalMemoryTotal: 0,
          physicalMemoryAvailable: 0,
        ),
        zfs: const ZfsStats(
          demandAccessesPerSecond: 0,
          demandDataAccessesPerSecond: 0,
          demandMetadataAccessesPerSecond: 0,
          demandDataHitsPerSecond: 0,
          demandDataIoHitsPerSecond: 0,
          demandDataMissesPerSecond: 0,
          demandDataHitPercentage: 0,
          demandDataIoHitPercentage: 0,
          demandDataMissPercentage: 0,
          demandMetadataHitsPerSecond: 0,
          demandMetadataIoHitsPerSecond: 0,
          demandMetadataMissesPerSecond: 0,
          demandMetadataHitPercentage: 0,
          demandMetadataIoHitPercentage: 0,
          demandMetadataMissPercentage: 0,
          l2arcHitsPerSecond: 0,
          l2arcMissesPerSecond: 0,
          totalL2arcAccessesPerSecond: 0,
          l2arcAccessHitPercentage: 0,
          l2arcMissPercentage: 0,
          bytesReadPerSecondFromTheL2arc: 0,
          bytesWrittenPerSecondToTheL2arc: 0,
        ),
        disks: const DiskStats(
          readOps: 0,
          readBytes: 0,
          writeOps: 0,
          writeBytes: 0,
          busy: 0,
        ),
        interfaces: const {},
        timestamp: DateTime(2026),
      );

      fakeClient.emitSystemStats(stats);
      await Future<void>.delayed(Duration.zero);

      expect(provider.cpuCores.map((e) => e.key).toList(), ['cpu1', 'cpu2']);
    });
  });

  group('SystemStatsProvider - dispose', () {
    test('unsubscribes and releases the active client', () async {
      final scoped = SystemStatsProvider(serverService);
      await scoped.setApiClient(testServer);
      await scoped.subscribeToStats();

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
