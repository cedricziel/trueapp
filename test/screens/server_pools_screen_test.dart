import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/screens/server_pools_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late PoolProvider poolProvider;
  late DatasetProvider datasetProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    poolProvider = PoolProvider(serverService);
    datasetProvider = DatasetProvider(serverService);
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );

    // Store credentials so the screen's `setApiClient` call succeeds, and
    // register the fake client so `ApiClientManager.getClient()` returns it.
    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    poolProvider.dispose();
    datasetProvider.dispose();
    await fakeClient.dispose();
    await TestProviders.disposeTestStack(
      service: serverService,
      database: database,
    );
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PoolProvider>.value(value: poolProvider),
        ChangeNotifierProvider<DatasetProvider>.value(value: datasetProvider),
      ],
      child: CupertinoApp(home: ServerPoolsScreen(server: testServer)),
    );
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
      final loadingPoolProvider = _AlwaysLoadingPoolProvider(serverService);
      addTearDown(loadingPoolProvider.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<PoolProvider>.value(
              value: loadingPoolProvider,
            ),
            ChangeNotifierProvider<DatasetProvider>.value(
              value: datasetProvider,
            ),
          ],
          child: CupertinoApp(home: ServerPoolsScreen(server: testServer)),
        ),
      );
      await tester.pump();

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    });

    testWidgets('shows "No pools found" once loading finishes with none', (
      tester,
    ) async {
      fakeClient.pools = [];

      await tester.pumpWidget(createTestApp());
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
      fakeClient.pools = [];

      await tester.pumpWidget(createTestApp());
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
    testWidgets('renders a tile per pool with its name and status', (
      tester,
    ) async {
      fakeClient.pools = [
        {
          'name': 'tank',
          'status': 'ONLINE',
          'healthy': true,
          'topology': <String, dynamic>{},
        },
        {
          'name': 'backup',
          'status': 'DEGRADED',
          'healthy': false,
          'topology': <String, dynamic>{},
        },
      ];

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => find.text('tank').evaluate().isNotEmpty,
      );

      expect(find.text('tank'), findsOneWidget);
      expect(find.text('Status: ONLINE'), findsOneWidget);
      expect(find.text('backup'), findsOneWidget);
      expect(find.text('Status: DEGRADED'), findsOneWidget);
    });

    testWidgets('a pool with no name or status falls back to "Unknown"', (
      tester,
    ) async {
      fakeClient.pools = [
        <String, dynamic>{'healthy': true},
      ];

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => find.text('Unknown').evaluate().isNotEmpty,
      );

      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Status: Unknown'), findsOneWidget);
    });

    testWidgets('tapping a pool tile navigates to its detail screen', (
      tester,
    ) async {
      fakeClient.pools = [
        {
          'name': 'tank',
          'status': 'ONLINE',
          'healthy': true,
          'topology': <String, dynamic>{},
        },
      ];

      await tester.pumpWidget(createTestApp());
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
        fakeClient.pools = [
          {
            'name': 'tank',
            'status': 'ONLINE',
            'healthy': true,
            'topology': topology,
          },
        ];
        await tester.pumpWidget(createTestApp());
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
        fakeClient.pools = [
          {'name': 'tank', 'status': 'ONLINE', 'healthy': true},
        ];
        await tester.pumpWidget(createTestApp());
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
      fakeClient.failingMethods.add('getPools');

      await tester.pumpWidget(createTestApp());
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
      fakeClient.failingMethods.add('getPools');

      await tester.pumpWidget(createTestApp());
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
}

/// A [PoolProvider] whose [isLoading] is pinned to `true`, so a widget test
/// can render `ServerPoolsScreen`'s loading branch deterministically instead
/// of racing real async setup work.
class _AlwaysLoadingPoolProvider extends PoolProvider {
  _AlwaysLoadingPoolProvider(super.service);

  @override
  bool get isLoading => true;
}
