import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/navigation/compact_navigation.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Regression coverage for ticket #87: every widget test previously ran at
/// `flutter_test`'s default 800x600 surface, which sits above
/// `AdaptiveNavigationScaffold`'s 768pt breakpoint - so the compact (phone)
/// branch, the one the vast majority of users actually see, was never
/// rendered by the suite.
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

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      child: CupertinoApp.router(routerConfig: createAppRouter()),
    );
  }

  testWidgets('uses the compact layout on an iPhone-class surface', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Servers').evaluate().isNotEmpty,
    );

    expect(find.byType(CompactNavigation), findsOneWidget);
    expect(find.byType(CupertinoSidebar), findsNothing);
  });

  testWidgets('keeps the sidebar on macOS even at phone width', (
    WidgetTester tester,
  ) async {
    // Reset synchronously before the test body returns: flutter_test checks
    // that no `debug*` foundation variable is left set as soon as the test
    // callback's future completes, which happens before any `addTearDown`
    // callback registered here would run.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      useCompactSurface(tester);

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => find.text('Servers').evaluate().isNotEmpty,
      );

      expect(find.byType(CupertinoSidebar), findsOneWidget);
      expect(find.byType(CompactNavigation), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('the compact layout shows exactly one navigation bar', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Servers').evaluate().isNotEmpty,
    );
    await pumpUntilExactlyOne(tester, find.byType(CupertinoNavigationBar));

    expect(find.byType(CupertinoNavigationBar), findsOneWidget);
  });

  testWidgets('tapping a compact destination bar item navigates there', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Servers').evaluate().isNotEmpty,
    );
    await pumpUntilExactlyOne(tester, find.byType(CupertinoTabBar));

    expect(find.byType(CupertinoTabBar), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await settleRouteTransition(tester);

    expect(find.text('DATABASE'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
