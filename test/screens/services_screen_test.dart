import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/services_provider.dart';
import 'package:truehub/screens/services_screen.dart';
import 'package:truehub/services/active_server.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/widgets/service_tile.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/provider_scope.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

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
      port: 443,
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

  Future<void> pumpScreen(WidgetTester tester, FakeApiClient fakeClient) async {
    await unifiedServerService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
    final provider = ServicesProvider(
      unifiedServerService,
      clientManager: TestProviders.mockApiClientManager,
      activeServer: ActiveServer(testServer).listenable,
    );
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      provideAppProviders(
        database: database,
        service: unifiedServerService,
        serverProvider: serverProvider,
        servicesProvider: provider,
        child: CupertinoApp(home: ServicesScreen(server: testServer)),
      ),
    );
    await pumpUntilAsync(
      tester,
      () =>
          find.byType(ServiceTile).evaluate().isNotEmpty ||
          find.text('No services found').evaluate().isNotEmpty,
    );
  }

  FakeApiClient clientWithServices() => FakeApiClient()
    ..services = [
      {'service': 'ssh', 'state': 'STOPPED', 'enable': false},
      {'service': 'cifs', 'state': 'RUNNING', 'enable': true},
    ];

  testWidgets('shows an empty state when the server reports no services', (
    tester,
  ) async {
    await pumpScreen(tester, FakeApiClient());

    expect(find.text('No services found'), findsOneWidget);
    expect(find.text('Test Server - Services'), findsOneWidget);
  });

  testWidgets('lists each service with its running state', (tester) async {
    await pumpScreen(tester, clientWithServices());

    expect(find.text('SMB'), findsOneWidget);
    expect(find.text('SSH'), findsOneWidget);
    expect(find.text('Running'), findsOneWidget);
    expect(find.text('Stopped'), findsOneWidget);
  });

  testWidgets('offers only start for a stopped service', (tester) async {
    await pumpScreen(tester, clientWithServices());

    await tester.tap(find.text('SSH'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoActionSheet), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
    expect(find.text('Restart'), findsNothing);
  });

  testWidgets('starting a service calls the client without more prompts', (
    tester,
  ) async {
    final fakeClient = clientWithServices();
    await pumpScreen(tester, fakeClient);

    await tester.tap(find.text('SSH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start'));
    await pumpUntilAsync(
      tester,
      () => fakeClient.serviceControlCalls.isNotEmpty,
    );

    expect(fakeClient.serviceControlCalls, [('start', 'ssh')]);
  });

  testWidgets('stopping a running service is marked destructive', (
    tester,
  ) async {
    final fakeClient = clientWithServices();
    await pumpScreen(tester, fakeClient);

    await tester.tap(find.text('SMB'));
    await tester.pumpAndSettle();

    final stop = tester.widget<CupertinoActionSheetAction>(
      find.widgetWithText(CupertinoActionSheetAction, 'Stop'),
    );
    expect(stop.isDestructiveAction, isTrue);
    expect(find.text('Restart'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await pumpUntilAsync(
      tester,
      () => fakeClient.serviceControlCalls.isNotEmpty,
    );

    expect(fakeClient.serviceControlCalls, [('stop', 'cifs')]);
  });

  testWidgets('cancelling the sheet changes nothing', (tester) async {
    final fakeClient = clientWithServices();
    await pumpScreen(tester, fakeClient);

    await tester.tap(find.text('SMB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fakeClient.serviceControlCalls, isEmpty);
    expect(find.byType(CupertinoActionSheet), findsNothing);
  });

  testWidgets('shows a dismissible banner when an action fails', (
    tester,
  ) async {
    final fakeClient = clientWithServices()..failingMethods.add('stopService');
    await pumpScreen(tester, fakeClient);

    await tester.tap(find.text('SMB'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Stop'));
    await pumpUntilAsync(
      tester,
      () =>
          find.byKey(const Key('services-action-error')).evaluate().isNotEmpty,
    );

    expect(find.byKey(const Key('services-action-error')), findsOneWidget);

    await tester.tap(find.byKey(const Key('services-action-error-dismiss')));
    await tester.pump();

    expect(find.byKey(const Key('services-action-error')), findsNothing);
  });
}
