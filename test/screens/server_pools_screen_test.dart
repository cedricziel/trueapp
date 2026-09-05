import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_pools_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

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

  Widget createTestApp(PoolProvider poolProvider) {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      poolProvider: poolProvider,
      child: CupertinoApp(home: ServerPoolsScreen(server: testServer)),
    );
  }

  /// Registers [fakeClient] as the server's API client so the screen's own
  /// `setApiClient` + `loadPools()` in `initState` drive a real
  /// `PoolProvider` through the mocked network path, rather than seeding a
  /// fake provider's getters directly.
  Future<PoolProvider> realPoolProvider(FakeApiClient fakeClient) async {
    await unifiedServerService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(
      testServer.id,
      fakeClient,
    );
    return PoolProvider(unifiedServerService);
  }

  group('ServerPoolsScreen - loading and empty states', () {
    testWidgets('shows an activity indicator while pools are loading', (
      tester,
    ) async {
      // `isLoading` only flips true once real async work (setApiClient's
      // keychain lookup, then loadPools) actually progresses, which a plain
      // `pump()` inside the FakeAsync test zone can't drive - catching that
      // exact transient frame would be racy. A provider whose `isLoading`
      // getter is pinned to `true` tests the screen's loading branch
      // directly and deterministically instead.
      final loadingPoolProvider = _AlwaysLoadingPoolProvider(
        unifiedServerService,
      );
      addTearDown(loadingPoolProvider.dispose);

      await tester.pumpWidget(createTestApp(loadingPoolProvider));
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows "No pools found" once loading finishes with none', (
      tester,
    ) async {
      final fakeClient = FakeApiClient()..pools = [];
      final poolProvider = await realPoolProvider(fakeClient);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await pumpUntilAsync(
        tester,
        () => find.text('No pools found').evaluate().isNotEmpty,
      );

      expect(find.text('No pools found'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
        findsOneWidget,
      );
    });

    testWidgets('the navigation bar shows the server name and pops on Back', (
      tester,
    ) async {
      final fakeClient = FakeApiClient()..pools = [];
      final poolProvider = await realPoolProvider(fakeClient);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await pumpUntilAsync(
        tester,
        () => find.text('No pools found').evaluate().isNotEmpty,
      );

      expect(find.text('Test Server - Pools'), findsOneWidget);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Back'));
      await tester.pump();
      // Popping the only route in a bare `CupertinoApp(home: ...)` leaves
      // the screen in place (nothing to pop to) rather than throwing.
      expect(tester.takeException(), isNull);
    });
  });

  group('ServerPoolsScreen - populated list', () {
    testWidgets('tapping a pool tile navigates to its detail screen', (
      tester,
    ) async {
      final fakeClient = FakeApiClient()
        ..pools = [
          {
            'name': 'tank',
            'status': 'ONLINE',
            'healthy': true,
            'topology': <String, dynamic>{},
          },
        ];
      final poolProvider = await realPoolProvider(fakeClient);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await pumpUntilAsync(
        tester,
        () => find.text('tank').evaluate().isNotEmpty,
      );

      await tester.tap(find.text('tank'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // `PoolDetailScreen` titles its navigation bar with the pool name too,
      // so after the push there are two - one per screen in the stack.
      expect(find.text('tank'), findsWidgets);
      expect(find.widgetWithText(CupertinoButton, 'Back'), findsWidgets);
    });

    group('pool type description', () {
      Future<void> pumpWithTopology(
        WidgetTester tester,
        Map<String, dynamic> topology,
      ) async {
        final fakeClient = FakeApiClient()
          ..pools = [
            {
              'name': 'tank',
              'status': 'ONLINE',
              'healthy': true,
              'topology': topology,
            },
          ];
        final poolProvider = await realPoolProvider(fakeClient);
        addTearDown(poolProvider.dispose);

        await tester.pumpWidget(createTestApp(poolProvider));
        await pumpUntilAsync(
          tester,
          () => find.text('tank').evaluate().isNotEmpty,
        );
      }

      testWidgets('describes a mirror vdev with its drive count', (
        tester,
      ) async {
        await pumpWithTopology(tester, {
          'data': [
            {
              'type': 'mirror',
              'children': [<String, dynamic>{}, <String, dynamic>{}],
            },
          ],
        });
        expect(find.text('Mirror (2 drives)'), findsOneWidget);
      });

      testWidgets('describes a raidz1 vdev with its drive count', (
        tester,
      ) async {
        await pumpWithTopology(tester, {
          'data': [
            {
              'type': 'raidz1',
              'children': [
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
              ],
            },
          ],
        });
        expect(find.text('RAID-Z1 (3 drives)'), findsOneWidget);
      });

      testWidgets('describes a raidz2 vdev with its drive count', (
        tester,
      ) async {
        await pumpWithTopology(tester, {
          'data': [
            {
              'type': 'raidz2',
              'children': [
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
              ],
            },
          ],
        });
        expect(find.text('RAID-Z2 (4 drives)'), findsOneWidget);
      });

      testWidgets('describes a raidz3 vdev with its drive count', (
        tester,
      ) async {
        await pumpWithTopology(tester, {
          'data': [
            {
              'type': 'raidz3',
              'children': [
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
                <String, dynamic>{},
              ],
            },
          ],
        });
        expect(find.text('RAID-Z3 (5 drives)'), findsOneWidget);
      });

      testWidgets('describes a single-drive vdev', (tester) async {
        await pumpWithTopology(tester, {
          'data': [
            {
              'type': 'disk',
              'children': [<String, dynamic>{}],
            },
          ],
        });
        expect(find.text('Single drive'), findsOneWidget);
      });

      testWidgets('falls back to "Custom configuration" for an unknown '
          'vdev shape', (tester) async {
        await pumpWithTopology(tester, {
          'data': [
            {'type': 'draid'},
          ],
        });
        expect(find.text('Custom configuration'), findsOneWidget);
      });

      testWidgets('falls back to "Unknown configuration" for empty data', (
        tester,
      ) async {
        await pumpWithTopology(tester, {'data': <dynamic>[]});
        expect(find.text('Unknown configuration'), findsOneWidget);
      });

      testWidgets('is omitted entirely when topology is absent', (
        tester,
      ) async {
        final fakeClient = FakeApiClient()
          ..pools = [
            {'name': 'tank', 'status': 'ONLINE', 'healthy': true},
          ];
        final poolProvider = await realPoolProvider(fakeClient);
        addTearDown(poolProvider.dispose);

        await tester.pumpWidget(createTestApp(poolProvider));
        await pumpUntilAsync(
          tester,
          () => find.text('tank').evaluate().isNotEmpty,
        );

        expect(find.text('Unknown configuration'), findsNothing);
        expect(find.text('Custom configuration'), findsNothing);
      });
    });
  });

  group('ServerPoolsScreen - connection error', () {
    testWidgets('shows a retryable connection error and can retry', (
      tester,
    ) async {
      final fakeClient = FakeApiClient()..failingMethods.add('getPools');
      final poolProvider = await realPoolProvider(fakeClient);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await pumpUntilAsync(
        tester,
        () => find
            .widgetWithText(CupertinoButton, 'Try Again')
            .evaluate()
            .isNotEmpty,
      );

      expect(poolProvider.connectionError, isNotNull);
      expect(
        find.text(poolProvider.connectionError!.shortMessage),
        findsOneWidget,
      );

      // Fix the fake so a retry succeeds, then tap "Try Again".
      fakeClient.failingMethods.remove('getPools');
      fakeClient.pools = [
        {
          'name': 'tank',
          'status': 'ONLINE',
          'healthy': true,
          'topology': <String, dynamic>{},
        },
      ];

      await tester.tap(find.widgetWithText(CupertinoButton, 'Try Again'));
      await pumpUntilAsync(
        tester,
        () => find.text('tank').evaluate().isNotEmpty,
      );

      expect(find.text('tank'), findsOneWidget);
      expect(poolProvider.connectionError, isNull);
    });

    testWidgets('"Check Settings" pops the screen', (tester) async {
      final fakeClient = FakeApiClient()..failingMethods.add('getPools');
      final poolProvider = await realPoolProvider(fakeClient);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await pumpUntilAsync(
        tester,
        () => find
            .widgetWithText(CupertinoButton, 'Check Settings')
            .evaluate()
            .isNotEmpty,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Check Settings'));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('ServerPoolsScreen - per-drive topology visualization', () {
    testWidgets('renders a healthy pool with a drive badge per disk', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);
      final poolProvider = _FakePoolProvider(unifiedServerService, [
        Pool.fromJson({
          'name': 'tank',
          'status': 'ONLINE',
          'healthy': true,
          'allocated': 1200,
          'free': 2600,
          'topology': {
            'data': [
              {
                'type': 'MIRROR',
                'children': [
                  {'disk': 'ada0', 'status': 'ONLINE'},
                  {'disk': 'ada1', 'status': 'ONLINE'},
                ],
              },
            ],
          },
        }),
      ]);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await tester.pump();

      expectNoLayoutOverflow(tester);
      expect(find.text('tank'), findsOneWidget);
      expect(find.text('Mirror (2 drives)'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark), findsNWidgets(2));
      expect(find.textContaining('needs attention'), findsNothing);
    });

    testWidgets('flags the specific offline disk in a degraded pool', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);
      final poolProvider = _FakePoolProvider(unifiedServerService, [
        Pool.fromJson({
          'name': 'backup',
          'status': 'DEGRADED',
          'healthy': false,
          'allocated': 3100,
          'free': 4900,
          'topology': {
            'data': [
              {
                'type': 'RAIDZ1',
                'children': [
                  {'disk': 'ada0', 'status': 'ONLINE'},
                  {'disk': 'ada1', 'status': 'ONLINE'},
                  {'disk': 'ada2', 'status': 'ONLINE'},
                  {'disk': 'ada3', 'status': 'OFFLINE'},
                ],
              },
            ],
          },
        }),
      ]);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await tester.pump();

      expectNoLayoutOverflow(tester);
      expect(find.text('ada3 needs attention'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark), findsNWidgets(3));
      expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    });

    testWidgets('does not overflow with a wide RAID-Z2 vdev at iPhone width', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);
      final poolProvider = _FakePoolProvider(unifiedServerService, [
        Pool.fromJson({
          'name': 'archive',
          'status': 'ONLINE',
          'healthy': true,
          'allocated': 0,
          'free': 0,
          'topology': {
            'data': [
              {
                'type': 'RAIDZ2',
                'children': [
                  for (var i = 0; i < 10; i++)
                    {'disk': 'ada$i', 'status': 'ONLINE'},
                ],
              },
            ],
          },
        }),
      ]);
      addTearDown(poolProvider.dispose);

      await tester.pumpWidget(createTestApp(poolProvider));
      await tester.pump();

      expectNoLayoutOverflow(tester);
      expect(find.byIcon(CupertinoIcons.checkmark), findsNWidgets(10));
    });
  });
}

/// A [PoolProvider] whose [isLoading] is pinned to `true`, so a widget test
/// can render `ServerPoolsScreen`'s loading branch deterministically instead
/// of racing real async setup work.
class _AlwaysLoadingPoolProvider extends PoolProvider {
  _AlwaysLoadingPoolProvider(super.service);

  @override
  bool get isLoading => true;
}

/// A [PoolProvider] whose [pools] is seeded directly, bypassing the network
/// and credential flow so a widget test can render `ServerPoolsScreen` with
/// realistic data without a live API client.
class _FakePoolProvider extends PoolProvider {
  _FakePoolProvider(super.service, this._seedPools);

  final List<Pool> _seedPools;

  @override
  List<Pool> get pools => _seedPools;

  @override
  bool get isLoading => false;
}
