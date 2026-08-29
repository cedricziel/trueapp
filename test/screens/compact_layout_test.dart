import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/screens/server_detail_screen.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Smoke tests for ticket #87: the app's main shell screens - the ones
/// `AdaptiveNavigationScaffold` routes to - rendered at an iPhone-class
/// surface. Each asserts real content is showing (not a silent fallback to
/// a spinner or lock screen) and that nothing overflows.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  testWidgets('HomeScreen renders on a compact surface without exceptions', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider.value(value: serverProvider)],
        child: const CupertinoApp(home: HomeScreen()),
      ),
    );
    await pumpUntilAsync(
      tester,
      () => find.text('Servers').evaluate().isNotEmpty,
    );

    expect(find.text('Servers'), findsWidgets);
    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });

  testWidgets(
    'SettingsScreen renders on a compact surface without exceptions',
    (WidgetTester tester) async {
      useCompactSurface(tester);
      final trayProvider = TrayProvider();
      addTearDown(trayProvider.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: serverProvider),
            ChangeNotifierProvider.value(value: trayProvider),
          ],
          child: const CupertinoApp(home: SettingsScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Settings'), findsOneWidget);
      expectNoLayoutOverflow(tester);
    },
  );

  testWidgets(
    'SettingsScreen renders the MENU BAR tray section on macOS without '
    'overflowing a compact surface',
    (WidgetTester tester) async {
      // Reset synchronously before the test body returns: flutter_test
      // checks that no `debug*` foundation variable is left set as soon as
      // the test callback's future completes, which happens before any
      // `addTearDown` callback registered here would run (matches the
      // pattern in adaptive_navigation_scaffold_test.dart).
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        useCompactSurface(tester);
        final trayProvider = TrayProvider();
        addTearDown(trayProvider.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider.value(value: trayProvider),
            ],
            child: const CupertinoApp(home: SettingsScreen()),
          ),
        );
        await tester.pump();

        // Non-vacuity guard: proves the tray section actually rendered,
        // rather than the assertion below passing merely because the
        // section (and the Flexible fix inside it) was never built.
        expect(find.text('MENU BAR'), findsOneWidget);
        expectNoLayoutOverflow(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

  testWidgets('SettingsScreen renders on the default (regular) surface without '
      'exceptions', (WidgetTester tester) async {
    // No useCompactSurface() call - this stays at flutter_test's default
    // 800x600 surface, confirming the compact-width fix does not regress
    // the layout above the breakpoint.
    final trayProvider = TrayProvider();
    addTearDown(trayProvider.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: serverProvider),
          ChangeNotifierProvider.value(value: trayProvider),
        ],
        child: const CupertinoApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });

  testWidgets('ServerDetailScreen renders on a compact surface with a single '
      'navigation bar', (WidgetTester tester) async {
    useCompactSurface(tester);

    final testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );

    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        child: CupertinoApp(home: ServerDetailScreen(server: testServer)),
      ),
    );
    await pumpUntilFound(tester, find.text('Storage Pools'));

    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });
}
