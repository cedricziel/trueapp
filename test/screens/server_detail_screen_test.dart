import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Regression coverage for ticket #86: `ServerDetailScreen` overflowed
/// horizontally at phone widths. Its section headers built a bare
/// `Row(mainAxisAlignment: spaceBetween, ...)`, and a non-flex `Row` child
/// is laid out with unbounded main-axis constraints, so neither the title
/// nor the trailing action could shrink - at 390pt the "Storage Pools"
/// header alone overflowed.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
    );
  }

  testWidgets('renders at iPhone width without layout overflow', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilFound(tester, find.text('Storage Pools'));

    // Guard against the assertion below being vacuous: if the screen had
    // silently fallen back to the authentication spinner or lock screen
    // instead of the real content, there would be nothing left to overflow.
    expect(find.text('Storage Pools'), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });

  testWidgets(
    'renders the lower sections at iPhone width without layout overflow',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      await tester.pumpWidget(createTestApp());
      await pumpUntilFound(tester, find.text('Storage Pools'));
      expectNoLayoutOverflow(tester);

      // RenderFlex overflow is only reported at paint time, so a Row below
      // the fold of the ListView never reports until it is scrolled into
      // view.
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expectNoLayoutOverflow(tester);
    },
  );

  testWidgets(
    'renders a loaded pool with a long name at iPhone width without layout '
    'overflow',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      final poolProvider = _FakePoolProvider(unifiedServerService, [
        {
          'name': 'a-very-long-storage-pool-name-that-stresses-the-card',
          'status': 'ONLINE',
          'healthy': true,
          'topology': <String, dynamic>{},
        },
      ]);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(
        provideAppProviders(
          database: database,
          service: unifiedServerService,
          serverProvider: serverProvider,
          poolProvider: poolProvider,
          child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
        ),
      );
      await pumpUntilFound(tester, find.text('Storage Pools'));

      expect(
        find.textContaining('a-very-long-storage-pool-name'),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);
    },
  );

  testWidgets(
    'renders a favorite app with resource usage, an upgrade and a long '
    'category list at iPhone width without layout overflow',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      // Ticket #86 reported a second overflow beyond the section headers'
      // 29px one, but the investigation that shipped alongside the
      // SectionHeader fix could not reproduce it in the empty-provider
      // state or with a seeded PoolProvider - AppCardWidget's several
      // `Row(children: [..., Spacer(), ...])` layouts (categories/version,
      // network usage, ports) were never exercised with real installed-app
      // data. This seeds exactly that: a favorite, installed app with
      // resource usage, an available upgrade, a long category list and a
      // port - everything AppCardWidget conditionally renders.
      const longApp = App(
        name: 'a-favorite-app-with-a-long-instance-name',
        title: 'A Favorite App With A Long Instance Name',
        description: 'A test app',
        installed: true,
        healthy: true,
        latestVersion: '2.0.0',
        latestAppVersion: '2.0.0',
        latestHumanVersion: '2.0.0',
        categories: [
          'Media & Streaming Applications',
          'Network & Communication Tools',
        ],
        tags: [],
        screenshots: [],
        sources: [],
        maintainers: [],
        recommended: false,
        catalog: 'community',
        train: 'community',
        resourceUsage: AppResourceUsage(
          cpuUsage: 42.5,
          memoryUsage: 512 * 1024 * 1024,
          memoryLimit: 1024 * 1024 * 1024,
          networkRxBytes: 12345678,
          networkTxBytes: 987654,
        ),
        upgradeInfo: AppUpgradeInfo(
          upgradeAvailable: true,
          availableVersion: '2.1.0',
          currentVersion: '2.0.0',
          canUpgrade: true,
        ),
        usedPorts: [
          AppPortInfo(
            containerPort: 8080,
            protocol: 'tcp',
            hostPorts: [AppHostPort(hostPort: 8080, hostIp: '0.0.0.0')],
          ),
        ],
        portals: {'Web UI': 'http://192.168.1.100:8080'},
      );
      final favoriteConfig = AppConfig(
        serverId: testServer.id,
        appName: longApp.name,
        isFavorite: true,
        installed: true,
      );

      final appProvider = _FakeAppProvider(
        database: database,
        serverService: unifiedServerService,
        seedApps: [longApp],
        seedFavorites: [favoriteConfig],
      );
      addTearDown(appProvider.dispose);

      await tester.pumpWidget(
        provideAppProviders(
          database: database,
          service: unifiedServerService,
          serverProvider: serverProvider,
          appProvider: appProvider,
          child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
        ),
      );
      await pumpUntilFound(
        tester,
        find.textContaining('a-favorite-app-with-a-long-instance-name'),
      );
      // Installed apps display their instance `name`, not `title` - see
      // `App.effectiveDisplayName`.
      expect(
        find.textContaining('a-favorite-app-with-a-long-instance-name'),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pump();

      expectNoLayoutOverflow(tester);
    },
  );

  testWidgets(
    'unsubscribes from system stats when the screen is disposed '
    '(regression test for #102)',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      final systemStatsProvider = _RecordingSystemStatsProvider(
        unifiedServerService,
      );
      addTearDown(systemStatsProvider.dispose);

      await tester.pumpWidget(
        provideAppProviders(
          database: database,
          service: unifiedServerService,
          serverProvider: serverProvider,
          systemStatsProvider: systemStatsProvider,
          child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
        ),
      );
      await pumpUntilFound(tester, find.text('Storage Pools'));

      expect(systemStatsProvider.unsubscribeCallCount, 0);

      // Replacing the whole tree tears down ServerDetailScreen's State,
      // running its dispose() - the same teardown a back navigation or tab
      // switch triggers in the real app.
      await tester.pumpWidget(const CupertinoApp(home: SizedBox.shrink()));

      expect(systemStatsProvider.unsubscribeCallCount, 1);
    },
  );
}

/// A [SystemStatsProvider] that records how many times
/// [unsubscribeFromStats] is called, so tests can assert the subscription
/// is torn down on screen disposal without a live API client.
class _RecordingSystemStatsProvider extends SystemStatsProvider {
  _RecordingSystemStatsProvider(super.service);

  int unsubscribeCallCount = 0;

  @override
  Future<void> unsubscribeFromStats() async {
    unsubscribeCallCount++;
    await super.unsubscribeFromStats();
  }
}

/// An [AppProvider] whose [apps] and [favoriteApps] are seeded directly,
/// bypassing the network/database round trip so a widget test can render
/// `AppCardWidget` with realistic data - resource usage, an upgrade, ports -
/// without a live API client.
class _FakeAppProvider extends AppProvider {
  _FakeAppProvider({
    required super.database,
    required super.serverService,
    required List<App> seedApps,
    required List<AppConfig> seedFavorites,
  }) : _seedApps = seedApps,
       _seedFavorites = seedFavorites;

  final List<App> _seedApps;
  final List<AppConfig> _seedFavorites;

  @override
  List<App> get apps => _seedApps;

  @override
  List<AppConfig> get favoriteApps => _seedFavorites;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}

/// A [PoolProvider] whose [pools] is seeded directly, bypassing the network
/// and credential flow so a widget test can render `PoolCardWidget` with
/// realistic data without a live API client.
class _FakePoolProvider extends PoolProvider {
  _FakePoolProvider(super.service, this._seedPools);

  final List<Map<String, dynamic>> _seedPools;

  @override
  List<Map<String, dynamic>> get pools => _seedPools;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;
}
