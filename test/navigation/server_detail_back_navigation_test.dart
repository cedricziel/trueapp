import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/navigation/shell_navigation_leading.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Regression coverage for ticket #85(b): `HomeScreen` used to reach server
/// detail with `context.go`, which replaces the whole route stack rather
/// than pushing onto it, so there was nothing to pop back to. #55 had
/// already removed the leading back button from `ServerDetailScreen`, so a
/// phone-width user - who has no sidebar to fall back on - was stranded
/// with only the hamburger-style destination switcher to get back to the
/// server list, not a real "go back" affordance.
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
      name: 'Back Nav Server',
      host: '192.168.1.60',
      port: 443,
      username: 'admin',
      password: 'password',
    );
    await serverProvider.addServer(testServer, 'password');

    // Drain ServerProvider's background auto-select/authenticate reaction to
    // adding the sole registered server before any test runs - otherwise it
    // can still be resolving when a fast test's tearDown disposes the
    // provider and closes the stream it tries to emit on.
    var attempts = 0;
    while ((serverProvider.selectedServer == null ||
            serverProvider.isAuthenticating) &&
        attempts < 100) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      attempts++;
    }
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

  testWidgets('tapping a server from the list leaves a poppable detail page', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Back Nav Server').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('Back Nav Server').first);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    expect(find.byType(ShellBackButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the back button returns to the server list', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Back Nav Server').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('Back Nav Server').first);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    await tapWhenUnambiguous(tester, find.byType(ShellBackButton));
    await settleRouteTransition(tester);

    expect(find.text('Back Nav Server'), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a cold start directly on /server/:id shows no back button', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        child: CupertinoApp.router(
          routerConfig: createAppRouter(
            initialLocation: '/server/${testServer.id}',
          ),
        ),
      ),
    );
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    expect(find.byType(ShellBackButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entering pools from detail keeps the server list beneath', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Back Nav Server').evaluate().isNotEmpty,
    );

    await tester.tap(find.text('Back Nav Server').first);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    // The "Pools" action button sits below the fold of the detail screen's
    // ListView at this surface height - scroll it into view before tapping,
    // otherwise the tap lands on whatever is at that now-stale offset
    // instead (see `server_detail_screen_test.dart`'s tests for the same
    // pattern).
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();

    await tapWhenUnambiguous(tester, find.text('Pools'));
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.textContaining('Pools').evaluate().isNotEmpty,
    );

    // Pop out of the pools screen with its own back button.
    final poolsBack = find.byType(CupertinoButton).first;
    await tester.tap(poolsBack);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    // Still on detail, and detail is still poppable back to the list.
    expect(find.byType(ShellBackButton), findsOneWidget);

    await tapWhenUnambiguous(tester, find.byType(ShellBackButton));
    await settleRouteTransition(tester);

    expect(find.text('Back Nav Server'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'single-server auto-navigation does not clobber the pushed detail page',
    (WidgetTester tester) async {
      useCompactSurface(tester);

      await tester.pumpWidget(createTestApp());
      await pumpUntilAsync(
        tester,
        () => find.text('Back Nav Server').evaluate().isNotEmpty,
      );

      await tester.tap(find.text('Back Nav Server').first);
      await settleRouteTransition(tester);
      await pumpUntilAsync(
        tester,
        () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
      );

      expect(find.byType(ShellBackButton), findsOneWidget);

      // Simulate the auth stream re-emitting for the single registered
      // server while HomeScreen sits underneath the pushed detail page -
      // exactly what happens on a reconnect.
      await runRealAsync(tester, () => serverProvider.selectServer(testServer));
      await tester.pump();
      await settleRouteTransition(tester);

      expect(find.byType(ShellBackButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('two overlapping taps push only one detail route', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);

    await tester.pumpWidget(createTestApp());
    await pumpUntilAsync(
      tester,
      () => find.text('Back Nav Server').evaluate().isNotEmpty,
    );

    // Two taps before the first can settle. `onTap` awaits its own
    // `selectServer` - a real database round-trip - so the tile is still
    // on screen and hittable when the second tap lands. Without an
    // in-flight guard both continuations reach `context.push` and stack
    // two identical detail routes on top of the list.
    await tester.tap(find.text('Back Nav Server').first);
    await tester.tap(find.text('Back Nav Server').first);
    await settleRouteTransition(tester);
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    // A single back press must land on the server list. With two routes
    // stacked it only uncovers the second detail page, leaving the user
    // to press back twice for one tap.
    await tapWhenUnambiguous(tester, find.byType(ShellBackButton));
    await settleRouteTransition(tester);

    expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    expect(find.byType(ShellBackButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
