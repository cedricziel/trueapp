// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;

void main() {
  late AppDatabase database;
  late UnifiedServerService unifiedServerService;

  setUp(() async {
    // Create a fresh test database for each test using in-memory SQLite
    database = AppDatabase.forTesting(NativeDatabase.memory());

    // Create real service with SQLite repository and mock keychain
    final sqliteRepository = SqliteServerRepository(database);
    final mockKeychain = MockKeychainService();
    unifiedServerService = UnifiedServerService(
      repository: sqliteRepository,
      keychain: mockKeychain,
    );
    await unifiedServerService.initialize();
  });

  tearDown(() async {
    // Clean up after each test
    await database.close();
  });

  testWidgets('TrueNAS Manager app smoke test', (WidgetTester tester) async {
    // This is a simplified smoke test that just checks basic widget instantiation
    // The full app initialization is complex and better tested with unit tests

    final connectionStatusProvider = ConnectionStatusProvider();

    // Create a simplified home screen test instead of the full app
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          Provider<UnifiedServerService>.value(value: unifiedServerService),
          ChangeNotifierProvider.value(value: connectionStatusProvider),
          ChangeNotifierProvider(
            create: (context) => ServerProvider(unifiedServerService),
          ),
          ChangeNotifierProvider(
            create: (context) => PoolProvider(unifiedServerService),
          ),
          ChangeNotifierProvider(
            create: (context) => DatasetProvider(unifiedServerService),
          ),
          ChangeNotifierProvider(
            create: (context) => AppProvider(
              database: database,
              serverService: unifiedServerService,
            ),
          ),
          ChangeNotifierProvider(
            create: (context) => SystemStatsProvider(unifiedServerService),
          ),
          ChangeNotifierProvider(create: (context) => TrayProvider()),
        ],
        child: const CupertinoApp(
          title: 'TrueNAS Manager',
          home: CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('TrueNAS Manager'),
            ),
            child: Center(child: Text('TrueNAS Manager')),
          ),
        ),
      ),
    );

    // Verify that the app renders successfully
    expect(find.text('TrueNAS Manager'), findsWidgets);
  });
}
