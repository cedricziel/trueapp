import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/database/database_file_remover.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/test_database.dart';
import '../helpers/fake_tray_host.dart';
import '../helpers/test_providers.dart';

class _RecordingDatabaseFileRemover implements DatabaseFileRemover {
  _RecordingDatabaseFileRemover({this.fail = false});

  final bool fail;
  int removals = 0;

  @override
  Future<void> removeDatabaseFiles() async {
    removals++;
    if (fail) throw const FileSystemException('cannot delete');
  }
}

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
      serverProvider = await TestProviders.createSettledServerProvider(
        unifiedServerService,
      );
      trayProvider = TrayProvider(trayService: fakeTrayService());

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, (call) async => null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(windowChannel, null);
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

    Future<int> confirmClearDatabase(
      WidgetTester tester,
      DatabaseFileRemover databaseFiles,
    ) async {
      var opened = 0;
      final holder = AppDatabaseHolder(
        open: () {
          opened++;
          return createTestDatabase();
        },
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerProvider>.value(value: serverProvider),
            ChangeNotifierProvider<TrayProvider>.value(value: trayProvider),
            Provider<AppDatabaseHolder>.value(value: holder),
            Provider<UnifiedServerService>.value(value: unifiedServerService),
          ],
          child: CupertinoApp(
            home: SettingsScreen(databaseFiles: databaseFiles),
          ),
        ),
      );

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(CupertinoDialogAction, 'Clear Database'),
      );
      final result = find.text('Database Recreated');
      final failure = find.text('Error');
      for (var i = 0; i < 100; i++) {
        if (result.evaluate().isNotEmpty || failure.evaluate().isNotEmpty) {
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      return opened;
    }

    testWidgets('confirming removes the database files without the table-drop '
        'fallback', (tester) async {
      final databaseFiles = _RecordingDatabaseFileRemover();

      final opened = await confirmClearDatabase(tester, databaseFiles);

      expect(find.text('Database Recreated'), findsOneWidget);
      expect(databaseFiles.removals, 1);
      expect(opened, 0);
    });

    testWidgets('falls back to dropping the table when the files cannot be '
        'removed', (tester) async {
      final databaseFiles = _RecordingDatabaseFileRemover(fail: true);

      final opened = await confirmClearDatabase(tester, databaseFiles);

      expect(find.text('Database Recreated'), findsOneWidget);
      expect(databaseFiles.removals, 1);
      expect(opened, 1);
    });

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
  });
}
