import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/pool_card_widget.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  final testServer = NasServer.create(
    name: 'Test Server',
    host: '192.168.1.100',
    username: 'admin',
    password: 'password',
  );

  Widget wrap(
    Map<String, dynamic> pool, {
    double width = 375,
    DatasetProvider? datasetProvider,
  }) {
    final card = PoolCardWidget(pool: pool, server: testServer);
    final home = Center(
      child: SizedBox(
        width: width,
        child: SingleChildScrollView(child: card),
      ),
    );

    if (datasetProvider == null) {
      return CupertinoApp(home: home);
    }
    return ChangeNotifierProvider<DatasetProvider>.value(
      value: datasetProvider,
      child: CupertinoApp(home: home),
    );
  }

  group('PoolCardWidget - content', () {
    testWidgets('renders the pool name, status and healthy styling', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({'name': 'tank', 'status': 'ONLINE', 'healthy': true}),
      );

      expect(find.text('tank'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
      );
      expect(icon.color, CupertinoColors.systemGreen);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('renders unhealthy styling in red', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({'name': 'tank', 'status': 'DEGRADED', 'healthy': false}),
      );

      expect(find.text('DEGRADED'), findsOneWidget);
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
      );
      expect(icon.color, CupertinoColors.systemRed);
      final statusText = tester.widget<Text>(find.text('DEGRADED'));
      expect(statusText.style?.color, CupertinoColors.systemRed);
    });

    testWidgets('falls back to Unknown for missing name/status/healthy', (
      WidgetTester tester,
    ) async {
      // allocated/free are supplied so the storage-metric row doesn't add
      // its own "Unknown" text and muddy this test's count.
      await tester.pumpWidget(wrap({'allocated': 0, 'free': 1024}));

      expect(find.text('Unknown'), findsNWidgets(2)); // name + status
      final icon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
      );
      expect(icon.color, CupertinoColors.systemRed); // healthy defaults false
    });
  });

  group('PoolCardWidget - pool type description', () {
    testWidgets('shows Unknown configuration when topology is missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap({'name': 'tank'}));
      expect(find.text('Unknown configuration'), findsOneWidget);
    });

    testWidgets('shows Unknown configuration when topology data is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'topology': {'data': <dynamic>[]},
        }),
      );
      expect(find.text('Unknown configuration'), findsOneWidget);
    });

    testWidgets('shows Mirror with the drive count', (
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
      expect(find.text('Mirror (2 drives)'), findsOneWidget);
    });

    testWidgets('shows RAID-Z1/Z2/Z3 with the drive count', (
      WidgetTester tester,
    ) async {
      for (final entry in {
        'raidz1': 'RAID-Z1 (3 drives)',
        'raidz2': 'RAID-Z2 (4 drives)',
        'raidz3': 'RAID-Z3 (5 drives)',
      }.entries) {
        final driveCount = int.parse(
          RegExp(r'\((\d+)').firstMatch(entry.value)!.group(1)!,
        );
        await tester.pumpWidget(
          wrap({
            'name': 'tank',
            'topology': {
              'data': [
                {
                  'type': entry.key,
                  'children': List.generate(driveCount, (i) => {'name': 'd$i'}),
                },
              ],
            },
          }),
        );
        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('shows Single drive for a lone unmatched vdev child', (
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
      expect(find.text('Single drive'), findsOneWidget);
    });

    testWidgets(
      'shows Custom configuration for an unmatched multi-child vdev',
      (WidgetTester tester) async {
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
        expect(find.text('Custom configuration'), findsOneWidget);
      },
    );
  });

  group('PoolCardWidget - storage metrics', () {
    testWidgets('formats used/available/total from allocated and free', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'allocated': 1024 * 1024 * 1024, // 1GB
          'free': 1024 * 1024 * 1024, // 1GB
        }),
      );

      expect(find.text('1.0GB'), findsNWidgets(2)); // used + available
      expect(find.text('2.0GB'), findsOneWidget); // total = allocated + free
    });

    testWidgets('falls back to size for total when allocated/free missing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'status': 'ONLINE',
          'size': 1024 * 1024 * 1024 * 1024, // 1TB
        }),
      );

      expect(find.text('Unknown'), findsNWidgets(2)); // used + available
      expect(find.text('1.0TB'), findsOneWidget);
    });

    testWidgets('shows Unknown for all metrics when no size data is present', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap({'name': 'tank', 'status': 'ONLINE'}));

      expect(find.text('Unknown'), findsNWidgets(3));
    });

    testWidgets('formats bytes and kilobytes below the megabyte threshold', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({'name': 'tank', 'allocated': 512, 'free': 2048}),
      );

      expect(find.text('512B'), findsOneWidget);
      expect(find.text('2.0KB'), findsOneWidget);
    });
  });

  group('PoolCardWidget - navigation', () {
    late AppDatabase database;
    late UnifiedServerService unifiedServerService;
    late DatasetProvider datasetProvider;

    setUp(() async {
      await TestProviders.cleanupTestEnvironment();
      TestProviders.setupTestEnvironment();
      database = createTestDatabase();
      unifiedServerService = await TestProviders.createMockUnifiedServerService(
        database: database,
      );
      datasetProvider = DatasetProvider(unifiedServerService);
    });

    tearDown(() async {
      await TestProviders.disposeTestStack(
        providers: [datasetProvider],
        service: unifiedServerService,
        database: database,
      );
    });

    testWidgets('tapping the card navigates to the pool detail screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap({
          'name': 'tank',
          'status': 'ONLINE',
          'healthy': true,
        }, datasetProvider: datasetProvider),
      );

      await tester.tap(find.byType(PoolCardWidget));
      await settleRouteTransition(tester);

      expect(find.text('Datasets'), findsOneWidget);
    });
  });
}
