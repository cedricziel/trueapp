import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/home_screen.dart';
import 'package:truenas_manager/services/database.dart';

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
          return CupertinoApp(
            home: MultiProvider(
              providers: [
                Provider<AppDatabase>.value(value: database),
                ChangeNotifierProvider.value(value: serverProvider),
                ChangeNotifierProvider.value(value: poolProvider),
              ],
              child: const HomeScreen(),
            ),
          );
        }

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // STEP 1: Verify we're on the Home Screen with our registered server
        expect(find.text('TrueNAS Manager'), findsOneWidget);
        expect(find.text('Test TrueNAS Server'), findsOneWidget);
        expect(find.text('https://192.168.1.100:443'), findsOneWidget);

        // Verify server is not yet selected in provider
        expect(serverProvider.selectedServer, isNull);

        // STEP 2: Navigate to Server Detail Screen by tapping on the server
        await tester.tap(find.text('Test TrueNAS Server'));
        await tester.pumpAndSettle();

        // Verify we're on the Server Detail Screen
        expect(
          find.text('Test TrueNAS Server'),
          findsOneWidget,
        ); // Navigation bar title
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
        await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
        await tester.pumpAndSettle();

        // Verify action sheet is displayed
        expect(find.text('Edit Server'), findsOneWidget);

        // Tap "Edit Server" in the action sheet
        await tester.tap(find.text('Edit Server'));
        await tester.pumpAndSettle();

        // Verify we're on the Edit Server Screen
        expect(
          find.text('Edit Server'),
          findsOneWidget,
        ); // Navigation bar title
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        // STEP 4: Make changes to the server

        // Find and update the server name field
        final nameFields = find.byType(CupertinoTextField);
        expect(nameFields, findsWidgets);

        // Update server name (first field)
        await tester.enterText(nameFields.first, 'Updated TrueNAS Server');
        await tester.pumpAndSettle();

        // Toggle allow untrusted certificates
        final untrustedCertToggle = find.byWidgetPredicate(
          (widget) =>
              widget is CupertinoSwitch &&
              find
                  .ancestor(
                    of: find.byWidget(widget),
                    matching: find.byWidgetPredicate(
                      (parent) =>
                          parent is CupertinoFormRow &&
                          find
                              .descendant(
                                of: find.byWidget(parent),
                                matching: find.text(
                                  'Allow Untrusted Certificates',
                                ),
                              )
                              .evaluate()
                              .isNotEmpty,
                    ),
                  )
                  .evaluate()
                  .isNotEmpty,
        );

        await tester.tap(untrustedCertToggle);
        await tester.pumpAndSettle();

        // Update host field (find by looking for the field that contains the host)
        final allTextFields = find.byType(CupertinoTextField);
        for (
          int i = 0;
          i < tester.widgetList<CupertinoTextField>(allTextFields).length;
          i++
        ) {
          final textField = tester.widget<CupertinoTextField>(
            allTextFields.at(i),
          );
          if (textField.controller?.text == '192.168.1.100') {
            await tester.enterText(allTextFields.at(i), '192.168.1.150');
            await tester.pumpAndSettle();
            break;
          }
        }

        // Add a new WiFi SSID
        final wifiSsidField = find.byWidgetPredicate(
          (widget) =>
              widget is CupertinoTextField &&
              widget.placeholder == 'Wi-Fi network name',
        );

        await tester.enterText(wifiSsidField, 'OfficeWiFi');
        await tester.pumpAndSettle();

        // Tap Add button for WiFi SSID
        final addButtons = find.text('Add');
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();

        // STEP 5: Save the changes
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        // STEP 6: Verify we're back on the Server Detail Screen with updated data
        expect(
          find.text('Updated TrueNAS Server'),
          findsOneWidget,
        ); // Navigation bar should show updated name

        // Wait for any potential async operations to complete
        await tester.pumpAndSettle();

        // STEP 7: Verify changes have bubbled up to the provider
        expect(serverProvider.selectedServer, isNotNull);
        expect(serverProvider.selectedServer?.name, 'Updated TrueNAS Server');
        expect(serverProvider.selectedServer?.host, '192.168.1.150');
        expect(
          serverProvider.selectedServer?.allowUntrustedCertificates,
          isTrue,
        );
        expect(
          serverProvider.selectedServer?.trustedWifiSsids,
          contains('HomeWiFi'),
        );
        expect(
          serverProvider.selectedServer?.trustedWifiSsids,
          contains('OfficeWiFi'),
        );

        // STEP 8: Verify changes are persisted in the database
        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb, isNotNull);
        expect(serverFromDb!.name, 'Updated TrueNAS Server');
        expect(serverFromDb.host, '192.168.1.150');
        expect(serverFromDb.allowUntrustedCertificates, isTrue);
        expect(serverFromDb.trustedWifiSsids, contains('HomeWiFi'));
        expect(serverFromDb.trustedWifiSsids, contains('OfficeWiFi'));

        // STEP 9: Verify the server list in provider is also updated
        final serversInProvider = serverProvider.servers;
        final updatedServerInList = serversInProvider.firstWhere(
          (s) => s.id == testServer.id,
        );
        expect(updatedServerInList.name, 'Updated TrueNAS Server');
        expect(updatedServerInList.host, '192.168.1.150');
        expect(updatedServerInList.allowUntrustedCertificates, isTrue);

        // STEP 10: Navigate back to Home Screen and verify changes are reflected
        await tester.tap(find.byIcon(CupertinoIcons.back));
        await tester.pumpAndSettle();

        // Should be back on Home Screen
        expect(find.text('TrueNAS Manager'), findsOneWidget);
        expect(find.text('Updated TrueNAS Server'), findsOneWidget);
        expect(find.text('https://192.168.1.150:443'), findsOneWidget);

        // Original server name should no longer be visible
        expect(find.text('Test TrueNAS Server'), findsNothing);
        expect(find.text('https://192.168.1.100:443'), findsNothing);
      },
    );

    testWidgets(
      'should handle edit cancellation without affecting provider state',
      (WidgetTester tester) async {
        Widget createTestApp() {
          return CupertinoApp(
            home: MultiProvider(
              providers: [
                Provider<AppDatabase>.value(value: database),
                ChangeNotifierProvider.value(value: serverProvider),
                ChangeNotifierProvider.value(value: poolProvider),
              ],
              child: const HomeScreen(),
            ),
          );
        }

        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Navigate to server detail
        await tester.tap(find.text('Test TrueNAS Server'));
        await tester.pumpAndSettle();

        // Store original server state
        final originalServer = serverProvider.selectedServer!;
        expect(originalServer.name, 'Test TrueNAS Server');
        expect(originalServer.host, '192.168.1.100');
        expect(originalServer.allowUntrustedCertificates, isFalse);

        // Navigate to edit screen
        await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Edit Server'));
        await tester.pumpAndSettle();

        // Make changes
        final nameFields = find.byType(CupertinoTextField);
        await tester.enterText(nameFields.first, 'Changed Server Name');
        await tester.pumpAndSettle();

        // Cancel instead of saving
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

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
        return CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
              ChangeNotifierProvider.value(value: poolProvider),
            ],
            child: const HomeScreen(),
          ),
        );
      }

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Navigate to server detail
      await tester.tap(find.text('Test TrueNAS Server'));
      await tester.pumpAndSettle();

      // First edit: Change name
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      final nameFields = find.byType(CupertinoTextField);
      await tester.enterText(nameFields.first, 'First Edit');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify first change
      expect(find.text('First Edit'), findsOneWidget);
      expect(serverProvider.selectedServer?.name, 'First Edit');

      // Second edit: Toggle HTTPS and change port
      await tester.tap(find.byIcon(CupertinoIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      // Toggle HTTPS off
      final httpsToggle = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoSwitch &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoFormRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Use HTTPS'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      await tester.tap(httpsToggle);
      await tester.pumpAndSettle();

      // Save second edit
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

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
