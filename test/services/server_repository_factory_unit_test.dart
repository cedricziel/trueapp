import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/cloudkit_server_repository.dart';
import 'package:truehub/services/server_repository_factory.dart';
import 'package:truehub/services/sqlite_server_repository.dart';

import '../helpers/mock_cloudkit_service_adapter.dart';
import '../helpers/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('supportsCloudKit matches the host platform', () {
    expect(
      ServerRepositoryFactory.supportsCloudKit,
      Platform.isIOS || Platform.isMacOS,
    );
  });

  group('ServerRepositoryFactory.create', () {
    late int cloudKitBuilt;

    ServerRepositoryFactory buildFactory({required bool isApplePlatform}) {
      cloudKitBuilt = 0;
      return ServerRepositoryFactory(
        serversDaoSource: createTestDatabase(),
        cloudKitServiceBuilder: () {
          cloudKitBuilt++;
          return MockCloudKitServiceAdapter();
        },
        isApplePlatform: isApplePlatform,
      );
    }

    test(
      'uses SQLite on a non-Apple platform without building CloudKit',
      () async {
        final repo = await buildFactory(isApplePlatform: false).create();

        expect(repo, isA<SqliteServerRepository>());
        expect(cloudKitBuilt, 0);
      },
    );

    test('uses CloudKit on an Apple platform', () async {
      final repo = await buildFactory(isApplePlatform: true).create();
      addTearDown(repo.dispose);

      expect(repo, isA<CloudKitServerRepository>());
      expect(cloudKitBuilt, 1);
    });

    test('forceSqlite overrides the Apple platform default', () async {
      final repo = await buildFactory(
        isApplePlatform: true,
      ).create(forceSqlite: true);

      expect(repo, isA<SqliteServerRepository>());
      expect(cloudKitBuilt, 0);
    });

    test('forceCloudKit selects CloudKit on a non-Apple platform', () async {
      final repo = await buildFactory(
        isApplePlatform: false,
      ).create(forceCloudKit: true);
      addTearDown(repo.dispose);

      expect(repo, isA<CloudKitServerRepository>());
    });

    test('falls back to SQLite once CloudKit fails to initialize', () async {
      final factory = ServerRepositoryFactory(
        serversDaoSource: createTestDatabase(),
        cloudKitServiceBuilder: () => _UnavailableCloudKitService(),
        isApplePlatform: true,
      );

      final repo = await factory.create();

      expect(repo, isA<SqliteServerRepository>());
    });
  });
}

class _UnavailableCloudKitService extends MockCloudKitServiceAdapter {
  @override
  Future<bool> initialize() async => false;
}
