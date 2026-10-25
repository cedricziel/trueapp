import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:web_socket_channel/io.dart';

import 'fake_truenas_server.dart';

void main() {
  late FakeTrueNasServer server;
  late json_rpc.Peer client;

  Future<json_rpc.Peer> connect({void Function(json_rpc.Peer)? setup}) async {
    final socket = await WebSocket.connect(
      'ws://127.0.0.1:${server.port}/api/current',
    );
    final peer = json_rpc.Peer(IOWebSocketChannel(socket).cast<String>());
    setup?.call(peer);
    peer.listen();
    addTearDown(peer.close);
    return peer;
  }

  setUp(() async {
    server = await FakeTrueNasServer.start(otpCodes: {'otp': '123456'})
      ..accounts['otp'] = 'pw';
    addTearDown(server.stop);
    client = await connect();
  });

  test('checks credentials and OTP codes', () async {
    expect(await client.sendRequest('auth.login', ['root', 'wrong']), isFalse);
    expect(await client.sendRequest('auth.login', ['otp', 'pw']), isFalse);
    expect(
      await client.sendRequest('auth.login', ['otp', 'pw', '123456']),
      isTrue,
    );
  });

  test('refuses calls before login, except ping', () async {
    expect(await client.sendRequest('core.ping'), 'pong');
    await expectLater(
      client.sendRequest('auth.me'),
      throwsA(isA<json_rpc.RpcException>()),
    );

    await client.sendRequest('auth.login', ['root', 'password']);
    expect(
      await client.sendRequest('auth.me'),
      containsPair('pw_name', 'root'),
    );
  });

  test('applies handlers and failures to live connections', () async {
    await client.sendRequest('auth.login', ['root', 'password']);
    server
      ..onMethod('pool.query', (_) => ['tank'])
      ..failNext('pool.query', code: 22, message: 'busy');

    await expectLater(
      client.sendRequest('pool.query'),
      throwsA(isA<json_rpc.RpcException>().having((e) => e.code, 'code', 22)),
    );
    expect(await client.sendRequest('pool.query'), ['tank']);
    expect(server.successfulCalls('pool.query'), 1);
  });

  test('pushes collection updates', () async {
    final received = <Object?>[];
    final peer = await connect(
      setup: (peer) => peer.registerMethod(
        'collection_update',
        (json_rpc.Parameters p) => received.add(p.value),
      ),
    );
    await peer.sendRequest('core.ping');

    server.emit('alert.list', msg: 'ADDED', id: 'a1');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(received, [
      {'collection': 'alert.list', 'msg': 'ADDED', 'id': 'a1'},
    ]);
  });

  test('serves only /api/current', () async {
    await expectLater(
      WebSocket.connect('ws://127.0.0.1:${server.port}/websocket'),
      throwsA(isA<WebSocketException>()),
    );
  });
}
