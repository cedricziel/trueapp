import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);

    // Create a test server
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

    // Add server to database
    await serverProvider.addServer(testServer);
  });

  tearDown(() async {
    await database.close();
  });

  group('EditServerScreen', () {
    Widget createTestWidget() {
      return CupertinoApp(
        home: MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider.value(value: serverProvider),
          ],
          child: EditServerScreen(server: testServer),
        ),
      );
    }

    testWidgets('should render edit server screen with existing data', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check that the form fields are populated with existing data
      expect(find.text('Test Server'), findsAtLeastNWidgets(1));
      expect(find.text('192.168.1.100'), findsAtLeastNWidgets(1));
      expect(find.text('http://192.168.1.200:8080'), findsAtLeastNWidgets(1));
      expect(find.text('443'), findsAtLeastNWidgets(1));
      expect(find.text('admin'), findsAtLeastNWidgets(1));
      expect(find.text('HomeWiFi'), findsOneWidget);

      // Check that HTTPS toggle is enabled
      final httpsSwitch = tester.widget<CupertinoSwitch>(
        find.byWidgetPredicate(
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
        ),
      );
      expect(httpsSwitch.value, isTrue);

      // Check that untrusted certificates toggle is disabled
      final untrustedCertSwitch = tester.widget<CupertinoSwitch>(
        find.byWidgetPredicate(
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
        ),
      );
      expect(untrustedCertSwitch.value, isFalse);
    });

    testWidgets('should update server name and save successfully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the name field and update it
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      await tester.enterText(nameField, 'Updated Test Server');
      await tester.pumpAndSettle();

      // Tap the save button
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify that the server was updated in the database
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.name, 'Updated Test Server');
    });

    testWidgets('should toggle HTTPS and clear port field', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the HTTPS toggle
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

      // Toggle HTTPS off
      await tester.tap(httpsToggle);
      await tester.pumpAndSettle();

      // Find the port field and verify it's cleared
      final portField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Port'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      final portFieldWidget = tester.widget<CupertinoTextField>(portField);
      expect(portFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('should add and remove trusted WiFi SSIDs', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the WiFi SSID input field
      final wifiSsidField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            widget.placeholder == 'Wi-Fi network name',
      );

      // Add a new SSID
      await tester.enterText(wifiSsidField, 'NewWiFi');
      await tester.pumpAndSettle();

      // Tap the Add button
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Verify the new SSID appears in the list
      expect(find.text('NewWiFi'), findsOneWidget);

      // Remove the original SSID
      final removeButtons = find.text('Remove');
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the server was updated with new trusted WiFi SSIDs
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.trustedWifiSsids, contains('NewWiFi'));
      expect(updatedServer.trustedWifiSsids, isNot(contains('HomeWiFi')));
    });

    testWidgets('should toggle allow untrusted certificates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the untrusted certificates toggle
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

      // Toggle untrusted certificates on
      await tester.tap(untrustedCertToggle);
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the server was updated
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.allowUntrustedCertificates, isTrue);
    });

    testWidgets('should return navigation result true when changes are saved', (
      WidgetTester tester,
    ) async {
      bool? navigationResult;

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Test Navigation'),
              ),
              child: Center(
                child: CupertinoButton(
                  child: const Text('Edit Server'),
                  onPressed: () async {
                    navigationResult =
                        await Navigator.of(
                          tester.element(find.byType(CupertinoButton)),
                        ).push<bool>(
                          CupertinoPageRoute(
                            builder: (context) =>
                                EditServerScreen(server: testServer),
                          ),
                        );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the button to navigate to edit screen
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      // Make a change (update name)
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      await tester.enterText(nameField, 'Changed Name');
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify navigation result is true
      expect(navigationResult, isTrue);
    });

    testWidgets('should return navigation result null when cancelled', (
      WidgetTester tester,
    ) async {
      bool? navigationResult;

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Test Navigation'),
              ),
              child: Center(
                child: CupertinoButton(
                  child: const Text('Edit Server'),
                  onPressed: () async {
                    navigationResult =
                        await Navigator.of(
                          tester.element(find.byType(CupertinoButton)),
                        ).push<bool>(
                          CupertinoPageRoute(
                            builder: (context) =>
                                EditServerScreen(server: testServer),
                          ),
                        );
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the button to navigate to edit screen
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      // Cancel without saving
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify navigation result is null
      expect(navigationResult, isNull);
    });

    testWidgets('should validate form fields and disable save when invalid', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear the name field to make form invalid
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      // Find the save button and verify it's disabled
      final saveButton = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoButton &&
            find
                .descendant(
                  of: find.byWidget(widget),
                  matching: find.text('Save'),
                )
                .evaluate()
                .isNotEmpty,
      );

      final saveButtonWidget = tester.widget<CupertinoButton>(saveButton);
      expect(saveButtonWidget.onPressed, isNull);
    });
  });

  group('Server Provider Integration', () {
    testWidgets('should refresh server data after edit', (
      WidgetTester tester,
    ) async {
      // Set the test server as the active server
      serverProvider.selectServer(testServer);

      Widget createTestWidget() {
        return CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        );
      }

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Update the server name
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );

      await tester.enterText(nameField, 'Server Updated via Provider');
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the server provider has the updated server
      final updatedServer = serverProvider.selectedServer;
      expect(updatedServer, isNotNull);
      expect(updatedServer!.name, 'Server Updated via Provider');
    });
  });
}
