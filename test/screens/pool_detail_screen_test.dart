import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/screens/dataset_detail_screen.dart';
import 'package:truehub/screens/pool_detail_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late DatasetProvider datasetProvider;
  late JobsProvider jobsProvider;
  late FakeApiClient fakeClient;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    datasetProvider = DatasetProvider(serverService);
    jobsProvider = JobsProvider(serverService);
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
    await TestProviders.disposeTestStack(
      providers: [datasetProvider, jobsProvider],
      service: serverService,
      database: database,
    );
  });

  Widget wrap(Map<String, dynamic> pool, {NasServer? server}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DatasetProvider>.value(value: datasetProvider),
        ChangeNotifierProvider<JobsProvider>.value(value: jobsProvider),
      ],
      child: CupertinoApp(
        home: PoolDetailScreen(server: server ?? testServer, pool: pool),
      ),
    );
  }

  group('PoolDetailScreen - pool info', () {
    testWidgets('shows the pool name in the nav bar title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('tank'), findsOneWidget);
    });

    testWidgets('falls back to Unknown Pool when the name is missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(<String, dynamic>{}));
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Unknown Pool'), findsOneWidget);
    });

    testWidgets('shows Status and a green healthy icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({'name': 'tank', 'status': 'ONLINE', 'healthy': true}),
      );
      await pumpUntilFound(tester, find.text('Datasets'));

      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('Healthy'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
      );
      expect(icon.color, CupertinoColors.systemGreen);
    });

    testWidgets('shows Degraded and a red unhealthy icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({'name': 'tank', 'status': 'DEGRADED', 'healthy': false}),
      );
      await pumpUntilFound(tester, find.text('Datasets'));

      expect(find.text('DEGRADED'), findsOneWidget);
      expect(find.text('Degraded'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
      );
      expect(icon.color, CupertinoColors.systemRed);
    });

    testWidgets('falls back to Unknown for missing status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('hides the Configuration row when topology is missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Configuration'), findsNothing);
    });

    testWidgets('describes a mirror topology with its drive count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {
            'data': [
              {
                'type': 'mirror',
                'children': [
                  {'name': 'disk1'},
                  {'name': 'disk2'},
                ],
              },
            ],
          },
        }),
      );
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('Mirror (2 drives)'), findsOneWidget);
    });

    testWidgets('describes RAID-Z2 with its drive count', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {
            'data': [
              {
                'type': 'raidz2',
                'children': [
                  {'name': 'd0'},
                  {'name': 'd1'},
                  {'name': 'd2'},
                  {'name': 'd3'},
                ],
              },
            ],
          },
        }),
      );
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('RAID-Z2 (4 drives)'), findsOneWidget);
    });

    testWidgets('describes a lone unmatched vdev child as Single drive', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {
            'data': [
              {
                'type': 'disk',
                'children': [
                  {'name': 'disk1'},
                ],
              },
            ],
          },
        }),
      );
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Single drive'), findsOneWidget);
    });

    testWidgets('describes an unmatched multi-child vdev as Custom', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {
            'data': [
              {
                'type': 'stripe',
                'children': [
                  {'name': 'disk1'},
                  {'name': 'disk2'},
                ],
              },
            ],
          },
        }),
      );
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Custom configuration'), findsOneWidget);
    });

    testWidgets('describes empty topology data as Unknown configuration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {'data': <dynamic>[]},
        }),
      );
      await pumpUntilFound(tester, find.text('Datasets'));
      expect(find.text('Unknown configuration'), findsOneWidget);
    });
  });

  group('PoolDetailScreen - dataset list', () {
    testWidgets('shows an error state and Retry re-fetches', (
      WidgetTester tester,
    ) async {
      fakeClient.failingMethods.add('getDatasets');
      fakeClient.datasets = [
        {'name': 'tank/data', 'pool': 'tank'},
      ];

      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('Error loading datasets'));

      expect(find.text('Error loading datasets'), findsOneWidget);
      expect(find.byType(CupertinoButton), findsWidgets);
      expect(find.text('Retry'), findsOneWidget);

      fakeClient.failingMethods.remove('getDatasets');
      await tester.tap(find.text('Retry'));
      await pumpUntilFound(tester, find.text('data'));

      expect(find.text('Error loading datasets'), findsNothing);
      expect(find.text('data'), findsOneWidget);
    });

    testWidgets('shows an empty state when there are no datasets', (
      WidgetTester tester,
    ) async {
      fakeClient.datasets = [];
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('No datasets found'));

      expect(find.text('No datasets found'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.folder), findsOneWidget);
    });

    testWidgets('shows an empty state when no dataset belongs to this pool', (
      WidgetTester tester,
    ) async {
      fakeClient.datasets = [
        {'name': 'other/data', 'pool': 'other'},
      ];
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('No datasets found'));
      expect(find.text('No datasets found'), findsOneWidget);
    });

    testWidgets(
      'lists only datasets for this pool, indented by path depth, with '
      'usage and mountpoint',
      (WidgetTester tester) async {
        fakeClient.datasets = [
          {
            'name': 'tank/data',
            'pool': 'tank',
            'type': 'FILESYSTEM',
            'mountpoint': '/mnt/tank/data',
            'used': {'value': '10GiB'},
            'available': {'value': '90GiB'},
          },
          {
            'name': 'tank/data/nested',
            'pool': 'tank',
            'type': 'VOLUME',
            'used': {'value': '1GiB'},
            'available': {'value': '9GiB'},
          },
          {'name': 'other/data', 'pool': 'other'},
        ];

        await tester.pumpWidget(wrap({'name': 'tank'}));
        await pumpUntilFound(tester, find.text('data'));

        // Only the two tank datasets render - the other pool's is excluded.
        expect(find.text('data'), findsOneWidget);
        expect(find.text('nested'), findsOneWidget);
        expect(find.text('/mnt/tank/data'), findsOneWidget);
        expect(find.text('10GiB'), findsOneWidget);
        expect(find.text('of 90GiB'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.folder), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.cube), findsOneWidget);

        final nestedTile = tester.getRect(find.text('nested'));
        final topTile = tester.getRect(find.text('data').first);
        expect(
          nestedTile.left,
          greaterThan(topTile.left),
          reason: 'A deeper dataset path should render more indented.',
        );
      },
    );

    testWidgets('falls back to 0B and defaults for missing usage fields', (
      WidgetTester tester,
    ) async {
      fakeClient.datasets = [
        {'name': 'tank/data', 'pool': 'tank'},
      ];
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('data'));

      expect(find.text('0B'), findsOneWidget);
      expect(find.text('of 0B'), findsOneWidget);
      // No mountpoint supplied -> its Text is omitted entirely.
      expect(find.textContaining('/mnt'), findsNothing);
    });

    testWidgets('tapping a dataset tile navigates to DatasetDetailScreen', (
      WidgetTester tester,
    ) async {
      fakeClient.datasets = [
        {'name': 'tank/data', 'pool': 'tank', 'mountpoint': '/mnt/tank/data'},
      ];
      await tester.pumpWidget(wrap({'name': 'tank'}));
      await pumpUntilFound(tester, find.text('data'));

      await tester.tap(find.text('data'));
      await settleRouteTransition(tester);

      expect(find.byType(DatasetDetailScreen), findsOneWidget);
      // DatasetDetailScreen's own nav title is the last path segment too.
      expect(find.text('data'), findsOneWidget);
    });
  });

  group('PoolDetailScreen - layout', () {
    testWidgets('renders a populated pool at iPhone width without overflow', (
      WidgetTester tester,
    ) async {
      useCompactSurface(tester);
      fakeClient.datasets = [
        {
          'name': 'tank/a-fairly-long-dataset-name-for-overflow-testing',
          'pool': 'tank',
          'type': 'FILESYSTEM',
          'mountpoint':
              '/mnt/tank/a-fairly-long-dataset-name-for-overflow-testing',
          'used': {'value': '512GiB'},
          'available': {'value': '1.5TiB'},
        },
        {
          'name':
              'tank/a-fairly-long-dataset-name-for-overflow-testing/nested-child',
          'pool': 'tank',
          'type': 'VOLUME',
          'used': {'value': '12GiB'},
          'available': {'value': '88GiB'},
        },
      ];

      await tester.pumpWidget(
        wrap({
          'name': 'a-very-long-storage-pool-name-that-stresses-the-layout',
          'status': 'ONLINE',
          'healthy': true,
          'topology': {
            'data': [
              {
                'type': 'raidz2',
                'children': [
                  {'name': 'd0'},
                  {'name': 'd1'},
                  {'name': 'd2'},
                  {'name': 'd3'},
                ],
              },
            ],
          },
        }),
      );
      await pumpUntilFound(tester, find.text('nested-child'));
      expectNoLayoutOverflow(tester);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pump();
      expectNoLayoutOverflow(tester);
    });
  });
}
