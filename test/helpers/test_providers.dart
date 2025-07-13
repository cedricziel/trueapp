import 'package:drift/native.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;

class TestProviders {
  /// Creates a real UnifiedServerService with SQLite repository and mock keychain
  /// for testing that requires actual database persistence
  static Future<UnifiedServerService> createMockUnifiedServerService({
    AppDatabase? database,
  }) async {
    // Use provided database or create a new in-memory one
    final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());

    // Create real service with SQLite repository and mock keychain
    final sqliteRepository = SqliteServerRepository(db);
    final mockKeychain = MockKeychainService();
    final service = UnifiedServerService(
      repository: sqliteRepository,
      keychain: mockKeychain,
    );

    await service.initialize();
    return service;
  }

  /// Creates a ServerProvider with a mock unified server service
  static Future<ServerProvider> createServerProvider({
    AppDatabase? database,
  }) async {
    final service = await createMockUnifiedServerService(database: database);
    return ServerProvider(service);
  }
}
