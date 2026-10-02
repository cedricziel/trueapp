import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/server_auth_session.dart';
import 'package:truehub/services/unified_server_service.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late AppDatabase database;
  late UnifiedServerService serverService;
  late ServerAuthSession session;
  late FakeApiClient fakeClient;
  late FakeTelemetryService telemetry;
  late NasServer testServer;

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();

    database = createTestDatabase();
    serverService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    telemetry = FakeTelemetryService();
    session = ServerAuthSession(
      credentials: serverService,
      clientManager: TestProviders.mockApiClientManager,
      telemetry: telemetry,
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
    session.dispose();
    await fakeClient.dispose();
    await serverService.dispose();
    await TestProviders.cleanupTestEnvironment();
  });

  test('starts unauthenticated without a server', () {
    expect(session.status.state, AuthenticationState.none);
    expect(session.server, isNull);
    expect(session.client, isNull);
  });

  test('connect authenticates and publishes each transition', () async {
    final states = <AuthenticationState>[];
    session.stream.listen((status) => states.add(status.state));

    await session.connect(testServer);
    await Future<void>.delayed(Duration.zero);

    expect(states, [
      AuthenticationState.authenticating,
      AuthenticationState.authenticated,
    ]);
    expect(session.status.server?.id, testServer.id);
    expect(session.client, same(fakeClient));
  });

  test('connect requires authentication when no password is stored', () async {
    final orphan = NasServer.create(
      name: 'Orphan',
      host: '192.168.1.101',
      username: 'admin',
      password: '',
    );

    await session.connect(orphan);

    expect(session.status.requiresAuthentication, isTrue);
    expect(session.status.error, isNotNull);
    expect(session.client, isNull);
  });

  test(
    'connect fails and reports telemetry when the connection throws',
    () async {
      TestProviders.mockApiClientManager.shouldFailConnection = true;

      await session.connect(testServer);

      expect(session.status.hasFailed, isTrue);
      expect(telemetry.recordedErrors, hasLength(1));
      expect(
        telemetry.recordedErrors.single.context,
        'ServerAuthSession._authenticate',
      );
    },
  );

  test('connect releases the previous server\'s client', () async {
    await session.connect(testServer);
    TestProviders.mockApiClientManager.methodCalls.clear();

    await session.connect(null);

    expect(
      TestProviders.mockApiClientManager.methodCalls,
      contains('releaseClient:${testServer.id}'),
    );
    expect(session.status.state, AuthenticationState.none);
    expect(session.server, isNull);
  });

  test('retry re-authenticates the selected server', () async {
    TestProviders.mockApiClientManager.shouldFailConnection = true;
    await session.connect(testServer);
    expect(session.status.hasFailed, isTrue);

    TestProviders.mockApiClientManager.shouldFailConnection = false;
    await session.retry();

    expect(session.status.isAuthenticated, isTrue);
  });

  test('retry without a server does nothing', () async {
    await session.retry();

    expect(session.status.state, AuthenticationState.none);
  });

  test('disconnect publishes the cleared status', () async {
    await session.connect(testServer);
    final emitted = <AuthenticationStatus>[];
    session.stream.listen(emitted.add);

    await session.disconnect();
    await Future<void>.delayed(Duration.zero);

    expect(emitted.single.state, AuthenticationState.none);
    expect(emitted.single.server, isNull);
  });

  test(
    'reauthenticateWith recreates the client with fresh credentials',
    () async {
      await session.connect(testServer);
      session.reset();

      await session.reauthenticateWith(testServer);

      expect(session.status.isAuthenticated, isTrue);
      expect(
        TestProviders.mockApiClientManager.methodCalls,
        contains('forceRecreateClient:${testServer.id}'),
      );
    },
  );

  test(
    'reauthenticateWith a missing server leaves the session reset',
    () async {
      await session.connect(testServer);
      session.reset();

      await session.reauthenticateWith(null);

      expect(session.status.state, AuthenticationState.none);
    },
  );

  group('refreshConnection', () {
    test('is a no-op when nothing is connected', () async {
      await session.refreshConnection();

      expect(
        TestProviders.mockApiClientManager.methodCalls,
        isNot(contains('ensureAllConnectionsAlive')),
      );
    });

    test('keeps the session authenticated when the pool is alive', () async {
      await session.connect(testServer);

      await session.refreshConnection();

      expect(session.status.isAuthenticated, isTrue);
    });

    test(
      'marks the session failed when the server\'s connection is lost',
      () async {
        await session.connect(testServer);
        TestProviders.mockApiClientManager.connectionFailures = {
          testServer.id: 'socket closed',
        };

        await session.refreshConnection();

        expect(session.status.hasFailed, isTrue);
        expect(session.status.error, 'Connection lost: socket closed');
      },
    );

    test('ignores a result that arrives after switching servers', () async {
      await session.connect(testServer);
      TestProviders.mockApiClientManager.connectionFailures = {
        testServer.id: 'socket closed',
      };

      final pending = session.refreshConnection();
      session.clearServer();
      await pending;

      expect(session.status.state, AuthenticationState.none);
    });
  });

  test('dispose releases the client and closes the stream', () async {
    final scoped = ServerAuthSession(
      credentials: serverService,
      clientManager: TestProviders.mockApiClientManager,
    );
    await scoped.connect(testServer);
    final done = scoped.stream.isEmpty;
    TestProviders.mockApiClientManager.methodCalls.clear();

    scoped.dispose();

    expect(
      TestProviders.mockApiClientManager.methodCalls,
      contains('releaseClient:${testServer.id}'),
    );
    expect(await done, isTrue);
  });

  group('replaceServer', () {
    test('swaps in the refreshed copy of the selected server', () async {
      await session.connect(testServer);

      session.replaceServer(testServer.copyWith(name: 'Renamed'));

      expect(session.server?.name, 'Renamed');
    });

    test('ignores a refresh of a server that is no longer selected', () async {
      final other = NasServer.create(
        name: 'Other',
        host: '192.168.1.102',
        username: 'admin',
        password: 'password',
      );
      await serverService.saveServerConfig(server: other, password: 'password');
      TestProviders.mockApiClientManager.addMockClient(
        other.id,
        FakeApiClient(),
      );
      await session.connect(testServer);
      await session.connect(other);

      session.replaceServer(testServer.copyWith(name: 'Stale'));

      expect(session.server?.id, other.id);
      expect(session.client, isNotNull);
    });
  });
}
