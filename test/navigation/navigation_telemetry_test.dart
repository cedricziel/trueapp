import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/navigation/app_router.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late FakeTelemetryService telemetry;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = await TestProviders.createSettledServerProvider(
      unifiedServerService,
    );
    telemetry = FakeTelemetryService();
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  testWidgets('records route-name templates, never path parameters', (
    tester,
  ) async {
    final router = createAppRouter(telemetry: telemetry);
    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        child: CupertinoApp.router(routerConfig: router),
      ),
    );
    await settleRouteTransition(tester);

    router.go('/server/secret-server-id/apps');
    await settleRouteTransition(tester);
    router.push('/add-server');
    await settleRouteTransition(tester);

    final events = [
      for (final r in telemetry.logRecords)
        if (r.body == 'app.navigation') {...r.attributes},
    ];
    final screens = events.map((e) => e['screen.name']).toSet();
    expect(screens, containsAll(['server-apps', 'add-server']));
    expect(events.toString(), isNot(contains('secret-server-id')));
    expect(
      events.map((e) => e.toString()).toSet().length,
      events.length,
      reason: 'duplicate events',
    );
  });
}
