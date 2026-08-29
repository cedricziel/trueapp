import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/services/authentication_session_service.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  group('Settings Screen Tests', () {
    late AppDatabase database;
    late ServerProvider serverProvider;
    late UnifiedServerService unifiedServerService;
    late TrayProvider trayProvider;

    // WindowManager talks to the native side over this MethodChannel. There
    // is no handler registered for it in the `flutter test` VM, so toggling
    // "Show in Dock" would otherwise throw a MissingPluginException - see
    // test/providers/tray_provider_test.dart for the same setup.
    const windowChannel = MethodChannel('com.truenas.manager/window');

    setUp(() async {
      await TestProviders.cleanupTestEnvironment();
      TestProviders.setupTestEnvironment();
      database = createTestDatabase();
      unifiedServerService = await TestProviders.createMockUnifiedServerService(
        database: database,
      );
      serverProvider = ServerProvider(unifiedServerService);
      trayProvider = TrayProvider();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, (call) async => null);

      // This is a process-wide singleton, so a session left authenticated by
      // one test would otherwise leak into the next.
      AuthenticationSessionService.instance.invalidateSession();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, null);
      AuthenticationSessionService.instance.invalidateSession();
    });

    testWidgets('should display settings screen with clear database option', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
            ChangeNotifierProvider<TrayProvider>.value(value: trayProvider),
          ],
          child: const CupertinoApp(home: SettingsScreen()),
        ),
      );

      // Verify the screen title
      expect(find.text('Settings'), findsOneWidget);

      // Verify database section
      expect(find.text('DATABASE'), findsOneWidget);
      expect(find.text('Clear Database'), findsOneWidget);
      expect(
        find.text('Remove all servers and reset app data'),
        findsOneWidget,
      );
      expect(find.text('Clear'), findsOneWidget);

      // Verify about section
      expect(find.text('ABOUT'), findsOneWidget);
      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0+1'), findsOneWidget);
      expect(find.text('Database Schema'), findsOneWidget);
      expect(find.text('Version 1'), findsOneWidget);
    });

    testWidgets(
      'should show confirmation dialog when clear database is tapped',
      (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ServerProvider>.value(
                value: serverProvider,
              ),
              ChangeNotifierProvider<TrayProvider>.value(value: trayProvider),
            ],
            child: const CupertinoApp(home: SettingsScreen()),
          ),
        );

        // Tap the clear database button
        await tester.tap(find.text('Clear'));
        await tester.pumpAndSettle();

        // Verify confirmation dialog appears
        expect(find.text('Clear Database'), findsAtLeastNWidgets(2));
        expect(find.text('Cancel'), findsOneWidget);

        // Test cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Should return to settings screen
        expect(find.text('Settings'), findsOneWidget);
      },
    );

    testWidgets('should handle clear database cancellation', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
            ChangeNotifierProvider<TrayProvider>.value(value: trayProvider),
          ],
          child: const CupertinoApp(home: SettingsScreen()),
        ),
      );

      // Tap clear database
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Tap cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should return to settings screen
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Clear Database'), findsOneWidget);
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
          ChangeNotifierProvider<TrayProvider>.value(value: trayProvider),
        ],
        child: const CupertinoApp(home: SettingsScreen()),
      );
    }

    // The full "confirm -> recreate database" path is deliberately not
    // exercised here: past the confirmation dialog it reaches for the real
    // `AppDatabase.instance` singleton and `getApplicationDocumentsDirectory()`
    // as a fallback, which would leave a genuine (if empty) database file
    // behind and risks flaking under this environment's plugin-less
    // `path_provider`. The confirm/cancel dialog tests above already cover
    // `_showClearDatabaseDialog`'s own branches.

    group('tray / system tray section', () {
      // `flutter_test` pins `defaultTargetPlatform` to a fixed default for
      // deterministic cross-host results - it is NOT the host OS - so the
      // section (rendered only for macOS/Windows/Linux) needs an explicit
      // override to appear at all. It has to be set and reset synchronously
      // within each test body: flutter_test asserts no `debug*` foundation
      // variable is left set as soon as the test callback's future
      // completes, which is before any `addTearDown` callback would run
      // (matches the pattern in compact_layout_test.dart).
      testWidgets('renders the platform-appropriate header and labels', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(createTestApp());

          expect(find.text('SYSTEM TRAY'), findsOneWidget);
          expect(find.text('Minimize to System Tray'), findsOneWidget);
          expect(find.text('Show in Dock'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('renders the macOS-flavoured header and labels', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        try {
          await tester.pumpWidget(createTestApp());

          expect(find.text('MENU BAR'), findsOneWidget);
          expect(find.text('Minimize to Menu Bar'), findsOneWidget);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('toggling Minimize to Tray updates the provider', (
        tester,
      ) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(createTestApp());
          expect(trayProvider.minimizeToTray, isTrue);

          // "Minimize to System Tray" is the first switch in the section.
          await tester.tap(find.byType(CupertinoSwitch).first);
          await tester.pump();

          expect(trayProvider.minimizeToTray, isFalse);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });

      testWidgets('toggling Show in Dock updates the provider without '
          'throwing', (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        try {
          await tester.pumpWidget(createTestApp());
          expect(trayProvider.showInDock, isTrue);

          await tester.tap(find.byType(CupertinoSwitch).at(1));
          await tester.pump();

          expect(trayProvider.showInDock, isFalse);
          expect(tester.takeException(), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      });
    });

    group('security section - session lock/unlock', () {
      testWidgets('starts locked and shows Unlock Session', (tester) async {
        await tester.pumpWidget(createTestApp());

        expect(find.text('Unlock Session'), findsOneWidget);
      });

      testWidgets('unlocking succeeds without biometrics available in this '
          'environment and flips the button to Lock Session', (tester) async {
        await tester.pumpWidget(createTestApp());

        // `SecureStorageService.authenticate` reaches out to `local_auth`,
        // which has no platform implementation registered here - it falls
        // back to treating biometrics as unavailable and allows access,
        // marking the session authenticated. That round trip is real
        // asynchronous work, so both the tap and the wait for its result
        // need to step outside the FakeAsync zone.
        await runRealAsync(tester, () async {
          await tester.tap(find.text('Unlock Session'));
        });
        await pumpUntilAsync(
          tester,
          () => find.text('Session Unlocked').evaluate().isNotEmpty,
        );

        expect(find.text('Session Unlocked'), findsOneWidget);
        await tester.tap(find.widgetWithText(CupertinoDialogAction, 'OK'));
        await tester.pump();

        expect(find.text('Lock Session'), findsOneWidget);
        expect(AuthenticationSessionService.instance.isSessionValid, isTrue);

        // `markAuthenticated()` started a 30-minute session `Timer` inside
        // this test's `FakeAsync` zone; cancel it before the test body
        // returns; a `Timer` still pending once the zone is torn down trips
        // flutter_test's own "pending timers" assertion (this runs before
        // `tearDown`, so invalidating there would be too late).
        AuthenticationSessionService.instance.invalidateSession();
      });

      testWidgets('locking an unlocked session shows Session Locked and '
          'reverts the button', (tester) async {
        AuthenticationSessionService.instance.markAuthenticated();

        await tester.pumpWidget(createTestApp());
        expect(find.text('Lock Session'), findsOneWidget);

        await tester.tap(find.text('Lock Session'));
        await tester.pump();

        expect(find.text('Session Locked'), findsOneWidget);
        expect(AuthenticationSessionService.instance.isSessionValid, isFalse);

        await tester.tap(find.widgetWithText(CupertinoDialogAction, 'OK'));
        await tester.pump();

        expect(find.text('Unlock Session'), findsOneWidget);
      });
    });
  });
}
