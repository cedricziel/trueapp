import 'dart:async';

import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/sqlite_server_repository.dart';
import 'package:flutter/foundation.dart';
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

  /// Tears down the full test stack in the correct order.
  ///
  /// The order matters: static state first, then the provider, then the
  /// service, and only afterwards the database.
  ///
  /// [AppDatabase.close] is guarded by [timeout] on purpose. When a widget test
  /// fails part way through, drift queries that were started inside the test's
  /// `FakeAsync` zone can never complete, and `close()` then waits for them
  /// forever. Without the guard a single failing test wedges every remaining
  /// test in the same file, which is exactly how a CI run turns into a one-hour
  /// timeout instead of a readable failure.
  static Future<void> disposeTestStack({
    ChangeNotifier? provider,
    UnifiedServerService? service,
    AppDatabase? database,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await _ignoringErrors(cleanupTestEnvironment);
    await _ignoringErrors(() async => provider?.dispose());
    await _ignoringErrors(() async => service?.dispose());

    if (database != null) {
      await _ignoringErrors(() => database.close().timeout(timeout));
    }
  }

  static Future<void> _ignoringErrors(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // Teardown is best effort: a failure here must never mask the actual
      // test failure, and must never stop the remaining teardown steps.
    }
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
