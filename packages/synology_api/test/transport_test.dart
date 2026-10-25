import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synology_api/synology_api.dart';
import 'package:synology_api/testing.dart';
import 'package:test/test.dart';

void main() {
  const request = SynologyRequest(
    path: 'entry.cgi',
    api: 'SYNO.DSM.Info',
    version: 2,
    method: 'getinfo',
  );

  HttpSynologyTransport answering(int status, String body) =>
      HttpSynologyTransport(
        Uri.parse('https://nas.test:5001'),
        client: MockClient((_) async => http.Response(body, status)),
      );

  test('posts form fields so credentials stay out of the URL', () async {
    late http.Request sent;
    final transport = HttpSynologyTransport(
      Uri.parse('https://nas.test:5001'),
      client: MockClient((r) async {
        sent = r;
        return http.Response('{"success":true,"data":{}}', 200);
      }),
    );

    await transport.send(
      const SynologyRequest(
        path: 'entry.cgi',
        api: 'SYNO.API.Auth',
        version: 7,
        method: 'login',
        params: {'passwd': 'secret'},
        synoToken: 'token',
      ),
    );

    expect(sent.method, 'POST');
    expect(sent.url.toString(), 'https://nas.test:5001/webapi/entry.cgi');
    expect(sent.bodyFields['passwd'], 'secret');
    expect(sent.headers['X-SYNO-TOKEN'], 'token');
  });

  test('treats a success without data as empty', () async {
    expect(await answering(200, '{"success":true}').send(request), isEmpty);
  });

  test(
    'reports non-200 responses, non-JSON bodies and odd envelopes',
    () async {
      for (final (status, body) in [
        (502, ''),
        (200, '<html>'),
        (200, '{"ok":1}'),
      ]) {
        await expectLater(
          answering(status, body).send(request),
          throwsA(isA<SynologyProtocolException>()),
        );
      }
    },
  );

  test('talks to the fake over a real socket', () async {
    final server = await FakeSynologyNas.dsm7().serve();
    addTearDown(server.close);
    final client = SynologyClient(
      HttpSynologyTransport(Uri.parse('http://127.0.0.1:${server.port}')),
    );

    final session = await client.login('admin', 'secret');
    final info = await client.dsmInfo();

    expect(session.synoToken, isNotNull);
    expect(info.version!.major, 7);
    expect(info.uptime, const Duration(hours: 1));
  });
}
