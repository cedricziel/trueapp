import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';

/// Regression coverage for ticket #84: every `/server/:serverId` page
/// builder used to do `state.extra as NasServer`. `extra` is only populated
/// when navigation originated inside the app, so a cold start on that
/// location - exactly what `createAppRouter(initialLocation: ...)` does, and
/// what a deep link or a restored location would also do - threw a
/// `_TypeError` before the screen ever built.
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
      name: 'Deep Link Server',
      host: '192.168.1.50',
      port: 443,
      username: 'admin',
      password: 'password',
    );
    await serverProvider.addServer(testServer, 'password');

    // ServerProvider auto-selects and authenticates the sole registered
    // server as soon as its stream listener observes it - a background
    // process `addServer` does not await. Draining it here, in real time,
    // stops it from finishing mid-test (or after a fast test's tearDown has
    // already disposed the provider and closed the stream it tries to emit
    // on).
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

  Widget createTestApp(String initialLocation) {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      child: CupertinoApp.router(
        routerConfig: createAppRouter(initialLocation: initialLocation),
      ),
    );
  }

  testWidgets('cold start on /server/:id renders the detail screen without '
      'extra', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp('/server/${testServer.id}'));
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    expect(find.byIcon(CupertinoIcons.ellipsis), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cold start shows a loading indicator until the server resolves',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp('/server/${testServer.id}'));
      // Deliberately no further pump: the very first frame, before the
      // async lookup has had any chance to complete, is what must show a
      // loading state rather than nothing (or a crash).

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cold start on an unknown server id redirects to /servers', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp('/server/does-not-exist'));
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.add).evaluate().isNotEmpty,
    );

    expect(find.text('Deep Link Server'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deep link to a nested route /server/:id/pools renders '
      'without extra', (WidgetTester tester) async {
    await tester.pumpWidget(createTestApp('/server/${testServer.id}/pools'));
    await pumpUntilAsync(
      tester,
      () => find.textContaining('Pools').evaluate().isNotEmpty,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('a deleted server closes its detail route back to the list', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestApp('/server/${testServer.id}'));
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
    );

    await runRealAsync(
      tester,
      () => serverProvider.deleteServer(testServer.id),
    );
    await pumpUntilAsync(
      tester,
      () => find.byIcon(CupertinoIcons.add).evaluate().isNotEmpty,
    );

    expect(find.byIcon(CupertinoIcons.ellipsis), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'in-app navigation from the server list reaches the detail screen',
    (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp('/servers'));
      await pumpUntilAsync(
        tester,
        () => find.text('Deep Link Server').evaluate().isNotEmpty,
      );

      await tester.tap(find.text('Deep Link Server').first);
      await settleRouteTransition(tester);
      await pumpUntilAsync(
        tester,
        () => find.byIcon(CupertinoIcons.ellipsis).evaluate().isNotEmpty,
      );

      expect(find.byIcon(CupertinoIcons.ellipsis), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
