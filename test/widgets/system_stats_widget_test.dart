import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/system_stats.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/system_stats_widget.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

const ZfsStats _emptyZfs = ZfsStats(
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
);

SystemStats _stats({
  double cpuUsage = 42.0,
  Map<String, CpuCore> cores = const {},
  int arcSize = 1000,
  int physicalMemoryTotal = 8000,
  int physicalMemoryAvailable = 4000,
  double readOps = 1.0,
  double readBytes = 2048,
  double writeOps = 3.0,
  double writeBytes = 4096,
  double busy = 5.0,
  Map<String, NetworkInterfaceStats> interfaces = const {},
}) {
  return SystemStats(
    cpu: CpuStats(
      overall: CpuCore(usage: cpuUsage),
      cores: cores,
    ),
    memory: MemoryStats(
      arcSize: arcSize,
      arcFreeMemory: 500,
      arcAvailableMemory: 500,
      physicalMemoryTotal: physicalMemoryTotal,
      physicalMemoryAvailable: physicalMemoryAvailable,
    ),
    zfs: _emptyZfs,
    disks: DiskStats(
      readOps: readOps,
      readBytes: readBytes,
      writeOps: writeOps,
      writeBytes: writeBytes,
      busy: busy,
    ),
    interfaces: interfaces,
    timestamp: DateTime(2026),
  );
}

/// A [FakeApiClient] whose `subscribeToSystemStats()` hangs until
/// [subscribeGate] is completed.
///
/// `subscribeToStats()` on the provider flips `isLoading` to true, then
/// `await`s this call before flipping it back. `FakeApiClient`'s own
/// implementation resolves immediately, and any real `await` inside
/// `tester.pumpWidget` flushes that resolution as a microtask well before
/// the widget actually renders - so the ordinary fake can never be observed
/// mid-subscribe. Gating the call on an uncompleted [Completer] instead
/// keeps the provider suspended in its loading state for as long as the
/// test needs it there.
class _SlowFakeApiClient extends FakeApiClient {
  final Completer<void> subscribeGate = Completer<void>();

  @override
  Future<void> subscribeToSystemStats() async {
    calls.add('subscribeToSystemStats');
    await subscribeGate.future;
  }
}

/// Bundles the plumbing a populated-state test needs: a real
/// [SystemStatsProvider] wired to a [FakeApiClient] through the same
/// [TestProviders] seam `system_stats_provider_test.dart` uses, so pushing
/// stats through [FakeApiClient.emitSystemStats] drives the widget exactly
/// as it would be driven in the app.
class _Harness {
  _Harness({
    required this.database,
    required this.serverService,
    required this.provider,
    required this.fakeClient,
    required this.server,
  });

  final AppDatabase database;
  final UnifiedServerService serverService;
  final SystemStatsProvider provider;
  final FakeApiClient fakeClient;
  final NasServer server;

  Future<void> dispose() async {
    provider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  }
}

Future<_Harness> _buildHarness() async {
  await TestProviders.cleanupTestEnvironment();
  TestProviders.setupTestEnvironment();

  final database = createTestDatabase();
  final serverService = await TestProviders.createMockUnifiedServerService(
    database: database,
  );
  final provider = SystemStatsProvider(serverService);
  final fakeClient = FakeApiClient();

  final server = NasServer.create(
    name: 'Test Server',
    host: '192.168.1.100',
    username: 'admin',
    password: 'password',
  );
  await serverService.saveServerConfig(server: server, password: 'password');
  TestProviders.mockApiClientManager.addMockClient(server.id, fakeClient);

  return _Harness(
    database: database,
    serverService: serverService,
    provider: provider,
    fakeClient: fakeClient,
    server: server,
  );
}

/// Wraps [SystemStatsWidget] for a test. `ResponsiveRow` (used internally by
/// the widget) reads the *actual* `MediaQuery` width to decide between its
/// row and column layouts, not a locally-constrained width - so the test
/// surface itself must be sized with [useCompactSurface]/[useRegularSurface]
/// (call that before `pumpWidget`) rather than by wrapping this in a
/// fixed-width `SizedBox`, or the widget lays out for one width while being
/// constrained to another and overflows.
Widget _wrap(SystemStatsProvider provider) {
  return CupertinoApp(
    home: ChangeNotifierProvider<SystemStatsProvider>.value(
      value: provider,
      child: SingleChildScrollView(child: const SystemStatsWidget()),
    ),
  );
}

