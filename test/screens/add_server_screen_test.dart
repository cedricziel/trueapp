import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/add_server_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_truenas_server.dart';
import '../helpers/form_finders.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_providers.dart';

/// Covers `AddServerScreen`'s own form logic: field validation gating Save
/// and Test Connection, the trusted-Wi-Fi-SSID list editor, the HTTPS switch
/// clearing the port field, and the save/connection-test flows.
///
/// `test/navigation/add_server_navigation_test.dart` already covers routing
/// (Cancel popping back to the server list through the real router), so that
/// is deliberately not repeated here.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget createTestApp() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
      ],
      child: const CupertinoApp(home: AddServerScreen()),
    );
  }

  Finder saveButtonFinder() => find.widgetWithText(CupertinoButton, 'Save');

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
  // switches, the Test Connection button, its Result row - are not in the
  // tree at all (not merely scrolled out of view) until dragged into range.
  Future<void> scrollFormIntoView(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
  }

  Future<void> scrollFormToTop(WidgetTester tester) async {
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump();
  }

  Future<void> fillRequiredFields(
    WidgetTester tester, {
    String name = 'My Server',
    String host = '192.168.1.50',
  }) async {
    await tester.enterText(formFieldWithLabel('Name'), name);
    await tester.pump();
    await tester.enterText(formFieldWithLabel('Host'), host);
    await tester.pump();
    await tester.enterText(formFieldWithLabel('Username'), 'admin');
    await tester.pump();
    await tester.enterText(formFieldWithLabel('Password'), 'hunter2');
    await tester.pump();
  }

  group('form validation', () {
    testWidgets('Save is disabled until all required fields are filled', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      final saveButton = tester.widget<CupertinoButton>(saveButtonFinder());
      expect(saveButton.onPressed, isNull);

      await fillRequiredFields(tester);

      final enabledSaveButton = tester.widget<CupertinoButton>(
        saveButtonFinder(),
      );
      expect(enabledSaveButton.onPressed, isNotNull);
    });

    testWidgets(
      'Save stays disabled when only some required fields are filled',
      (tester) async {
        await tester.pumpWidget(createTestApp());

        await tester.enterText(formFieldWithLabel('Name'), 'My Server');
        await tester.pump();
        await tester.enterText(formFieldWithLabel('Host'), '192.168.1.50');
        await tester.pump();
        // Username and password left empty.

        final saveButton = tester.widget<CupertinoButton>(saveButtonFinder());
        expect(saveButton.onPressed, isNull);
      },
    );

    testWidgets('Test Connection button is disabled until form is valid', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await scrollFormIntoView(tester);

      final testButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Test'),
      );
      expect(testButton.onPressed, isNull);

      await scrollFormToTop(tester);
      await fillRequiredFields(tester);
      await scrollFormIntoView(tester);

      final enabledTestButton = tester.widget<CupertinoButton>(
        find.widgetWithText(CupertinoButton, 'Test'),
      );
      expect(enabledTestButton.onPressed, isNotNull);
    });
  });

  group('save flow', () {
    testWidgets('tapping Save persists the server and pops with true', (
      tester,
    ) async {
      bool? poppedWith;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
          ],
          child: CupertinoApp(
            home: Builder(
              builder: (context) => CupertinoButton(
                onPressed: () async {
                  poppedWith = await Navigator.of(context).push<bool>(
                    CupertinoPageRoute(builder: (_) => const AddServerScreen()),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await fillRequiredFields(
        tester,
        name: 'Persisted Server',
        host: '10.0.0.5',
      );

      await runRealAsync(tester, () async {
        await tester.tap(saveButtonFinder());
      });
      await pumpUntilAsync(
        tester,
        () => find.text('Open').evaluate().isNotEmpty,
      );
      // Persisting the first-ever server also fires `ServerProvider`'s own
      // fire-and-forget auto-select/authenticate chain (via its
      // `serversStream` listener). Wait for it to settle too, or its stray
      // continuation runs during the next test's `setUp` and hits an
      // already-disposed `serverProvider`.
      await pumpUntilAsync(tester, () => serverProvider.selectedServer != null);

      expect(poppedWith, isTrue);

      final servers = await runRealAsync(
        tester,
        () => unifiedServerService.getAllServers(),
      );
      expect(servers, isNotNull);
      expect(
        servers!.any(
          (s) => s.name == 'Persisted Server' && s.host == '10.0.0.5',
        ),
        isTrue,
      );
    });

    testWidgets('the saved server carries the entered trusted SSIDs', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      // Add the SSID before filling the fields below it - focusing the
      // Password field auto-scrolls the form to keep it visible, which
      // would carry the Add button out from under a tap landing at its
      // stale position.
      await tester.enterText(wifiSsidField(), 'HomeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();
      await fillRequiredFields(tester, name: 'SSID Server');

      expect(find.text('HomeWiFi'), findsOneWidget);

      await runRealAsync(tester, () async {
        await tester.tap(saveButtonFinder());
      });
      // Persisting the first-ever server also fires `ServerProvider`'s own
      // fire-and-forget auto-select/authenticate chain (via its
      // `serversStream` listener); wait for it to actually settle rather
      // than a single `pump()`, or its stray continuation runs during the
      // next test's `setUp` and hits an already-disposed `serverProvider`.
      await pumpUntilAsync(tester, () => serverProvider.selectedServer != null);

      final servers = await runRealAsync(
        tester,
        () => unifiedServerService.getAllServers(),
      );
      final saved = servers!.firstWhere((s) => s.name == 'SSID Server');
      expect(saved.trustedWifiSsids, contains('HomeWiFi'));
    });
  });

  group('trusted Wi-Fi SSID editor', () {
    testWidgets('adding an SSID clears the input and lists it with Remove', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      await tester.enterText(wifiSsidField(), 'OfficeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      expect(find.text('OfficeWiFi'), findsOneWidget);
      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsOneWidget);

      final input = tester.widget<CupertinoTextField>(wifiSsidField());
      expect(input.controller!.text, isEmpty);
    });

    testWidgets('blank input is not added as an SSID', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.enterText(wifiSsidField(), '   ');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();

      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsNothing);
    });

    testWidgets('duplicate SSIDs are not added twice', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.enterText(wifiSsidField(), 'HomeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();
      // The second Add is a no-op - the field is left untouched by
      // `_addWifiSsid` when the SSID is already trusted, so it isn't
      // cleared the way a successful add clears it.
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

    testWidgets('removing an SSID takes it back out of the list', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());

      await tester.enterText(wifiSsidField(), 'HomeWiFi');
      await tester.pump();
      await tester.tap(find.widgetWithText(CupertinoButton, 'Add'));
      await tester.pump();
      expect(find.text('HomeWiFi'), findsOneWidget);

      await tester.tap(find.widgetWithText(CupertinoButton, 'Remove'));
      await tester.pump();

      expect(find.text('HomeWiFi'), findsNothing);
      expect(find.widgetWithText(CupertinoButton, 'Remove'), findsNothing);
    });

    testWidgets('Detect surfaces a dialog when no Wi-Fi can be found', (
      tester,
    ) async {
      // On the Linux test VM the connectivity_plus / network_info_plus /
      // permission_handler platform channels have no host implementation
      // registered, so `NetworkService.getCurrentWifiSsidWithPermission`
      // resolves to `null` through its own internal catch rather than
      // throwing - this exercises the screen's "no SSID found" dialog
      // branch, not its error-dialog branch.
      await tester.pumpWidget(createTestApp());

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
  });

  group('HTTPS and certificate switches', () {
    testWidgets('toggling Use HTTPS off clears the port field', (tester) async {
      await tester.pumpWidget(createTestApp());

      await tester.enterText(formFieldWithLabel('Port'), '8443');
      await tester.pump();
      expect(find.text('8443'), findsOneWidget);

      await scrollFormIntoView(tester);
      await tester.tap(find.byType(CupertinoSwitch).first);
      await tester.pump();

      expect(find.text('8443'), findsNothing);
    });

    testWidgets('Allow Untrusted Certificates toggles independently', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await scrollFormIntoView(tester);

      final switches = find.byType(CupertinoSwitch);
      final untrustedSwitchBefore = tester
          .widgetList<CupertinoSwitch>(switches)
          .last;
      expect(untrustedSwitchBefore.value, isFalse);

      await tester.tap(switches.last);
      await tester.pump();

      final untrustedSwitchAfter = tester
          .widgetList<CupertinoSwitch>(switches)
          .last;
      expect(untrustedSwitchAfter.value, isTrue);
    });
  });

  group('connection test', () {
    testWidgets('a successful login reports success', (tester) async {
      // `testWidgets` bodies run inside a `FakeAsync` zone (see
      // `pump_helpers.dart`); starting the fake server's real `HttpServer`
      // there registers its internal idle-timeout `Timer` as a *fake* one
      // that outlives the test, tripping flutter_test's "pending timers"
      // assertion. `runRealAsync` steps outside the zone so it (and its
      // eventual `stop()`) behave like real sockets.
      final fakeServer = (await runRealAsync(tester, FakeTrueNasServer.start))!;

      await tester.pumpWidget(createTestApp());
      await fillRequiredFields(tester, name: 'Fake Server', host: '127.0.0.1');
      await tester.enterText(formFieldWithLabel('Port'), '${fakeServer.port}');
      await tester.pump();
      // The fake server only speaks plain WebSocket, not TLS.
      await scrollFormIntoView(tester);
      await tester.tap(find.byType(CupertinoSwitch).first);
      await tester.pump();
      // Toggling HTTPS clears the port field the same way a manual edit
      // would; put the fake server's port back. The port row is up near the
      // top of the form, so it has to be scrolled back into view first.
      await scrollFormToTop(tester);
      await tester.enterText(formFieldWithLabel('Port'), '${fakeServer.port}');
      await tester.pump();
      await scrollFormIntoView(tester);

      await runRealAsync(tester, () async {
        await tester.tap(find.widgetWithText(CupertinoButton, 'Test'));
      });
      await pumpUntilAsync(
        tester,
        () =>
            find.textContaining('Connection successful').evaluate().isNotEmpty,
      );

      expect(find.textContaining('Connection successful'), findsOneWidget);

      await runRealAsync(tester, fakeServer.stop);
    });

    testWidgets('a rejected login reports authentication failure', (
      tester,
    ) async {
      final fakeServer = (await runRealAsync(tester, FakeTrueNasServer.start))!;
      fakeServer.onMethod('auth.login', (_) => false);

      await tester.pumpWidget(createTestApp());
      await fillRequiredFields(tester, name: 'Fake Server', host: '127.0.0.1');
      await scrollFormIntoView(tester);
      await tester.tap(find.byType(CupertinoSwitch).first);
      await tester.pump();
      // The port row is up near the top of the form.
      await scrollFormToTop(tester);
      await tester.enterText(formFieldWithLabel('Port'), '${fakeServer.port}');
      await tester.pump();
      await scrollFormIntoView(tester);

      await runRealAsync(tester, () async {
        await tester.tap(find.widgetWithText(CupertinoButton, 'Test'));
      });
      await pumpUntilAsync(
        tester,
        () =>
            find.textContaining('Authentication failed').evaluate().isNotEmpty,
      );

      expect(find.textContaining('Authentication failed'), findsOneWidget);

      await runRealAsync(tester, fakeServer.stop);
    });

    testWidgets(
      'an unreachable host reports a failure result rather than hanging',
      (tester) async {
        // Bind and immediately release a port so nothing is listening on
        // it - a fast "connection refused" instead of a slow DNS/route
        // timeout keeps this test quick.
        final deadPort = await runRealAsync(tester, () async {
          final probe = await FakeTrueNasServer.start();
          final port = probe.port;
          await probe.stop();
          return port;
        });

        await tester.pumpWidget(createTestApp());
        await fillRequiredFields(
          tester,
          name: 'Unreachable Server',
          host: '127.0.0.1',
        );
        await scrollFormIntoView(tester);
        await tester.tap(find.byType(CupertinoSwitch).first);
        await tester.pump();
        // The port row is up near the top of the form.
        await scrollFormToTop(tester);
        await tester.enterText(formFieldWithLabel('Port'), '$deadPort');
        await tester.pump();
        await scrollFormIntoView(tester);

        await runRealAsync(tester, () async {
          await tester.tap(find.widgetWithText(CupertinoButton, 'Test'));
        });
        await pumpUntilAsync(
          tester,
          () => find.textContaining('❌').evaluate().isNotEmpty,
          timeout: const Duration(seconds: 20),
        );

        expect(find.textContaining('❌'), findsOneWidget);
      },
    );
  });
}
