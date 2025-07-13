import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart'
    show MockKeychainService;
import 'mock_api_client_manager.dart';

class TestProviders {
  static MockApiClientManager? _mockApiClientManager;

  /// Gets or creates the mock API client manager for testing
  static MockApiClientManager get mockApiClientManager {
    _mockApiClientManager ??= MockApiClientManager();
    return _mockApiClientManager!;
  }

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

  /// Sets up the test environment with mock implementations
  static void setupTestEnvironment() {
    // Set the mock API client manager
    ApiClientManager.setInstance(mockApiClientManager);
  }

  /// Cleans up all static state that might interfere with test isolation
  static Future<void> cleanupTestEnvironment() async {
    // Clear all cached API clients while mock is still active
    await ApiClientManager.clearAllForTesting();

    // Reset the mock API client manager
    if (_mockApiClientManager != null) {
      _mockApiClientManager!.reset();
    }

    // Reset to default implementation for next test
    ApiClientManager.setInstance(null);
    _mockApiClientManager = null;
  }
}
