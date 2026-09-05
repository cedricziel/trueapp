import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/services/database.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late FileProvider provider;

  FileItem file(String name, {bool isDirectory = false}) {
    return FileItem(
      name: name,
      path: '/$name',
      isDirectory: isDirectory,
      size: 1024,
      modifiedTime: DateTime(2026, 1, 1),
      permissions: '644',
      owner: 'root',
      group: 'wheel',
    );
  }

  setUp(() async {
    database = createTestDatabase();
    final service = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    provider = FileProvider(service);
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [provider],
      database: database,
    );
  });

  group('FileProvider', () {
    test('starts empty, at the root, and not loading', () {
      expect(provider.files, isEmpty);
      expect(provider.currentPath, '/');
      expect(provider.isLoading, isFalse);
      expect(provider.searchQuery, isEmpty);
    });

    test('filteredFiles returns every file when the query is empty', () {
      provider.debugSetFiles([
        file('movies', isDirectory: true),
        file('notes.txt'),
      ]);

      expect(provider.filteredFiles, hasLength(2));
    });

    test('filteredFiles matches by name, case-insensitively', () {
      provider.debugSetFiles([
        file('Interstellar.mkv'),
        file('notes.txt'),
        file('Documentary.mkv'),
      ]);

      provider.setSearchQuery('doc');

      expect(provider.filteredFiles.map((f) => f.name), ['Documentary.mkv']);
    });

    test('setSearchQuery notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setSearchQuery('anything');

      expect(notified, isTrue);
      expect(provider.searchQuery, 'anything');
    });

    test('navigateUp is a no-op at the root', () async {
      await provider.navigateUp();

      expect(provider.currentPath, '/');
    });
  });
}
