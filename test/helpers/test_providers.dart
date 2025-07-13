import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;

class TestProviders {
  /// Creates a real UnifiedServerService with SQLite repository and mock keychain
  /// for testing that requires actual database persistence
  ///
  /// IMPORTANT: Always provide a database parameter to avoid creating multiple database instances
  /// which can cause race conditions. Each test should create its own database in setUp().
  static Future<UnifiedServerService> createMockUnifiedServerService({
    required AppDatabase database,
  }) async {
    // Create real service with SQLite repository and mock keychain
    final sqliteRepository = SqliteServerRepository(database);
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
    required AppDatabase database,
  }) async {
    final service = await createMockUnifiedServerService(database: database);
    return ServerProvider(service);
  }
}
