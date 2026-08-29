import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/server_repository_factory.dart';
import 'package:truehub/services/sqlite_server_repository.dart';

import '../helpers/test_database.dart';

void main() {
  group('ServerRepositoryFactory Unit Tests', () {
    setUp(() async {
      await ServerRepositoryFactory.reset();
    });

    tearDown(() async {
      await ServerRepositoryFactory.reset();
    });

    test('should detect CloudKit support correctly', () {
      final supportsCloudKit = ServerRepositoryFactory.supportsCloudKit;
      final expectedSupport = Platform.isIOS || Platform.isMacOS;

      expect(supportsCloudKit, equals(expectedSupport));
    });

    test('should provide singleton access pattern', () async {
      // Should throw before initialization
      expect(
        () => ServerRepositoryFactory.instance,
        throwsA(isA<StateError>()),
      );
    });

    test('should support factory reset', () async {
      await ServerRepositoryFactory.reset();

      // Should not throw
      expect(() => ServerRepositoryFactory.reset(), returnsNormally);
    });

    test('should detect platform correctly', () {
      // Test platform detection logic
      if (Platform.isIOS || Platform.isMacOS) {
        expect(ServerRepositoryFactory.supportsCloudKit, isTrue);
      } else {
        expect(ServerRepositoryFactory.supportsCloudKit, isFalse);
      }
    });
  });

  // This test VM always runs as Platform.isIOS == false and
  // Platform.isMacOS == false (it's Linux), so `create()`'s
  // `isApplePlatform` branch can never be exercised here - only the SQLite
  // path (default), the `forceCloudKit` fallback path, and the memoized
  // `_instance` short-circuit are reachable from a non-Apple test run.
  group('ServerRepositoryFactory.create - on a non-Apple platform', () {
    setUp(() async {
      await ServerRepositoryFactory.reset();
    });

    tearDown(() async {
      await ServerRepositoryFactory.reset();
    });

    test(
      'defaults to a SQLite repository and exposes it via instance',
      () async {
        final database = createTestDatabase();

        final repo = await ServerRepositoryFactory.create(database: database);

        expect(repo, isA<SqliteServerRepository>());
        expect(identical(ServerRepositoryFactory.instance, repo), isTrue);
      },
    );

    test(
      'a second call returns the memoized instance without reinitializing',
      () async {
        final database = createTestDatabase();

        final first = await ServerRepositoryFactory.create(database: database);
        final second = await ServerRepositoryFactory.create(
          database: createTestDatabase(),
          forceCloudKit: true, // ignored - _instance is already set
        );

        expect(identical(first, second), isTrue);
      },
    );

    test(
      'forceCloudKit falls back to SQLite once CloudKit fails to initialize',
      () async {
        final database = createTestDatabase();

        // CloudKitServerRepository.initialize() catches every failure and
        // returns false rather than throwing (there is no native CloudKit
        // channel on this platform), so `create()` should silently fall back
        // to SqliteServerRepository instead of surfacing an error.
        final repo = await ServerRepositoryFactory.create(
          database: database,
          forceCloudKit: true,
        );

        expect(repo, isA<SqliteServerRepository>());
        expect(identical(ServerRepositoryFactory.instance, repo), isTrue);
      },
    );

    test(
      'reset disposes the current repository and clears the singleton',
      () async {
        final database = createTestDatabase();
        await ServerRepositoryFactory.create(database: database);

        await ServerRepositoryFactory.reset();

        expect(
          () => ServerRepositoryFactory.instance,
          throwsA(isA<StateError>()),
        );
      },
    );
  });
}