void main() {
  group('SystemStatsWidget - empty state', () {
    testWidgets('shows the empty view when there is no data yet', (
      tester,
    ) async {
      final harness = await _buildHarness();
      addTearDown(harness.dispose);

      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      expect(find.text('No system stats available'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chart_bar), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
      expectNoLayoutOverflow(tester);
    });
  });

  group('SystemStatsWidget - loading state', () {
    testWidgets('shows a spinner while loading and without data', (
      tester,
    ) async {
      await TestProviders.cleanupTestEnvironment();
      TestProviders.setupTestEnvironment();
      final database = createTestDatabase();
      final serverService = await TestProviders.createMockUnifiedServerService(
        database: database,
      );
      final provider = SystemStatsProvider(serverService);
      final slowClient = _SlowFakeApiClient();
      final server = NasServer.create(
        name: 'Test Server',
        host: '192.168.1.100',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(
        server: server,
        password: 'password',
      );
      TestProviders.mockApiClientManager.addMockClient(server.id, slowClient);
      addTearDown(() async {
        provider.dispose();
        await slowClient.dispose();
        await serverService.dispose();
        await TestProviders.cleanupTestEnvironment();
      });

      await provider.setApiClient(server);
      // subscribeToStats() suspends on _SlowFakeApiClient's gate, so the
      // provider stays in its loading state for as long as this test needs.
      final pending = provider.subscribeToStats();

      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(provider));

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('No system stats available'), findsNothing);
      expectNoLayoutOverflow(tester);

      slowClient.subscribeGate.complete();
      await pending;
    });
  });

  group('SystemStatsWidget - error state', () {
    testWidgets('shows the error view when there is no data', (tester) async {
      final harness = await _buildHarness();
      addTearDown(harness.dispose);

      // No credentials saved for this server, so `setApiClient` leaves the
      // client unset and `subscribeToStats` reports the "No API client
      // configured" error synchronously.
      final orphan = NasServer.create(
        name: 'No Credentials',
        host: '192.168.1.200',
        username: 'admin',
        password: 'password',
      );
      await harness.provider.setApiClient(orphan);
      await harness.provider.subscribeToStats();

      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      expect(
        find.text('Failed to load system stats: No API client configured'),
        findsOneWidget,
      );
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);
    });
  });

  group('SystemStatsWidget - populated state', () {
    Future<_Harness> subscribedHarness() async {
      final harness = await _buildHarness();
      await harness.provider.setApiClient(harness.server);
      await harness.provider.subscribeToStats();
      return harness;
    }

    testWidgets(
      'renders CPU, memory and disk sections with low usage (green)',
      (tester) async {
        final harness = await subscribedHarness();
        addTearDown(harness.dispose);

        harness.fakeClient.emitSystemStats(
          _stats(
            cpuUsage: 30.0,
            physicalMemoryTotal: 8000,
            physicalMemoryAvailable: 4000,
            arcSize: 1000,
            readOps: 12.5,
            writeOps: 7.5,
            readBytes: 2048,
            writeBytes: 4096,
            busy: 20.0,
          ),
        );
        await tester.pump();
        useCompactSurface(tester);
        await tester.pumpWidget(_wrap(harness.provider));

        expect(find.text('CPU'), findsOneWidget);
        expect(find.text('30.0%'), findsOneWidget);
        expect(find.text('Memory'), findsOneWidget);
        expect(find.text('50.0%'), findsOneWidget); // (8000-4000)/8000
        expect(find.text('Disk I/O'), findsOneWidget);
        expect(find.text('20.0% busy'), findsOneWidget);
        expect(find.text('Read'), findsOneWidget);
        expect(find.text('Write'), findsOneWidget);
        expect(find.text('12.5 ops/s'), findsOneWidget);
        expect(find.text('7.5 ops/s'), findsOneWidget);
        expect(find.text('2.0KB/s'), findsOneWidget);
        expect(find.text('4.0KB/s'), findsOneWidget);
        // Physical: used 4000 / total 8000, ARC: 1000 / total 8000.
        expect(find.text('3.9KB / 7.8KB'), findsOneWidget);
        expect(find.text('1000B / 7.8KB'), findsOneWidget);
        // No cores, no network -> neither section renders.
        expect(find.text('Cores'), findsNothing);
        expect(find.text('Network'), findsNothing);

        final cpuPercent = tester.widget<Text>(find.text('30.0%'));
        expect((cpuPercent.style?.color), CupertinoColors.systemGreen);
        final memPercent = tester.widget<Text>(find.text('50.0%'));
        expect(memPercent.style?.color, CupertinoColors.systemPurple);
        final diskBusy = tester.widget<Text>(find.text('20.0% busy'));
        expect(diskBusy.style?.color, CupertinoColors.systemGreen);

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets('uses orange for medium usage', (tester) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(
        _stats(
          cpuUsage: 70.0,
          physicalMemoryTotal: 100,
          physicalMemoryAvailable: 20, // 80% used -> orange (>75, <=90)
          busy: 70.0,
        ),
      );
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      final cpuPercent = tester.widget<Text>(find.text('70.0%'));
      expect(cpuPercent.style?.color, CupertinoColors.systemOrange);
      final memPercent = tester.widget<Text>(find.text('80.0%'));
      expect(memPercent.style?.color, CupertinoColors.systemOrange);
      final diskBusy = tester.widget<Text>(find.text('70.0% busy'));
      expect(diskBusy.style?.color, CupertinoColors.systemOrange);

      expectNoLayoutOverflow(tester);
    });

    testWidgets('uses red for high usage', (tester) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(
        _stats(
          cpuUsage: 95.0,
          physicalMemoryTotal: 100,
          physicalMemoryAvailable: 8, // 92% used -> red (>90)
          busy: 90.0,
        ),
      );
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      final cpuPercent = tester.widget<Text>(find.text('95.0%'));
      expect(cpuPercent.style?.color, CupertinoColors.systemRed);
      final memPercent = tester.widget<Text>(find.text('92.0%'));
      expect(memPercent.style?.color, CupertinoColors.systemRed);
      final diskBusy = tester.widget<Text>(find.text('90.0% busy'));
      expect(diskBusy.style?.color, CupertinoColors.systemRed);

      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'renders a Cores section with up to 8 entries, taking the first 8',
      (tester) async {
        final harness = await subscribedHarness();
        addTearDown(harness.dispose);

        final cores = <String, CpuCore>{
          for (var i = 0; i < 10; i++) 'cpu$i': CpuCore(usage: i * 10.0),
        };
        harness.fakeClient.emitSystemStats(_stats(cores: cores));
        await tester.pump();
        useCompactSurface(tester);
        await tester.pumpWidget(_wrap(harness.provider));

        expect(find.text('Cores'), findsOneWidget);
        // Only the first 8 (by map insertion order, cpu0..cpu7) render.
        expect(find.text('0: 0%'), findsOneWidget);
        expect(find.text('7: 70%'), findsOneWidget);
        expect(find.text('8: 80%'), findsNothing);
        expect(find.text('9: 90%'), findsNothing);

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets('omits the Cores section when there are no per-core stats', (
      tester,
    ) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(_stats());
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      expect(find.text('Cores'), findsNothing);
    });

    testWidgets(
      'renders only active network interfaces, with formatted rates',
      (tester) async {
        final harness = await subscribedHarness();
        addTearDown(harness.dispose);

        harness.fakeClient.emitSystemStats(
          _stats(
            interfaces: const {
              'eth0': NetworkInterfaceStats(
                linkState: 'LINK_STATE_UP',
                speed: 1000,
                receivedBytesRate: 1024,
                // Deliberately distinct from the disk read/write rates
                // (2048/4096 bytes, the `_stats()` defaults) so the two
                // sections' formatted-rate text never collides.
                sentBytesRate: 3072,
              ),
              'eth1': NetworkInterfaceStats(
                linkState: 'LINK_STATE_DOWN',
                speed: 0,
                receivedBytesRate: 0,
                sentBytesRate: 0,
              ),
            },
          ),
        );
        await tester.pump();
        useCompactSurface(tester);
        await tester.pumpWidget(_wrap(harness.provider));

        expect(find.text('Network'), findsOneWidget);
        expect(find.text('eth0'), findsOneWidget);
        expect(find.text('eth1'), findsNothing);
        expect(find.text('UP'), findsOneWidget);
        expect(find.text('1.0KB/s'), findsOneWidget);
        expect(find.text('3.0KB/s'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.wifi), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.arrow_down), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.arrow_up), findsOneWidget);

        expectNoLayoutOverflow(tester);
      },
    );

    testWidgets('omits the Network card entirely when the map is empty', (
      tester,
    ) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(_stats());
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      expect(find.text('Network'), findsNothing);
      expect(find.byIcon(CupertinoIcons.wifi), findsNothing);
    });

    testWidgets('renders nothing extra when interfaces exist but none are up', (
      tester,
    ) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(
        _stats(
          interfaces: const {
            'eth0': NetworkInterfaceStats(
              linkState: 'LINK_STATE_DOWN',
              speed: 0,
              receivedBytesRate: 0,
              sentBytesRate: 0,
            ),
          },
        ),
      );
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      // The widget calls into _NetworkStatsCard (interfaces is not empty
      // at the provider level) but it renders SizedBox.shrink() because no
      // interface is up.
      expect(find.text('Network'), findsNothing);
      expect(find.text('eth0'), findsNothing);

      expectNoLayoutOverflow(tester);
    });

    testWidgets('renders several active interfaces, each with their own row', (
      tester,
    ) async {
      final harness = await subscribedHarness();
      addTearDown(harness.dispose);

      harness.fakeClient.emitSystemStats(
        _stats(
          interfaces: const {
            'eth0': NetworkInterfaceStats(
              linkState: 'LINK_STATE_UP',
              speed: 1000,
              receivedBytesRate: 512,
              sentBytesRate: 512,
            ),
            'eth1': NetworkInterfaceStats(
              linkState: 'LINK_STATE_UP',
              speed: 1000,
              receivedBytesRate: 1024 * 1024,
              sentBytesRate: 1024 * 1024,
            ),
          },
        ),
      );
      await tester.pump();
      useCompactSurface(tester);
      await tester.pumpWidget(_wrap(harness.provider));

      expect(find.text('eth0'), findsOneWidget);
      expect(find.text('eth1'), findsOneWidget);
      expect(find.text('UP'), findsNWidgets(2));

      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'lays out without overflow at phone width with every section populated',
      (tester) async {
        final harness = await subscribedHarness();
        addTearDown(harness.dispose);

        final cores = <String, CpuCore>{
          for (var i = 0; i < 8; i++)
            'cpu$i': CpuCore(usage: (i * 12).toDouble()),
        };
        harness.fakeClient.emitSystemStats(
          _stats(
            cpuUsage: 65.0,
            cores: cores,
            physicalMemoryTotal: 16 * 1024 * 1024 * 1024,
            physicalMemoryAvailable: 4 * 1024 * 1024 * 1024,
            arcSize: 2 * 1024 * 1024 * 1024,
            readOps: 123.4,
            writeOps: 56.7,
            readBytes: 12 * 1024 * 1024,
            writeBytes: 3 * 1024 * 1024,
            busy: 45.0,
            interfaces: const {
              'eth0': NetworkInterfaceStats(
                linkState: 'LINK_STATE_UP',
                speed: 1000,
                receivedBytesRate: 5 * 1024 * 1024,
                sentBytesRate: 1024 * 1024,
              ),
              'wlan0': NetworkInterfaceStats(
                linkState: 'LINK_STATE_UP',
                speed: 100,
                receivedBytesRate: 128 * 1024,
                sentBytesRate: 64 * 1024,
              ),
            },
          ),
        );
        await tester.pump();
        useCompactSurface(tester);
        await tester.pumpWidget(_wrap(harness.provider));
        await tester.pump();

        expect(find.text('Network'), findsOneWidget);
        expect(find.text('Cores'), findsOneWidget);
        expectNoLayoutOverflow(tester);
      },
    );
  });
}
