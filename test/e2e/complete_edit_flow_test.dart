import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/jobs_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/form_finders.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

/// End-to-end coverage for editing a server through the real screen stack:
/// Home → Server Detail → Edit → Save.
///
/// The app navigates with go_router, so these tests drive `CupertinoApp.router`
/// with a router built per test. Pumping a bare `CupertinoApp(home: HomeScreen())`
/// would leave every `context.go` call without a router and the taps would do
/// nothing.
///
/// Two further constraints shape every test in this file:
///
/// * `ServerDetailScreen` renders an indefinite activity indicator while it
///   authenticates, so `pumpAndSettle` would never return. All waiting goes
///   through the bounded helpers in `pump_helpers.dart`.
/// * Everything the edit flow persists goes through drift, which only makes
///   progress outside the `FakeAsync` zone of `testWidgets`. Waiting for such
///   an effect therefore uses [pumpUntilAsync], and direct database reads use
///   [runRealAsync].
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late PoolProvider poolProvider;
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
    poolProvider = PoolProvider(unifiedServerService);

    testServer = NasServer.create(
      name: 'Test TrueNAS Server',
      host: '192.168.1.100',
      localUrl: 'http://192.168.1.200:8080',
      trustedWifiSsids: ['HomeWiFi'],
      port: 443,
      username: 'admin',
      password: 'password',
      useHttps: true,
      allowUntrustedCertificates: false,
    );

    await serverProvider.addServer(testServer, 'password');
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider, poolProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  /// The full provider stack the home and detail screens depend on, wired to a
  /// freshly built router.
  Widget createTestApp(GoRouter router) {
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
        ChangeNotifierProvider(create: (_) => ConnectionStatusProvider()),
      ],
      child: CupertinoApp.router(routerConfig: router),
    );
  }

  /// Launches the app and waits until the registered server is listed.
  ///
  /// Runs at the default test surface, which is wide enough for the adaptive
  /// scaffold to show its sidebar layout.
  Future<void> pumpHomeScreen(WidgetTester tester) async {
    await tester.pumpWidget(createTestApp(createAppRouter()));
    await pumpUntilAsync(
      tester,
      () => find.text('Test TrueNAS Server').evaluate().isNotEmpty,
    );
  }

  /// Taps the server in the list and waits for the detail screen.
  ///
  /// The detail screen is identified by the ellipsis button in its navigation
  /// bar; the body itself may still be showing the authentication placeholder.
  Future<void> openServerDetail(WidgetTester tester) async {
    await tester.tap(find.text('Test TrueNAS Server').first);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );
  }

  /// Opens the detail screen's action sheet and navigates to the edit screen.
  Future<void> openEditScreen(WidgetTester tester) async {
    await tapWhenUnambiguous(tester, find.byIcon(CupertinoIcons.ellipsis));
    await settleRouteTransition(tester);

    expect(find.byType(CupertinoActionSheet), findsOneWidget);

    await tapWhenUnambiguous(tester, find.text('Edit Server'));
    await settleRouteTransition(tester);

    // The edit screen carries 'Edit Server' as its navigation bar title.
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  }

  group('Complete Edit Flow End-to-End Test', () {
    testWidgets('should complete full user journey: Home → Server Detail → '
        'Edit → Save → Provider Update', (WidgetTester tester) async {
      // STEP 1: Home screen lists the registered server.
      await pumpHomeScreen(tester);

      expect(find.text('Servers'), findsWidgets);
      expect(find.text('Test TrueNAS Server'), findsOneWidget);
      expect(find.text('https://192.168.1.100:443'), findsOneWidget);
      expect(serverProvider.selectedServer, isNull);

      // STEP 2: Opening the server selects it in the provider.
      await openServerDetail(tester);
      await pumpUntilAsync(tester, () => serverProvider.selectedServer != null);

      expect(serverProvider.selectedServer, isNotNull);
      expect(serverProvider.selectedServer!.name, 'Test TrueNAS Server');
      expect(serverProvider.selectedServer!.host, '192.168.1.100');
      expect(serverProvider.selectedServer!.port, 443);
      expect(serverProvider.selectedServer!.useHttps, isTrue);
      expect(
        serverProvider.selectedServer!.allowUntrustedCertificates,
        isFalse,
      );

      // STEP 3: Navigate into the edit screen.
      await openEditScreen(tester);

      // STEP 4: Change the server name.
      await tester.enterText(
        formFieldWithLabel('Name'),
        'Updated TrueNAS Server',
      );
      await tester.pump();

      // STEP 5: Save and wait for the write to reach the provider.
      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.selectedServer?.name == 'Updated TrueNAS Server',
      );

      // STEP 6: The change bubbled up to the provider, host is untouched.
      expect(serverProvider.selectedServer?.name, 'Updated TrueNAS Server');
      expect(serverProvider.selectedServer?.host, '192.168.1.100');

      // STEP 7: ... and was persisted.
      final serverFromDb = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.name, 'Updated TrueNAS Server');
      expect(serverFromDb.host, '192.168.1.100');

      // STEP 8: ... and the server list reflects it too.
      final updatedServerInList = serverProvider.servers.firstWhere(
        (s) => s.id == testServer.id,
      );
      expect(updatedServerInList.name, 'Updated TrueNAS Server');
      expect(updatedServerInList.host, '192.168.1.100');
    });

    testWidgets('should handle edit cancellation without affecting provider '
        'state', (WidgetTester tester) async {
      await pumpHomeScreen(tester);
      await openServerDetail(tester);
      await pumpUntilAsync(tester, () => serverProvider.selectedServer != null);

      final originalServer = serverProvider.selectedServer!;
      expect(originalServer.name, 'Test TrueNAS Server');
      expect(originalServer.host, '192.168.1.100');
      expect(originalServer.allowUntrustedCertificates, isFalse);

      await openEditScreen(tester);

      // Type a change, then discard it.
      await tester.enterText(formFieldWithLabel('Name'), 'Changed Server Name');
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Cancel'));
      await settleRouteTransition(tester);

      // Back on the detail screen, nothing changed.
      expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
      expect(serverProvider.selectedServer?.name, 'Test TrueNAS Server');
      expect(serverProvider.selectedServer?.host, '192.168.1.100');
      expect(
        serverProvider.selectedServer?.allowUntrustedCertificates,
        isFalse,
      );

      final serverFromDb = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.name, 'Test TrueNAS Server');
      expect(serverFromDb.host, '192.168.1.100');
      expect(serverFromDb.allowUntrustedCertificates, isFalse);
    });

    testWidgets('should handle multiple consecutive edits correctly', (
      WidgetTester tester,
    ) async {
      await pumpHomeScreen(tester);
      await openServerDetail(tester);
      await pumpUntilAsync(tester, () => serverProvider.selectedServer != null);

      // First edit: change the name.
      await openEditScreen(tester);
      await tester.enterText(formFieldWithLabel('Name'), 'First Edit');
      await tester.pump();
      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.selectedServer?.name == 'First Edit',
      );

      expect(serverProvider.selectedServer?.name, 'First Edit');

      // Second edit: change the host, on top of the first change.
      await openEditScreen(tester);
      await tester.enterText(formFieldWithLabel('Host'), '10.0.0.5');
      await tester.pump();
      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.selectedServer?.host == '10.0.0.5',
      );

      // Both edits survived.
      expect(serverProvider.selectedServer?.name, 'First Edit');
      expect(serverProvider.selectedServer?.host, '10.0.0.5');

      final finalServer = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(finalServer, isNotNull);
      expect(finalServer!.name, 'First Edit');
      expect(finalServer.host, '10.0.0.5');
    });
  });
}
