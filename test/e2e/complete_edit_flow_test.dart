import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/home_screen.dart';
import 'package:truehub/services/database.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late PoolProvider poolProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);
    poolProvider = PoolProvider();

    // Create and register a test server
    testServer = NasServer.create(
      name: 'Test TrueNAS Server',
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
  });

  tearDown(() async {
    await database.close();
  });

  group('Complete Edit Flow End-to-End Test', () {
    testWidgets(
      'should complete full user journey: Home → Server Detail → Edit → Save → Provider Update',
      (WidgetTester tester) async {
        // Create the complete app with providers
        Widget createTestApp() {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider.value(value: poolProvider),
            ],
            child: const CupertinoApp(home: HomeScreen()),
          );
        }

        await tester.pumpWidget(createTestApp());

        // Wait for initial build with timeout protection
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // STEP 1: Verify we're on the Home Screen with our registered server
        expect(find.text('TrueNAS Manager'), findsOneWidget);
        expect(find.text('Test TrueNAS Server'), findsOneWidget);
        expect(find.text('https://192.168.1.100:443'), findsOneWidget);

        // Verify server is not yet selected in provider
        expect(serverProvider.selectedServer, isNull);

        // STEP 2: Navigate to Server Detail Screen by tapping on the server
        await tester.tap(find.text('Test TrueNAS Server'));
        // Wait for navigation to complete without pumpAndSettle
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Extra wait for async operations in ServerDetailScreen
        await tester.pump(const Duration(milliseconds: 500));

        // Verify we're on the Server Detail Screen
        // Multiple instances of server name may exist (navigation bar, content)
        expect(find.text('Test TrueNAS Server'), findsWidgets);
        expect(find.text('Host'), findsOneWidget);
        expect(find.text('192.168.1.100'), findsOneWidget);
        expect(find.text('Port'), findsOneWidget);
        expect(find.text('443'), findsOneWidget);
        expect(find.text('Protocol'), findsOneWidget);
        expect(find.text('HTTPS'), findsOneWidget);
        expect(find.text('Username'), findsOneWidget);
        expect(find.text('admin'), findsOneWidget);

        // Verify server is now selected in provider
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Test TrueNAS Server');
        expect(serverProvider.selectedServer?.host, '192.168.1.100');
        expect(serverProvider.selectedServer?.port, 443);
        expect(serverProvider.selectedServer?.useHttps, isTrue);
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isFalse,
        );

        // STEP 3: Navigate to Edit Screen via the ellipsis menu
        // Find ellipsis in navigation bar
        final ellipsisButton = find.byIcon(CupertinoIcons.ellipsis);
        expect(ellipsisButton, findsOneWidget);

        await tester.tap(ellipsisButton);
        await tester.pump(const Duration(milliseconds: 100)); // Start animation
        await tester.pump(
          const Duration(milliseconds: 300),
        ); // Complete animation

        // Verify action sheet is displayed
        final actionSheet = find.byType(CupertinoActionSheet);
        expect(actionSheet, findsOneWidget);
        expect(find.text('Edit Server'), findsOneWidget);

        // Tap "Edit Server" in the action sheet
        await tester.tap(find.text('Edit Server'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify we're on the Edit Server Screen
        expect(
          find.text('Edit Server'),
          findsOneWidget,
        ); // Navigation bar title
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // STEP 4: Make changes to the server (simplified to just change name)
        // Find and update the server name field (this should be at the top and visible)
        final nameFields = find.byType(CupertinoTextField);
        expect(nameFields, findsWidgets);

        // Update server name (first field)
        await tester.enterText(nameFields.first, 'Updated TrueNAS Server');
        await tester.pump(const Duration(milliseconds: 100));

        // STEP 5: Save the changes
        // Save button should be in navigation bar and visible
        final saveButtons = find.text('Save');
        expect(saveButtons, findsWidgets);
        await tester.tap(saveButtons.first, warnIfMissed: false);
        // Use pump with duration for navigation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // STEP 6: Verify we're back on the Server Detail Screen with updated data
        expect(
          find.text('Updated TrueNAS Server'),
          findsOneWidget,
        ); // Navigation bar should show updated name

        // Wait for any potential async operations to complete
        await tester.pump(const Duration(milliseconds: 100));

        // STEP 7: Verify core changes have bubbled up to the provider
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Updated TrueNAS Server');
        // Host should remain unchanged since we only tested name change
        expect(serverProvider.selectedServer?.host, '192.168.1.100');

        // Note: Skip complex field verifications in e2e test as they are covered in unit tests
        // The key is that the basic edit flow works

        // STEP 8: Verify core changes are persisted in the database
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb, isNotNull);
        expect(serverFromDb!.name, 'Updated TrueNAS Server');
        expect(serverFromDb.host, '192.168.1.100');

        // STEP 9: Verify the server list in provider is also updated
        final serversInProvider = serverProvider.servers;
        final updatedServerInList = serversInProvider.firstWhere(
          (s) => s.id == testServer.id,
        );
        expect(updatedServerInList.name, 'Updated TrueNAS Server');
        expect(updatedServerInList.host, '192.168.1.100');

        // End of test - we've verified the core edit flow works
      },
    );

    testWidgets(
      'should handle edit cancellation without affecting provider state',
      (WidgetTester tester) async {
        Widget createTestApp() {
          return MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider.value(value: poolProvider),
            ],
            child: const CupertinoApp(home: HomeScreen()),
          );
        }

        await tester.pumpWidget(createTestApp());

        // Wait for initial build with timeout protection
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Navigate to server detail
        await tester.tap(find.text('Test TrueNAS Server'));
        // Wait for navigation to complete without pumpAndSettle
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Extra wait for async operations in ServerDetailScreen
        await tester.pump(const Duration(milliseconds: 500));

        // Store original server state
        final originalServer = serverProvider.selectedServer!;
        expect(originalServer.name, 'Test TrueNAS Server');
        expect(originalServer.host, '192.168.1.100');
        expect(originalServer.allowUntrustedCertificates, isFalse);

        // Navigate to edit screen
        final ellipsisButton = find.byIcon(CupertinoIcons.ellipsis);
        expect(ellipsisButton, findsOneWidget);

        await tester.tap(ellipsisButton);
        await tester.pump(const Duration(milliseconds: 100)); // Start animation
        await tester.pump(
          const Duration(milliseconds: 300),
        ); // Complete animation

        // Verify action sheet appeared
        expect(find.byType(CupertinoActionSheet), findsOneWidget);
        expect(find.text('Edit Server'), findsOneWidget);

        await tester.tap(find.text('Edit Server'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Make changes
        final nameFields = find.byType(CupertinoTextField);
        await tester.enterText(nameFields.first, 'Changed Server Name');
        await tester.pump(const Duration(milliseconds: 100));

        // Cancel instead of saving
        await tester.tap(find.text('Cancel'));
        // Use pump with duration for navigation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        // Verify we're back on server detail screen with original data
        expect(find.text('Test TrueNAS Server'), findsOneWidget);

        // Verify provider state is unchanged
        expect(serverProvider.selectedServer?.name, 'Test TrueNAS Server');
        expect(serverProvider.selectedServer?.host, '192.168.1.100');
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isFalse,
        );

        // Verify database is unchanged
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb!.name, 'Test TrueNAS Server');
        expect(serverFromDb.host, '192.168.1.100');
        expect(serverFromDb.allowUntrustedCertificates, isFalse);
      },
    );

    testWidgets('should handle multiple consecutive edits correctly', (
      WidgetTester tester,
    ) async {
      Widget createTestApp() {
        return MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider.value(value: serverProvider),
            ChangeNotifierProvider.value(value: poolProvider),
          ],
          child: const CupertinoApp(home: HomeScreen()),
        );
      }

      await tester.pumpWidget(createTestApp());

      // Wait for initial build with timeout protection
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to server detail
      await tester.tap(find.text('Test TrueNAS Server'));
      // Wait for navigation to complete without pumpAndSettle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Extra wait for async operations in ServerDetailScreen
      await tester.pump(const Duration(milliseconds: 500));

      // First edit: Change name
      final ellipsisButton = find.byIcon(CupertinoIcons.ellipsis);
      expect(ellipsisButton, findsOneWidget);

      await tester.tap(ellipsisButton);
      await tester.pump(const Duration(milliseconds: 100)); // Start animation
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Complete animation

      // Verify action sheet appeared
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Server'), findsOneWidget);

      await tester.tap(find.text('Edit Server'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final nameFields = find.byType(CupertinoTextField);
      await tester.enterText(nameFields.first, 'First Edit');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Save'));
      // Use pump with duration for navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify first change
      expect(find.text('First Edit'), findsOneWidget);
      expect(serverProvider.selectedServer?.name, 'First Edit');

      // Second edit: Toggle HTTPS and change port
      final ellipsisButton2 = find.byIcon(CupertinoIcons.ellipsis);
      expect(ellipsisButton2, findsOneWidget);

      await tester.tap(ellipsisButton2);
      await tester.pump(const Duration(milliseconds: 100)); // Start animation
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // Complete animation

      // Verify action sheet appeared
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Server'), findsOneWidget);

      await tester.tap(find.text('Edit Server'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Toggle HTTPS off
      // First scroll to ensure it's visible
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump(const Duration(milliseconds: 100));

      final httpsRow = find.text('Use HTTPS');
      if (httpsRow.evaluate().isNotEmpty) {
        final httpsToggle = find.descendant(
          of: find.ancestor(
            of: httpsRow,
            matching: find.byType(CupertinoFormRow),
          ),
          matching: find.byType(CupertinoSwitch),
        );

        if (httpsToggle.evaluate().isNotEmpty) {
          await tester.tap(httpsToggle);
        }
      }
      await tester.pump(const Duration(milliseconds: 100));

      // Save second edit
      await tester.tap(find.text('Save'));
      // Use pump with duration for navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify both changes are reflected
      expect(find.text('First Edit'), findsOneWidget);
      expect(serverProvider.selectedServer?.name, 'First Edit');
      expect(serverProvider.selectedServer?.useHttps, isFalse);

      // Verify changes are persisted
      final finalServer = await database.getServer(testServer.id);
      expect(finalServer!.name, 'First Edit');
      expect(finalServer.useHttps, isFalse);
    });
  });
}
