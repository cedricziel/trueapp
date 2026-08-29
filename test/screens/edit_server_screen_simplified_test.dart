import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/edit_server_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/network_service.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/test_providers.dart';
import '../helpers/mock_network_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/form_finders.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late NasServer testServer;
  late MockNetworkService mockNetworkService;

  setUp(() async {
    // Clean up any leftover state from previous tests
    await TestProviders.cleanupTestEnvironment();

    // Set up test environment with mocks
    TestProviders.setupTestEnvironment();

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
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
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
              Provider<UnifiedServerService>.value(value: unifiedServerService),
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

      // The Cupertino navigation bar renders a second copy of its contents
      // while the push transition runs, so wait for it to settle before
      // tapping. Save without making changes should still return true.
      await tapWhenUnambiguous(tester, find.text('Save'));

      // Saving writes through to the database, which only makes progress
      // outside the FakeAsync zone.
      await pumpUntilAsync(tester, () => navigationResult != null);

      expect(navigationResult, isTrue);
    });

    testWidgets('should cancel edit and return null', (
      WidgetTester tester,
    ) async {
      bool? navigationResult;
      // `navigationResult` is null both before the route is pushed and after a
      // cancel, so on its own it cannot tell a successful cancel from a Cancel
      // button that never popped. This flag records that the route completed.
      var navigationCompleted = false;

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
                  navigationCompleted = true;
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

      // Cancel the edit once the push transition stopped duplicating the
      // navigation bar contents.
      await tapWhenUnambiguous(tester, find.text('Cancel'));
      await pumpUntil(tester, () => navigationCompleted);

      expect(
        navigationCompleted,
        isTrue,
        reason: 'Cancel should pop the edit screen',
      );
      expect(navigationResult, isNull);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('should update server in database when saved', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              Provider<UnifiedServerService>.value(value: unifiedServerService),
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

      // Save the changes and wait for the write to land.
      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.servers.any(
          (s) => s.id == testServer.id && s.name == 'Updated Server Name',
        ),
      );

      // Verify the server was updated in the database. The read has to leave
      // the FakeAsync zone, otherwise the drift future never completes.
      final updatedServer = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
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

      // Save changes and wait for the write to reach the provider.
      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.selectedServer?.name == 'Provider Updated Server',
      );

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
      expect(serverFromDb.useHttps, isTrue);
      expect(serverFromDb.allowUntrustedCertificates, isTrue);

      // Passwords are deliberately not persisted in the database - they live
      // in the keychain and are only written when passed explicitly.
      expect(serverFromDb.password, isEmpty);
    });

    test(
      'should store an updated password in the keychain, not the database',
      () async {
        await serverProvider.updateServer(
          testServer.copyWith(name: 'Keychain Test Server'),
          password: 'newpassword',
        );

        expect(
          await unifiedServerService.getPassword(testServer.id),
          'newpassword',
        );

        final serverFromDb = await database.getServer(testServer.id);
        expect(serverFromDb, isNotNull);
        expect(serverFromDb!.password, isEmpty);
      },
    );

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

  // The groups below extend the coverage above with the screen's own form
  // logic that a full save/cancel round trip doesn't exercise: field
  // validation gating Save, the trusted-Wi-Fi-SSID editor, Wi-Fi detection
  // (success, no-network and error branches - via the injectable
  // [MockNetworkService]), the HTTPS/certificate/default-server switches,
  // and clearing the optional local URL.
  Widget createEditScreen({NasServer? server, NetworkService? networkService}) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        Provider<UnifiedServerService>.value(value: unifiedServerService),
        ChangeNotifierProvider.value(value: serverProvider),
      ],
      child: CupertinoApp(
        home: EditServerScreen(
          server: server ?? testServer,
          networkService: networkService ?? mockNetworkService,
        ),
      ),
    );
  }

  // `CupertinoTextFormFieldRow` wraps its own `CupertinoTextField`
  // internally, so `find.byType(CupertinoTextField)` alone also matches
  // Name/Host/Port/etc - this pins down the free-standing Wi-Fi SSID input.
  Finder wifiSsidField() => find.byWidgetPredicate(
    (widget) =>
        widget is CupertinoTextField &&
        widget.placeholder == 'Wi-Fi network name',
  );

  // `ListView(children: [...])` only mounts elements within the viewport
  // plus a small cache extent, so widgets well below the fold - the HTTPS
  // switches, "Set as Default Server", the Test Connection button - are not
  // in the tree at all (not merely scrolled out of view) until dragged into
  // range.
  Future<void> scrollFormIntoView(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
  }

  Future<void> pumpEditScreen(
    WidgetTester tester, {
    NasServer? server,
    NetworkService? networkService,
  }) async {
    await tester.pumpWidget(
      createEditScreen(server: server, networkService: networkService),
    );
    await tester.pump();
    // Let the post-frame credential-loading callback finish.
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('form validation', () {
    testWidgets('Save is enabled as soon as the screen opens with a valid '
        'server', (tester) async {
      await pumpEditScreen(tester);

      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });

    testWidgets('Save is disabled once a required field is cleared', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      await tester.enterText(formFieldWithLabel('Host'), '');
      await tester.pump();

      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Save'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('Save stays enabled when the password field is empty', (
      tester,
    ) async {
      // Unlike AddServerScreen, EditServerScreen deliberately does not
      // require a password - the existing one from the keychain is kept.
      await pumpEditScreen(tester);

      await tester.enterText(formFieldWithLabel('Password'), '');
      await tester.pump();

      final saveButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Save'),
      );
      expect(saveButton.onPressed, isNotNull);
    });
  });

  group('trusted Wi-Fi SSID editor', () {
    testWidgets('the existing trusted SSID is listed with a Remove button', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      expect(find.text('HomeWiFi'), findsOneWidget);
      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsOneWidget);
    });

    testWidgets('adding an SSID clears the input and lists it', (tester) async {
      await pumpEditScreen(tester);

      await tester.enterText(wifiSsidField(), 'OfficeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      expect(find.text('OfficeWiFi'), findsOneWidget);
      final input = tester.widget<CupertinoTextField>(wifiSsidField());
      expect(input.controller!.text, isEmpty);
    });

    testWidgets('blank input is not added as an SSID', (tester) async {
      await pumpEditScreen(tester);

      await tester.enterText(wifiSsidField(), '   ');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      // Only the pre-existing 'HomeWiFi' Remove button, none added.
      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsOneWidget);
    });

    testWidgets('duplicate SSIDs are not added twice', (tester) async {
      await pumpEditScreen(tester);

      await tester.enterText(wifiSsidField(), 'HomeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsOneWidget);

      // `find.text` also matches an `EditableText` by its current value, so
      // clear the (still duplicate-holding) input before asserting there is
      // only one 'HomeWiFi' on screen - the trusted-list row.
      await tester.enterText(wifiSsidField(), '');
      await tester.pump();
      expect(find.text('HomeWiFi'), findsOneWidget);
    });

    testWidgets('removing the existing SSID takes it out of the list', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Remove'));
      await tester.pump();

      expect(find.text('HomeWiFi'), findsNothing);
      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsNothing);
    });

    testWidgets('a removed then re-added SSID is saved to the database', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Remove'));
      await tester.pump();
      await tester.enterText(wifiSsidField(), 'GuestWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.servers.any(
          (s) =>
              s.id == testServer.id && s.trustedWifiSsids.contains('GuestWiFi'),
        ),
      );

      final updated = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(updated!.trustedWifiSsids, ['GuestWiFi']);
    });
  });

  group('current Wi-Fi detection', () {
    testWidgets('Detect surfaces the current SSID with an Add Current button', (
      tester,
    ) async {
      mockNetworkService.setIsConnectedToWifi(true);
      mockNetworkService.setCurrentWifiSsid('CurrentNet');

      await pumpEditScreen(tester);

      await runRealAsync(tester, () async {
        await tester.tap(find.widgetWithText(CupertinoButton, 'Detect'));
      });
      await pumpUntilAsync(
        tester,
        () => find.text('CurrentNet').evaluate().isNotEmpty,
      );

      expect(find.text('CurrentNet'), findsOneWidget);
      expect(
        find.widgetWithText(CupertinoButton, 'Add Current'),
        findsOneWidget,
      );

      await tester.tap(find.widgetWithText(CupertinoButton, 'Add Current'));
      await tester.pump();

      // The suggestion row is now redundant with the trusted list and
      // disappears; the SSID moves into the trusted-network rows instead.
      expect(find.widgetWithText(CupertinoButton, 'Add Current'), findsNothing);
      expect(
        find.widgetWithText(CupertinoButton, 'Remove'),
        findsNWidgets(2), // pre-existing HomeWiFi + newly added CurrentNet
      );
    });

    testWidgets('Detect shows "No Wi-Fi Detected" when nothing is found', (
      tester,
    ) async {
      // MockNetworkService defaults to not connected.
      await pumpEditScreen(tester);

      await runRealAsync(tester, () async {
        await tester.tap(find.widgetWithText(CupertinoButton, 'Detect'));
      });
      await pumpUntilAsync(
        tester,
        () => find.text('No Wi-Fi Detected').evaluate().isNotEmpty,
      );

      expect(find.text('No Wi-Fi Detected'), findsOneWidget);
      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'OK'));
      await tester.pump();
      expect(find.text('No Wi-Fi Detected'), findsNothing);
    });

    testWidgets('Detect shows an error dialog when detection throws', (
      tester,
    ) async {
      mockNetworkService.setShouldFailOperations(true);

      await pumpEditScreen(tester);

      await runRealAsync(tester, () async {
        await tester.tap(find.widgetWithText(CupertinoButton, 'Detect'));
      });
      await pumpUntilAsync(
        tester,
        () => find.text('Wi-Fi Detection Error').evaluate().isNotEmpty,
      );

      expect(find.text('Wi-Fi Detection Error'), findsOneWidget);
      expect(find.textContaining('Mock error'), findsOneWidget);

      await tester.tap(find.widgetWithText(CupertinoDialogAction, 'OK'));
      await tester.pump();
      expect(find.text('Wi-Fi Detection Error'), findsNothing);
    });
  });

  group('HTTPS and certificate switches', () {
    testWidgets('toggling Use HTTPS off clears the port field', (tester) async {
      await pumpEditScreen(tester);

      expect(find.text('443'), findsOneWidget);

      await scrollFormIntoView(tester);
      await tester.tap(find.byType(CupertinoSwitch).first);
      await tester.pump();

      expect(find.text('443'), findsNothing);
    });

    testWidgets('Allow Untrusted Certificates reflects the server default '
        'and can be toggled', (tester) async {
      await pumpEditScreen(tester);
      await scrollFormIntoView(tester);

      final switches = find.byType(CupertinoSwitch);
      // Order in the form: Use HTTPS, Allow Untrusted Certificates, Set as
      // Default Server.
      final untrustedBefore = tester
          .widgetList<CupertinoSwitch>(switches)
          .elementAt(1);
      expect(untrustedBefore.value, isFalse);

      await tester.tap(switches.at(1));
      await tester.pump();

      final untrustedAfter = tester
          .widgetList<CupertinoSwitch>(switches)
          .elementAt(1);
      expect(untrustedAfter.value, isTrue);
    });
  });

  group('Set as Default Server', () {
    testWidgets('turning it on and saving sets the server as default', (
      tester,
    ) async {
      await pumpEditScreen(tester);
      await scrollFormIntoView(tester);

      final switches = find.byType(CupertinoSwitch);
      await tester.tap(switches.at(2));
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.servers.any(
          (s) => s.id == testServer.id && s.isDefault,
        ),
      );

      final updated = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(updated!.isDefault, isTrue);
    });

    testWidgets('turning it off after it was default clears the default', (
      tester,
    ) async {
      // Real drift/keychain work never completes inside `testWidgets`'
      // FakeAsync zone without `runRealAsync` stepping outside it.
      final defaultServer = await runRealAsync(tester, () async {
        await serverProvider.setDefaultServer(testServer.id);
        return (await database.getServer(testServer.id))!;
      });
      expect(defaultServer!.isDefault, isTrue);

      await pumpEditScreen(tester, server: defaultServer);
      await scrollFormIntoView(tester);

      final switches = find.byType(CupertinoSwitch);
      await tester.tap(switches.at(2));
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.servers.any(
          (s) => s.id == testServer.id && !s.isDefault,
        ),
      );

      final updated = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(updated!.isDefault, isFalse);
    });
  });

  group('local URL', () {
    testWidgets('clearing the field removes the stored local URL on save', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      expect(testServer.localUrl, isNotNull);
      await tester.enterText(formFieldWithLabel('Local URL'), '');
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(
        tester,
        () => serverProvider.servers.any(
          (s) => s.id == testServer.id && s.localUrl == null,
        ),
      );

      final updated = await runRealAsync(
        tester,
        () => database.getServer(testServer.id),
      );
      expect(updated!.localUrl, isNull);
    });
  });

  group('connection test', () {
    testWidgets('reports a friendly error when required fields are blank', (
      tester,
    ) async {
      await pumpEditScreen(tester);

      await tester.enterText(formFieldWithLabel('Password'), '');
      await tester.pump();
      await scrollFormIntoView(tester);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Test'));
      await tester.pump();

      expect(find.textContaining('Please fill in all fields'), findsOneWidget);
    });
  });
}
