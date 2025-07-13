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
import '../helpers/mock_network_service.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late NasServer testServer;
  late MockNetworkService mockNetworkService;

  setUp(() async {
    // Clean up any leftover state from previous tests
    await TestProviders.cleanupTestEnvironment();

    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
    mockNetworkService = MockNetworkService();

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
    try {
      // Clean up any static state first
      await TestProviders.cleanupTestEnvironment();

      // Dispose providers
      serverProvider.dispose();
      unifiedServerService.dispose();

      // Close database
      await database.close();
    } catch (e) {
      // Ignore teardown errors in test environment
    }
  });

  group('EditServerScreen Core Functionality', () {
    testWidgets(
      'should display edit server screen',
      skip:
          true, // Still investigating hanging issue - may be related to database or provider lifecycle
      (WidgetTester tester) async {
        // Ensure clean state
        await TestProviders.cleanupTestEnvironment();

        await tester.pumpWidget(
          CupertinoApp(
            home: MultiProvider(
              providers: [
                Provider<AppDatabase>.value(value: database),
                Provider<UnifiedServerService>.value(
                  value: unifiedServerService,
                ),
                ChangeNotifierProvider.value(value: serverProvider),
              ],
              child: EditServerScreen(
                server: testServer,
                networkService: mockNetworkService,
              ),
            ),
          ),
        );

        // Pump once to build the widget
        await tester.pump();

        // Wait for the post-frame callback to execute
        await tester.pump(const Duration(milliseconds: 50));

        // Wait for credential loading to complete
        await tester.pump(const Duration(milliseconds: 200));

        // Check that the edit screen is displayed
        expect(find.text('Edit Server'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

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
                              Provider<UnifiedServerService>.value(
                                value: unifiedServerService,
                              ),
                              ChangeNotifierProvider.value(
                                value: serverProvider,
                              ),
                            ],
                            child: EditServerScreen(
                              server: testServer,
                              networkService: mockNetworkService,
                            ),
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to edit screen
      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Save without making changes (should still return true)
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
                              Provider<UnifiedServerService>.value(
                                value: unifiedServerService,
                              ),
                              ChangeNotifierProvider.value(
                                value: serverProvider,
                              ),
                            ],
                            child: EditServerScreen(
                              server: testServer,
                              networkService: mockNetworkService,
                            ),
                          ),
                        ),
                      );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to edit screen
      await tester.tap(find.text('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Cancel the edit
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(navigationResult, isNull);
    });

    testWidgets(
      'should update server in database when saved',
      skip:
          true, // Still investigating hanging issue - may be related to database or provider lifecycle
      (WidgetTester tester) async {
        // Ensure clean state
        await TestProviders.cleanupTestEnvironment();
        await tester.pumpWidget(
          CupertinoApp(
            home: MultiProvider(
              providers: [
                Provider<AppDatabase>.value(value: database),
                Provider<UnifiedServerService>.value(
                  value: unifiedServerService,
                ),
                ChangeNotifierProvider.value(value: serverProvider),
              ],
              child: EditServerScreen(
                server: testServer,
                networkService: mockNetworkService,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Extra delay to let _loadExistingCredentials complete
        await tester.pump(const Duration(milliseconds: 300));

        // Find and update the server name field
        final nameFields = find.byType(CupertinoTextField);
        expect(nameFields, findsWidgets);

        // Assuming the first text field is the name field based on the UI structure
        await tester.enterText(nameFields.first, 'Updated Server Name');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Save the changes
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify the server was updated in the database
        final updatedServer = await database.getServer(testServer.id);
        expect(updatedServer, isNotNull);
        expect(updatedServer!.name, 'Updated Server Name');
      },
    );
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
              Provider<UnifiedServerService>.value(value: unifiedServerService),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Update server name
      final nameFields = find.byType(CupertinoTextField);
      await tester.enterText(nameFields.first, 'Provider Updated Server');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
