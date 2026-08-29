import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart' as models;

import 'test_database.dart';

void main() {
  group('createTestDatabase', () {
    test(
      'returns a usable AppDatabase backed by its own in-memory store',
      () async {
        final database = createTestDatabase();

        final servers = await database.getAllServers();
        expect(servers, isEmpty);
      },
    );

    test('gives each call an independent database', () async {
      final first = createTestDatabase();
      final second = createTestDatabase();

      await first.insertServer(
        models.NasServer.create(
          name: 'Only in first',
          host: 'first.example.com',
          port: null,
          username: 'admin',
          password: 'password',
          useHttps: true,
        ),
      );

      expect((await first.getAllServers()).length, 1);
      expect((await second.getAllServers()), isEmpty);
    });
  });
}
