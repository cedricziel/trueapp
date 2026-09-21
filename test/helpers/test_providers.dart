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
  /// Pass in a database each test built itself (e.g. via
  /// test/helpers/test_database.dart's `createTestDatabase`), so every test
  /// owns its own executor rather than sharing one across instances.
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
    return ServerProvider(service, databaseRef: () => database);
  }

  /// Builds a [ServerProvider] and waits, in real time, for its initial
  /// server load, and any auto-selection it triggers, to finish.
  ///
  /// The constructor fires a drift query without awaiting it. Left in flight
  /// when a widget test's fake-async body starts, that query can never
  /// complete, and `AppDatabase.close()` in teardown then blocks until its
  /// guard timeout expires - about five seconds per test.
  ///
  /// Throws a [TimeoutException] when the load does not finish in time, so a
  /// slow database fails loudly here instead of stalling teardown later.
  static Future<ServerProvider> createSettledServerProvider(
    UnifiedServerService service,
  ) async {
    final provider = ServerProvider(service);
    await _waitUntil(() => !provider.isLoadingServers, 'initial server load');
    await settlePendingLoads(provider);
    return provider;
  }

  /// Lets background work that [provider] started finish.
  ///
  /// Call it at the end of a `setUp` that mutates servers: a change makes
  /// [ServerProvider] reload and auto-select in the background, and work
  /// still in flight when the fake-async test body starts stalls
  /// `AppDatabase.close()` (see [createSettledServerProvider]).
  /// `isLoadingServers` clears before auto-selection starts, so this also
  /// waits for any authentication it kicks off.
  static Future<void> settlePendingLoads(ServerProvider provider) async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await _waitUntil(
      () => !provider.isLoadingServers && !provider.isAuthenticating,
      'pending server work',
    );
  }

  static Future<void> _waitUntil(
    bool Function() condition,
    String description,
  ) async {
    final deadline = DateTime.now().add(const Duration(seconds: 2));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Timed out waiting for $description');
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
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
  /// Every notifier the test created itself belongs in [providers]. Injecting
  /// one with `ChangeNotifierProvider.value` hands the widget tree a borrowed
  /// reference: the provider does not own it and never disposes it, so the
  /// test has to. Missing one leaks whatever it holds - a `PoolProvider`, for
  /// instance, keeps an API client checked out until `dispose` releases it.
  static Future<void> disposeTestStack({
    Iterable<ChangeNotifier> providers = const [],
    UnifiedServerService? service,
    AppDatabase? database,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await _ignoringErrors(cleanupTestEnvironment);
    for (final provider in providers) {
      await _ignoringErrors(() async => provider.dispose());
    }
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
