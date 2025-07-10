import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';
import 'package:truenas_manager/screens/server_detail_screen.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);

    // Create and register a test server
    testServer = NasServer.create(
      name: 'Original Server',
      host: '192.168.1.100',
      localUrl: 'http://192.168.1.200:8080',
      trustedWifiSsids: ['HomeWiFi'],
      port: 443,
      username: 'admin',
      password: 'password',
      useHttps: true,
      allowUntrustedCertificates: false,
    );

    await serverProvider.addServer(testServer);
    serverProvider.selectServer(testServer); // Select the server for editing
  });

  tearDown(() async {
    await database.close();
  });

  group('Server Edit Provider Update Test', () {
    testWidgets(
      'should start with registered server, navigate to edit, make changes, save, and confirm changes bubble up to provider',
      (WidgetTester tester) async {
        // STEP 1: Start with a registered server
        expect(serverProvider.servers.length, 1);
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Original Server');
        expect(serverProvider.selectedServer?.host, '192.168.1.100');
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isFalse,
        );
        expect(serverProvider.selectedServer?.trustedWifiSsids, ['HomeWiFi']);

        // STEP 2: Create a mock navigation flow that simulates going from overview to edit
        Widget createEditFlow() {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider(create: (_) => PoolProvider()),
            ],
            child: CupertinoApp(
              home: ServerDetailScreen(server: serverProvider.selectedServer!),
            ),
          );
        }

        await tester.pumpWidget(createEditFlow());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify we're on the server detail screen
        expect(find.text('Original Server'), findsOneWidget);
        expect(find.text('192.168.1.100'), findsOneWidget);

        // Store a reference to track provider changes
        int notificationCount = 0;
        void listener() {
          notificationCount++;
        }

        serverProvider.addListener(listener);

        // STEP 3: Navigate to edit screen via the ellipsis menu
        await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.text('Edit Server').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify we're on the edit screen
        expect(find.text('Edit Server'), findsWidgets);
        expect(find.text('Save'), findsWidgets);
        expect(find.text('Cancel'), findsWidgets);

        // STEP 4: Make changes to the server (simplified to just change name)
        final textFields = find.byType(CupertinoTextField);

        // Find and update the name field (first text field)
        await tester.enterText(textFields.first, 'Updated Server Name');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // STEP 5: Save the changes
        await tester.tap(find.text('Save').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // STEP 6: Confirm changes bubble up to the provider

        // Verify the selected server in the provider has been updated
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Updated Server Name');
        expect(
          serverProvider.selectedServer?.host,
          '192.168.1.100',
        ); // Host unchanged
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isFalse, // Unchanged
        );
        expect(
          serverProvider.selectedServer?.trustedWifiSsids,
          contains('HomeWiFi'), // Original SSID should remain
        );

        // Verify the server in the servers list has been updated
        final updatedServerInList = serverProvider.servers.firstWhere(
          (s) => s.id == testServer.id,
        );
        expect(updatedServerInList.name, 'Updated Server Name');
        expect(updatedServerInList.host, '192.168.1.100'); // Host unchanged
        expect(
          updatedServerInList.allowUntrustedCertificates,
          isFalse,
        ); // Unchanged
        expect(
          updatedServerInList.trustedWifiSsids,
          contains('HomeWiFi'),
        ); // Original SSID

        // Verify changes were persisted to the database
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb, isNotNull);
        expect(serverFromDb!.name, 'Updated Server Name');
        expect(serverFromDb.host, '192.168.1.100'); // Host unchanged
        expect(serverFromDb.allowUntrustedCertificates, isFalse); // Unchanged
        expect(
          serverFromDb.trustedWifiSsids,
          contains('HomeWiFi'),
        ); // Original SSID

        // Verify the provider notified listeners of the changes
        expect(notificationCount, greaterThan(0));

        // Clean up listener
        serverProvider.removeListener(listener);
      },
    );

    testWidgets(
      'should verify that canceling edit does not affect provider state',
      (WidgetTester tester) async {
        // Store original state
        final originalName = serverProvider.selectedServer!.name;
        final originalHost = serverProvider.selectedServer!.host;
        final originalCertSetting =
            serverProvider.selectedServer!.allowUntrustedCertificates;

        Widget createEditFlow() {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider(create: (_) => PoolProvider()),
            ],
            child: CupertinoApp(
              home: EditServerScreen(server: serverProvider.selectedServer!),
            ),
          );
        }

        await tester.pumpWidget(createEditFlow());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Make changes
        final textFields = find.byType(CupertinoTextField);
        await tester.enterText(textFields.first, 'Should Not Save');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Cancel instead of saving
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify provider state is unchanged
        expect(serverProvider.selectedServer?.name, originalName);
        expect(serverProvider.selectedServer?.host, originalHost);
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          originalCertSetting,
        );

        // Verify database is unchanged
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb!.name, originalName);
        expect(serverFromDb.host, originalHost);
        expect(serverFromDb.allowUntrustedCertificates, originalCertSetting);
      },
    );

    test('should verify provider refresh mechanism works correctly', () async {
      // Select the server
      serverProvider.selectServer(testServer);
      expect(serverProvider.selectedServer?.name, 'Original Server');

      // Simulate a direct database update (as if another process updated the server)
      final updatedServer = testServer.copyWith(
        name: 'Externally Updated Server',
        host: '192.168.1.999',
        allowUntrustedCertificates: true,
      );

      await database.updateServer(updatedServer);

      // Provider should still have old data until refreshed
      expect(serverProvider.selectedServer?.name, 'Original Server');
      expect(serverProvider.selectedServer?.host, '192.168.1.100');

      // Refresh the selected server
      await serverProvider.refreshSelectedServer();

      // Provider should now have updated data
      expect(serverProvider.selectedServer?.name, 'Externally Updated Server');
      expect(serverProvider.selectedServer?.host, '192.168.1.999');
      expect(serverProvider.selectedServer?.allowUntrustedCertificates, isTrue);
    });

    test(
      'should verify updateServer automatically refreshes selected server',
      () async {
        // Select the server
        serverProvider.selectServer(testServer);
        expect(serverProvider.selectedServer?.name, 'Original Server');

        // Update through the provider (this should automatically refresh)
        final updatedServer = testServer.copyWith(
          name: 'Provider Updated Server',
          allowUntrustedCertificates: true,
          trustedWifiSsids: ['NewWiFi'],
        );

        await serverProvider.updateServer(updatedServer);

        // Verify the selected server is automatically updated
        expect(serverProvider.selectedServer?.name, 'Provider Updated Server');
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isTrue,
        );
        expect(
          serverProvider.selectedServer?.trustedWifiSsids,
          contains('NewWiFi'),
        );

        // Verify the servers list is also updated
        final serverInList = serverProvider.servers.firstWhere(
          (s) => s.id == testServer.id,
        );
        expect(serverInList.name, 'Provider Updated Server');
        expect(serverInList.allowUntrustedCertificates, isTrue);
        expect(serverInList.trustedWifiSsids, contains('NewWiFi'));
      },
    );
  });
}
