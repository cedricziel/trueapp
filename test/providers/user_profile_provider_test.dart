import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/providers/user_profile_provider.dart';
import 'package:truehub/services/active_server.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late UserProfileProvider provider;
  late FakeApiClient fakeClient;
  late FakeTelemetryService telemetryService;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    telemetryService = FakeTelemetryService();
    provider = UserProfileProvider(
      serverService,
      clientManager: TestProviders.mockApiClientManager,
      telemetryService: telemetryService,
    );
    fakeClient = FakeApiClient();

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      username: 'admin',
      password: 'password',
    );
    await serverService.saveServerConfig(
      server: testServer,
      password: 'password',
    );
    TestProviders.mockApiClientManager.addMockClient(testServer.id, fakeClient);
  });

  tearDown(() async {
    provider.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  test('starts empty and not loading', () {
    expect(provider.currentUser, isNull);
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('loadCurrentUser without a server is a no-op', () async {
    await provider.loadCurrentUser();

    expect(provider.currentUser, isNull);
    expect(provider.isLoading, isFalse);
    expect(fakeClient.calls, isNot(contains('getCurrentUser')));
  });

  test('loadCurrentUser fetches the user of the selected server', () async {
    fakeClient.currentUser = const UserInfo(
      username: 'jdoe',
      fullName: 'Jane Doe',
      homeDirectory: '/home/jdoe',
      shell: '/bin/zsh',
      uid: 1000,
      gid: 1000,
      source: 'LOCAL',
      isLocal: true,
      groupList: [],
      attributes: {},
      hasTwoFactor: false,
      privilege: {},
    );

    await provider.setServer(testServer);
    await provider.loadCurrentUser();

    expect(provider.currentUser?.username, 'jdoe');
    expect(provider.isLoading, isFalse);
    expect(provider.error, isNull);
  });

  test('setServer drops the previous server\'s user', () async {
    await provider.setServer(testServer);
    await provider.loadCurrentUser();
    expect(provider.currentUser, isNotNull);

    await provider.setServer(testServer);

    expect(provider.currentUser, isNull);
  });

  test('a failure is exposed and reported to telemetry', () async {
    fakeClient.failingMethods.add('getCurrentUser');
    await provider.setServer(testServer);
    telemetryService.recordedErrors.clear();

    await provider.loadCurrentUser();

    expect(provider.error, isNotNull);
    expect(provider.currentUser, isNull);
    expect(provider.isLoading, isFalse);
    expect(telemetryService.recordedErrors, hasLength(1));
    expect(
      telemetryService.recordedErrors.single.context,
      'UserProfileProvider.loadCurrentUser',
    );
  });

  test('a successful retry clears the previous error', () async {
    fakeClient.failingMethods.add('getCurrentUser');
    await provider.setServer(testServer);
    await provider.loadCurrentUser();
    expect(provider.error, isNotNull);

    fakeClient.failingMethods.remove('getCurrentUser');
    await provider.loadCurrentUser();

    expect(provider.error, isNull);
    expect(provider.currentUser, isNotNull);
  });

  test(
    'a result for a server that was switched away from is discarded',
    () async {
      final completer = Completer<UserInfo>();
      TestProviders.mockApiClientManager.addMockClient(
        testServer.id,
        _SlowApiClient(completer),
      );
      await provider.setServer(testServer);

      final pending = provider.loadCurrentUser();
      await provider.setServer(testServer);
      completer.complete(fakeClient.currentUser);
      await pending;

      expect(provider.currentUser, isNull);
    },
  );

  test('follows the active server', () async {
    final active = ActiveServer(testServer);
    final following = UserProfileProvider(
      serverService,
      clientManager: TestProviders.mockApiClientManager,
      activeServer: active.listenable,
    );
    addTearDown(following.dispose);

    await following.loadCurrentUser();

    expect(following.currentUser, isNotNull);
  });
}

class _SlowApiClient extends FakeApiClient {
  _SlowApiClient(this._completer);

  final Completer<UserInfo> _completer;

  @override
  Future<UserInfo> getCurrentUser() async {
    calls.add('getCurrentUser');
    return _completer.future;
  }
}
