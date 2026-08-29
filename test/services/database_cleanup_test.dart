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

import '../helpers/test_database.dart';

void main() {
  group('DatabaseCleanup.removeServersWithoutPasswords', () {
    test('does nothing on an empty database', () async {
      final database = createTestDatabase();

      await DatabaseCleanup.removeServersWithoutPasswords(database);

      expect(await database.getAllServers(), isEmpty);
    });

    test('removes every server, because AppDatabase never persists passwords '
        '(they live only in the keychain) - so every server read back from '
        'getAllServers() has password == "" and looks passwordless to this '
        'check, regardless of what was passed to insertServer', () async {
      final database = createTestDatabase();
      final withPassword = models.NasServer.create(
        name: 'Has Password',
        host: 'a.example.com',
        port: null,
        username: 'admin',
        password: 'super-secret',
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

      await DatabaseCleanup.removeServersWithoutPasswords(database);

      expect(await database.getAllServers(), isEmpty);
    });
  });
}
