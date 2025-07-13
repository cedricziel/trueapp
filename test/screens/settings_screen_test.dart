import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/screens/settings_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:drift/native.dart';
import '../helpers/test_providers.dart';

void main() {
  group('Settings Screen Tests', () {
    late AppDatabase database;
    late ServerProvider serverProvider;
    late UnifiedServerService unifiedServerService;
    late TrayProvider trayProvider;

    setUp(() async {
      await TestProviders.cleanupTestEnvironment();
      TestProviders.setupTestEnvironment();
      database = AppDatabase.forTesting(NativeDatabase.memory());
      unifiedServerService = await TestProviders.createMockUnifiedServerService(
        database: database,
      );
      serverProvider = ServerProvider(unifiedServerService);
      trayProvider = TrayProvider();
    });

    tearDown(() async {
      await database.close();
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
  });
}
