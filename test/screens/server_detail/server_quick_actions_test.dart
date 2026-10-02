import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_detail/server_quick_actions.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../../helpers/provider_scope.dart';
import '../../helpers/test_providers.dart';

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
    serverProvider = await TestProviders.createSettledServerProvider(
      unifiedServerService,
    );
    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  testWidgets('the Services tile opens the server services route', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => CupertinoPageScaffold(
            child: ServerQuickActions(server: testServer),
          ),
        ),
        GoRoute(
          path: '/server/:serverId/services',
          builder: (_, _) => const Text('services route'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        child: CupertinoApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.text('Services'));
    await tester.pumpAndSettle();

    expect(find.text('services route'), findsOneWidget);
  });
}
