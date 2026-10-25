import 'package:synology_api/synology_api.dart';
import 'package:synology_api/testing.dart';
import 'package:test/test.dart';

void main() {
  late FakeSynologyNas nas;
  late SynologyClient client;

  SynologyClient clientFor(FakeSynologyNas fake) => SynologyClient(
    HttpSynologyTransport(
      Uri.parse('https://nas.test:5001'),
      client: fake.client,
    ),
  );

  setUp(() {
    nas = FakeSynologyNas.dsm7();
    client = clientFor(nas);
  });

  Iterable<FakeCall> catalogQueries() =>
      nas.calls.where((c) => c.api == 'SYNO.API.Info');

  test('discovers the catalog once, even for concurrent callers', () async {
    final (catalog, _) = await (client.discover(), client.discover()).wait;
    await client.discover();

    expect(catalog.has('SYNO.Docker.Container'), isTrue);
    expect(catalogQueries(), hasLength(1));
  });

  test('retries discovery after a failed fetch', () async {
    nas.failNext('SYNO.API.Info', 110);

    await expectLater(client.discover(), throwsA(isA<SynologyApiException>()));
    await client.discover();
    expect(catalogQueries(), hasLength(1));
  });

  group('login', () {
    test('logs in with Auth v6 on the path the NAS advertises', () async {
      await client.login('admin', 'secret');

      final login = nas.calls.last;
      expect((login.path, login.version), ('entry.cgi', 6));

      final dsm6 = FakeSynologyNas.dsm6();
      await clientFor(dsm6).login('admin', 'secret');
      expect((dsm6.calls.last.path, dsm6.calls.last.version), ('auth.cgi', 6));
    });

    test('labels the session with the configured name', () async {
      await SynologyClient(
        HttpSynologyTransport(
          Uri.parse('https://nas.test:5001'),
          client: nas.client,
        ),
        sessionName: 'Probe',
      ).login('admin', 'secret');

      expect(nas.calls.last.params['session'], 'Probe');
    });

    test('attaches the session to later calls', () async {
      final session = await client.login('admin', 'secret');
      await client.dsmInfo();

      expect(nas.calls.last.params['_sid'], session.sid);
      expect(nas.calls.last.account, 'admin');
    });

    test('rejects a wrong password with the auth error text', () async {
      await expectLater(
        client.login('admin', 'wrong'),
        throwsA(
          isA<SynologyApiException>()
              .having((e) => e.code, 'code', 400)
              .having(
                (e) => e.message,
                'message',
                contains('incorrect password'),
              ),
        ),
      );
      expect(client.session, isNull);
    });

    test('asks for an OTP and then trusts the named device', () async {
      nas.otpCodes['admin'] = '123456';

      await expectLater(
        client.login('admin', 'secret'),
        throwsA(
          isA<SynologyOtpRequiredException>().having(
            (e) => e.code,
            'code',
            403,
          ),
        ),
      );
      await expectLater(
        client.login('admin', 'secret', otpCode: '000000'),
        throwsA(
          isA<SynologyOtpRequiredException>().having(
            (e) => e.code,
            'code',
            404,
          ),
        ),
      );

      final trusted = await client.login(
        'admin',
        'secret',
        otpCode: '123456',
        deviceName: 'TrueHub test',
      );
      expect(trusted.deviceId, isNotNull);

      final again = await clientFor(
        nas,
      ).login('admin', 'secret', deviceId: trusted.deviceId);
      expect(again.sid, isNot(trusted.sid));
    });
  });

  test('refuses authenticated calls before login', () async {
    expect(client.dsmInfo(), throwsStateError);
  });

  test('reports an API the NAS lacks without calling it', () async {
    final dsm6 = clientFor(FakeSynologyNas.dsm6());
    await dsm6.login('admin', 'secret');

    await expectLater(
      dsm6.call('SYNO.Docker.Container', 'list', minVersion: 1, maxVersion: 1),
      throwsA(isA<SynologyUnsupportedException>()),
    );
    await expectLater(
      dsm6.call('SYNO.Core.Package', 'list', minVersion: 3, maxVersion: 4),
      throwsA(
        isA<SynologyUnsupportedException>().having(
          (e) => e.message,
          'message',
          contains('v1-2 does not overlap'),
        ),
      ),
    );
  });

  test('flags an expired session', () async {
    await client.login('admin', 'secret');
    nas.expireSessions();

    await expectLater(
      client.dsmInfo(),
      throwsA(
        isA<SynologyApiException>().having(
          (e) => e.isSessionLost,
          'isSessionLost',
          isTrue,
        ),
      ),
    );
  });

  test('surfaces injected errors', () async {
    await client.login('admin', 'secret');
    nas.failNext('SYNO.DSM.Info', 105);

    await expectLater(
      client.dsmInfo(),
      throwsA(isA<SynologyApiException>().having((e) => e.code, 'code', 105)),
    );
    expect((await client.dsmInfo()).model, 'DS920+');
  });

  test('routes custom handlers with negotiated versions', () async {
    nas.on(
      'SYNO.Core.Package',
      'list',
      (call) => {'version': call.version, 'packages': []},
    );
    await client.login('admin', 'secret');

    final data = await client.call(
      'SYNO.Core.Package',
      'list',
      minVersion: 1,
      maxVersion: 5,
    );
    expect(data['version'], 2);
  });

  test('logout ends the session on both sides', () async {
    final session = await client.login('admin', 'secret');
    await client.logout();

    expect(client.session, isNull);
    expect(nas.calls.last.method, 'logout');
    expect(nas.calls.last.params['_sid'], session.sid);
    expect(client.dsmInfo(), throwsStateError);
  });

  group('capabilities', () {
    test('combine the catalog with the reported DSM version', () async {
      await client.login('admin', 'secret');
      final capabilities = await client.capabilities();

      expect(capabilities.dsmVersion, const DsmVersion(7, 2, 1, 69057, 5));
      expect(capabilities.supports(SynologyFeature.containers), isTrue);
    });

    test('hide what an older box does not offer', () async {
      final dsm6 = clientFor(FakeSynologyNas.dsm6());
      await dsm6.login('admin', 'secret');
      final capabilities = await dsm6.capabilities();

      expect(capabilities.dsmVersion!.major, 6);
      expect(capabilities.supports(SynologyFeature.containers), isFalse);
      expect(capabilities.supports(SynologyFeature.fileStation), isTrue);
    });
  });
}
