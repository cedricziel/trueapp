import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

/// A [FakeApiClient] whose directory listing fails the way the real client
/// fails: with a classified [ConnectionException], not a bare [Exception].
class _ClassifiedFailureClient extends FakeApiClient {
  ConnectionError failure = ConnectionError.permissionDenied(
    details: 'Not authorized',
  );

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    calls.add('getDirectoryListing');
    throw ConnectionException(failure);
  }
}

void main() {
  late AppDatabase database;
  late UnifiedServerService service;
  late FileProvider provider;
  late FakeTelemetryService telemetryService;
  late NasServer testServer;

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
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    service = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    telemetryService = FakeTelemetryService();
    provider = FileProvider(service, telemetryService: telemetryService);

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );

    await service.saveServerConfig(server: testServer, password: 'password');
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [provider],
      service: service,
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

  group('FileProvider - setApiClient', () {
    test('swallows a getClient failure and reports it to telemetry', () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await provider.setApiClient(testServer);

      expect(provider.files, isEmpty);
      expect(telemetryService.recordedErrors, hasLength(1));
      expect(
        telemetryService.recordedErrors.single.context,
        'FileProvider.setApiClient',
      );
    });
  });

  group('FileProvider - loadFiles', () {
    test('a classified failure from the client is surfaced as-is and '
        'reported to telemetry', () async {
      final client = _ClassifiedFailureClient();
      TestProviders.mockApiClientManager.addMockClient(testServer.id, client);
      await provider.setApiClient(testServer);

      await provider.loadFiles('/mnt/tank');

      expect(
        provider.connectionError?.type,
        ConnectionErrorType.permissionDenied,
      );
      expect(provider.error, 'Permission denied');
      expect(telemetryService.recordedErrors, hasLength(1));
      expect(
        telemetryService.recordedErrors.single.context,
        'FileProvider.loadFiles',
      );
    });

    test(
      'an unexpected failure is wrapped and reported to telemetry',
      () async {
        final client = FakeApiClient();
        client.failingMethods.add('getDirectoryListing');
        TestProviders.mockApiClientManager.addMockClient(testServer.id, client);
        await provider.setApiClient(testServer);

        await provider.loadFiles('/mnt/tank');

        expect(provider.connectionError, isNotNull);
        expect(provider.error, isNotNull);
        expect(telemetryService.recordedErrors, hasLength(1));
        expect(
          telemetryService.recordedErrors.single.context,
          'FileProvider.loadFiles',
        );
      },
    );
  });
}
