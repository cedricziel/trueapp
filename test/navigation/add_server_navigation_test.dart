import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

/// Regression coverage for routes whose screens close themselves with
/// `Navigator.pop`.
///
/// `context.go` replaces the whole route stack, so a screen reached that way
/// has nothing left to pop back to. For `/add-server`, which sits outside the
/// shell route, that turned Cancel into a hard crash:
///
///   You have popped the last page off of the stack, there are no pages left
///   to show
///
/// Such a route has to be entered with `context.push`.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late PoolProvider poolProvider;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
    poolProvider = PoolProvider(unifiedServerService);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider, poolProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<UnifiedServerService>.value(value: unifiedServerService),
        ChangeNotifierProvider.value(value: serverProvider),
        ChangeNotifierProvider.value(value: poolProvider),
        ChangeNotifierProvider(
          create: (_) => AppProvider(
            database: database,
            serverService: unifiedServerService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SystemStatsProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (_) => JobsProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (_) => FileProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (_) => HealthProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(
          create: (_) => FleetStatusProvider(unifiedServerService),
        ),
        ChangeNotifierProvider(create: (_) => ConnectionStatusProvider()),
      ],
      child: CupertinoApp.router(routerConfig: createAppRouter()),
    );
  }

  testWidgets('cancelling Add Server returns to the server list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Servers').evaluate().isNotEmpty,
    );

    await tapWhenUnambiguous(tester, find.byIcon(CupertinoIcons.add));
    await settleRouteTransition(tester);

    expect(
      find.text('Cancel'),
      findsOneWidget,
      reason: 'Expected to be on the Add Server screen',
    );

    await tapWhenUnambiguous(tester, find.text('Cancel'));
    await settleRouteTransition(tester);

    expect(
      tester.takeException(),
      isNull,
      reason: 'Cancelling must not pop the last page off the router stack',
    );
    expect(find.text('Servers'), findsWidgets);
    expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
  });
}
