import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_client_session.dart';
import 'package:truehub/services/server_credentials_lookup.dart';

import '../helpers/fake_api_client.dart';
import '../helpers/fake_telemetry_service.dart';
import '../helpers/mock_api_client_manager.dart';

class _FakeCredentials implements ServerCredentialsLookup {
  final Map<String, String> passwords = {};
  final Map<String, Completer<void>> gates = {};

  @override
  Future<String?> getPassword(String serverId) async {
    await gates[serverId]?.future;
    return passwords[serverId];
  }
}

NasServer _server(String id) => NasServer(
  id: id,
  name: 'Server $id',
  host: '$id.example.com',
  username: 'admin',
  password: '',
  isDefault: false,
  trustedWifiSsids: const [],
);

void main() {
  late MockApiClientManager manager;
  late _FakeCredentials credentials;
  late FakeTelemetryService telemetry;
  late ServerClientSession session;

  setUp(() {
    manager = MockApiClientManager();
    credentials = _FakeCredentials()
      ..passwords['a'] = 'pw-a'
      ..passwords['b'] = 'pw-b';
    telemetry = FakeTelemetryService();
    session = ServerClientSession(
      owner: 'TestOwner',
      clientManager: manager,
      credentials: credentials,
      telemetry: telemetry,
    );
  });

  test('checks out a client for the server it connects to', () async {
    final client = FakeApiClient();
    manager.addMockClient('a', client);

    expect(await session.connect(_server('a')), isTrue);

    expect(session.client, same(client));
    expect(session.serverId, 'a');
  });

  test('releases the previous client when switching servers', () async {
    manager.addMockClient('a', FakeApiClient());
    manager.addMockClient('b', FakeApiClient());

    await session.connect(_server('a'));
    await session.connect(_server('b'));

    expect(manager.wasMethodCalled('releaseClient:a'), isTrue);
    expect(session.serverId, 'b');
  });

  test('stays clientless when no password is stored', () async {
    manager.addMockClient('c', FakeApiClient());

    expect(await session.connect(_server('c')), isTrue);

    expect(session.client, isNull);
    expect(session.serverId, 'c');
    expect(manager.wasMethodCalled('getClient:c'), isFalse);
  });

  test('records a connection failure without throwing', () async {
    manager.shouldFailConnection = true;

    expect(await session.connect(_server('a')), isTrue);

    expect(session.client, isNull);
    expect(telemetry.recordedErrors.single.context, 'TestOwner.connect');
  });

  test('a slower earlier connect never overwrites a newer one', () async {
    manager.addMockClient('a', FakeApiClient());
    final clientB = FakeApiClient();
    manager.addMockClient('b', clientB);
    final gate = credentials.gates['a'] = Completer<void>();

    final first = session.connect(_server('a'));
    final second = session.connect(_server('b'));
    expect(await second, isTrue);
    gate.complete();

    expect(await first, isFalse);
    expect(session.client, same(clientB));
    expect(session.serverId, 'b');
    expect(manager.wasMethodCalled('getClient:a'), isFalse);
  });

  test('disconnect releases the client and forgets the server', () async {
    manager.addMockClient('a', FakeApiClient());
    await session.connect(_server('a'));

    await session.disconnect();

    expect(session.client, isNull);
    expect(session.serverId, isNull);
    expect(manager.wasMethodCalled('releaseClient:a'), isTrue);
  });

  test('dispose releases the client', () async {
    manager.addMockClient('a', FakeApiClient());
    await session.connect(_server('a'));

    session.dispose();
    await Future<void>.delayed(Duration.zero);

    expect(manager.wasMethodCalled('releaseClient:a'), isTrue);
    expect(session.client, isNull);
  });
}
