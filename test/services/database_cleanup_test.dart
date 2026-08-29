// Tests for [DatabaseCleanup.removeServersWithoutPasswords]
// (lib/services/database_cleanup.dart).
//
// The other two DatabaseCleanup methods (cleanupAllKeychainEntries,
// completeCleanup) reach through NativeKeychainService.instance to the
// truenas_native_plugins platform channel and are intentionally left
// untested here - that's platform-plugin territory, out of scope for a
// database-layer test file, and not exercisable against a plain
// createTestDatabase().

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/services/database_cleanup.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart';

import '../helpers/test_database.dart';

void main() {
  group('DatabaseCleanup.removeServersWithoutPasswords', () {
    test('does nothing on an empty database', () async {
      final database = createTestDatabase();
      final keychain = MockKeychainService();

      await DatabaseCleanup.removeServersWithoutPasswords(
        database,
        keychain: keychain,
      );

      expect(await database.getAllServers(), isEmpty);
    });

    test('keeps servers with a keychain password and removes servers without '
        'one, checking the keychain rather than the never-persisted DB '
        'password column', () async {
      final database = createTestDatabase();
      final keychain = MockKeychainService();
      final withPassword = models.NasServer.create(
        name: 'Has Password',
        host: 'a.example.com',
        port: null,
        username: 'admin',
        password: '',
      );
      final withoutPassword = models.NasServer.create(
        name: 'No Password',
        host: 'b.example.com',
        port: null,
        username: 'admin',
        password: '',
      );
      await database.insertServer(withPassword);
      await database.insertServer(withoutPassword);
      keychain.addPassword(withPassword.id, 'super-secret');

      await DatabaseCleanup.removeServersWithoutPasswords(
        database,
        keychain: keychain,
      );

      final remaining = await database.getAllServers();
      expect(remaining, hasLength(1));
      expect(remaining.single.id, withPassword.id);
    });
  });
}
