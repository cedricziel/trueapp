import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/sqlite_server_repository.dart';

import '../helpers/test_database.dart';

void main() {
  test('keeps working after the holder swaps its database', () async {
    final holder = AppDatabaseHolder(open: createTestDatabase);
    final repository = SqliteServerRepository(holder);
    addTearDown(repository.dispose);
    await repository.getAllServers();

    await holder.dispose();

    expect(await repository.getAllServers(), isEmpty);
    final server = NasServer.create(
      name: 'Home',
      host: '192.168.1.10',
      username: 'admin',
      password: 'pw',
    );
    expect(await repository.saveServer(server), isTrue);
    expect(await repository.getServer(server.id), isNotNull);
  });
}
