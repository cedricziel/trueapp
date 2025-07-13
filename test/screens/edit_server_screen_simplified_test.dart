import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/edit_server_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);

    testServer = NasServer.create(
      name: 'Test Server',
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
    await database.close();
  });

  group('EditServerScreen Core Functionality', () {
    testWidgets('should display edit server screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that the edit screen is displayed
      expect(find.text('Edit Server'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('should save server changes and return true', (
      WidgetTester tester,
    ) async {
      bool? navigationResult;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(middle: Text('Test')),
            child: Center(
              child: CupertinoButton(
                child: const Text('Edit'),
                onPressed: () async {
                  navigationResult =
                      await Navigator.of(
                        tester.element(find.text('Edit')),
                      ).push<bool>(
                        CupertinoPageRoute(
                          builder: (context) => MultiProvider(
                            providers: [
                              Provider<AppDatabase>.value(value: database),
                              ChangeNotifierProvider.value(
                                value: serverProvider,
                              ),
                            ],
                            child: EditServerScreen(server: testServer),
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to edit screen
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Save without making changes (should still return true)
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(navigationResult, isTrue);
    });

    testWidgets('should cancel edit and return null', (
      WidgetTester tester,
    ) async {
      bool? navigationResult;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            navigationBar: const CupertinoNavigationBar(middle: Text('Test')),
            child: Center(
              child: CupertinoButton(
                child: const Text('Edit'),
                onPressed: () async {
                  navigationResult =
                      await Navigator.of(
                        tester.element(find.text('Edit')),
                      ).push<bool>(
                        CupertinoPageRoute(
                          builder: (context) => MultiProvider(
                            providers: [
                              Provider<AppDatabase>.value(value: database),
                              ChangeNotifierProvider.value(
                                value: serverProvider,
                              ),
                            ],
                            child: EditServerScreen(server: testServer),
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to edit screen
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // Cancel the edit
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(navigationResult, isNull);
    });

    testWidgets('should update server in database when saved', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and update the server name field
      final nameFields = find.byType(CupertinoTextField);
      expect(nameFields, findsWidgets);

      // Assuming the first text field is the name field based on the UI structure
      await tester.enterText(nameFields.first, 'Updated Server Name');
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the server was updated in the database
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.name, 'Updated Server Name');
    });
  });

  group('Server Provider Integration', () {
    testWidgets('should refresh selected server after edit', (
      WidgetTester tester,
    ) async {
      // Set the test server as selected
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Test Server');

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Update server name
      final nameFields = find.byType(CupertinoTextField);
      await tester.enterText(nameFields.first, 'Provider Updated Server');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the selected server was refreshed in the provider
      expect(serverProvider.selectedServer?.name, 'Provider Updated Server');
    });
  });

  group('Database Operations', () {
    test('should update server with all new fields', () async {
      final updatedServer = testServer.copyWith(
        name: 'Database Test Server',
        host: 'new.example.com',
        localUrl: 'https://local.example.com:8443',
        trustedWifiSsids: ['WiFi1', 'WiFi2'],
        port: 8443,
        username: 'newuser',
        password: 'newpassword',
        useHttps: true,
        allowUntrustedCertificates: true,
      );

      await serverProvider.updateServer(updatedServer);

      // Verify all fields were updated in database
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.name, 'Database Test Server');
      expect(serverFromDb.host, 'new.example.com');
      expect(serverFromDb.localUrl, 'https://local.example.com:8443');
      expect(serverFromDb.trustedWifiSsids, ['WiFi1', 'WiFi2']);
      expect(serverFromDb.port, 8443);
      expect(serverFromDb.username, 'newuser');
      expect(serverFromDb.password, 'newpassword');
      expect(serverFromDb.useHttps, isTrue);
      expect(serverFromDb.allowUntrustedCertificates, isTrue);
    });

    test('should refresh selected server after database update', () async {
      // Select the test server
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Test Server');

      // Update server through provider
      final updatedServer = testServer.copyWith(
        name: 'Refresh Test Server',
        allowUntrustedCertificates: true,
      );

      await serverProvider.updateServer(updatedServer);

      // Verify selected server is automatically refreshed
      expect(serverProvider.selectedServer?.name, 'Refresh Test Server');
      expect(serverProvider.selectedServer?.allowUntrustedCertificates, isTrue);
    });
  });
}
