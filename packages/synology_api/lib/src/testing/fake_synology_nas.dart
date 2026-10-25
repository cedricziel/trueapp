import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../api_catalog.dart';
import '../errors.dart';

/// Answers one API method. Return the `data` payload, or throw
/// [FakeSynologyError] to send an error envelope.
typedef FakeHandler = Map<String, dynamic> Function(FakeCall call);

/// A request the fake received, after the envelope was checked.
final class FakeCall {
  const FakeCall({
    required this.path,
    required this.api,
    required this.version,
    required this.method,
    required this.params,
    required this.account,
  });

  final String path;
  final String api;
  final int version;
  final String method;

  /// Form fields other than `api`, `version` and `method`.
  final Map<String, String> params;

  /// Account owning the request's session, null when unauthenticated.
  final String? account;
}

/// Thrown from a [FakeHandler] to answer with DSM error [code].
final class FakeSynologyError implements Exception {
  const FakeSynologyError(this.code);

  final int code;
}

/// In-process stand-in for a DSM box that speaks the Web API wire protocol:
/// catalog discovery, login with optional 2FA and trusted devices, session
/// checks, version range checks, and error envelopes.
///
/// Use [client] to plug it into an `HttpSynologyTransport` without sockets,
/// or [serve] to exercise a real HTTP stack.
///
/// Pass [apis] to model a box other than the [dsm6] and [dsm7] presets.
class FakeSynologyNas {
  FakeSynologyNas({
    Map<String, ApiInfo>? apis,
    this.versionString = 'DSM 7.2.1-69057 Update 5',
    this.model = 'DS920+',
    Map<String, String>? accounts,
    Map<String, String>? otpCodes,
  }) : apis = apis ?? dsm7Apis(),
       accounts = accounts ?? {'admin': 'secret'},
       otpCodes = otpCodes ?? {};

  factory FakeSynologyNas.dsm6({Map<String, String>? accounts}) =>
      FakeSynologyNas(
        apis: dsm6Apis(),
        versionString: 'DSM 6.2.4-25556 Update 7',
        model: 'DS918+',
        accounts: accounts,
      );

  factory FakeSynologyNas.dsm7({Map<String, String>? accounts}) =>
      FakeSynologyNas(accounts: accounts);

  /// Taken from a captured DSM 6.2 `SYNO.API.Info` dump, trimmed to the APIs
  /// this library knows about.
  static Map<String, ApiInfo> dsm6Apis() => _catalog({
    'SYNO.API.Info': ('query.cgi', 1, 1),
    authApi: ('auth.cgi', 1, 6),
    'SYNO.DSM.Info': ('entry.cgi', 2, 2),
    'SYNO.Core.System': ('entry.cgi', 1, 3),
    'SYNO.Core.System.Utilization': ('entry.cgi', 1, 1),
    'SYNO.Storage.CGI.Storage': ('entry.cgi', 1, 1),
    'SYNO.FileStation.List': ('entry.cgi', 1, 2),
    'SYNO.Core.Package': ('entry.cgi', 1, 2),
  });

  /// Taken from a captured DSM 7.0 `SYNO.API.Info` dump, with the Docker
  /// package installed. `SYNO.Docker.*` comes from that package, not DSM.
  static Map<String, ApiInfo> dsm7Apis() => _catalog({
    'SYNO.API.Info': ('query.cgi', 1, 1),
    authApi: ('entry.cgi', 1, 7),
    'SYNO.DSM.Info': ('entry.cgi', 2, 2),
    'SYNO.Core.System': ('entry.cgi', 1, 3),
    'SYNO.Core.System.Utilization': ('entry.cgi', 1, 1),
    'SYNO.Storage.CGI.Storage': ('entry.cgi', 1, 1),
    'SYNO.FileStation.List': ('entry.cgi', 1, 2),
    'SYNO.Core.Package': ('entry.cgi', 1, 2),
    'SYNO.Docker.Container': ('entry.cgi', 1, 1),
  });

  static Map<String, ApiInfo> _catalog(
    Map<String, (String, int, int)> entries,
  ) => {
    for (final MapEntry(key: name, value: (path, min, max)) in entries.entries)
      name: ApiInfo(name: name, path: path, minVersion: min, maxVersion: max),
  };

  final Map<String, ApiInfo> apis;
  final String versionString;
  final String model;

  /// Account name to password.
  final Map<String, String> accounts;

  /// Account name to the one-time code it must log in with.
  final Map<String, String> otpCodes;

  /// Every call that passed envelope checks, oldest first.
  final List<FakeCall> calls = [];

  final _handlers = <String, FakeHandler>{};
  final _failures = <String, List<int>>{};
  final _sessions = <String, _FakeSession>{};
  final _trustedDevices = <String, String>{};
  var _counter = 0;

  /// Serves [api].[method] with [handler]; [api] must be in [apis].
  void on(String api, String method, FakeHandler handler) {
    _handlers['$api.$method'] = handler;
  }

  /// Makes the next call to [api] fail with [code], once per call to this.
  void failNext(String api, int code) {
    (_failures[api] ??= []).add(code);
  }

  /// Drops every session, as a DSM restart or timeout would.
  void expireSessions() => _sessions.clear();

  /// An [http.Client] that answers from this fake without opening sockets.
  http.Client get client => MockClient((request) async {
    final (status, body) = _respond(
      request.url.path,
      request.bodyFields,
      request.headers['x-syno-token'],
    );
    return http.Response(
      body,
      status,
      headers: {'content-type': 'application/json'},
    );
  });

  /// Listens on an ephemeral loopback port until the server is closed.
  Future<HttpServer> serve() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final body = await utf8.decodeStream(request);
      final (status, payload) = _respond(
        request.uri.path,
        Uri.splitQueryString(body),
        request.headers.value('x-syno-token'),
      );
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(payload);
      await request.response.close();
    });
    return server;
  }

  (int, String) _respond(
    String path,
    Map<String, String> fields,
    String? synoToken,
  ) {
    final api = fields['api'];
    final info = apis[api];
    if (api == null || info == null || '/webapi/${info.path}' != path) {
      return _error(102);
    }
    final version = int.tryParse(fields['version'] ?? '');
    final method = fields['method'];
    if (version == null || method == null) return _error(101);
    if (!info.supports(version)) return _error(104);

    final failures = _failures[api];
    if (failures != null && failures.isNotEmpty) {
      return _error(failures.removeAt(0));
    }

    final params = Map.of(fields)
      ..remove('api')
      ..remove('version')
      ..remove('method');
    final session = _sessions[params['_sid']];
    final isPublic =
        api == 'SYNO.API.Info' || (api == authApi && method == 'login');
    if (!isPublic && (session == null || session.synoToken != synoToken)) {
      return _error(119);
    }

    final call = FakeCall(
      path: info.path,
      api: api,
      version: version,
      method: method,
      params: params,
      account: session?.account,
    );
    calls.add(call);
    try {
      final handler = _handlers['$api.$method'] ?? _builtIn(api, method);
      if (handler == null) return _error(103);
      return (200, jsonEncode({'success': true, 'data': handler(call)}));
    } on FakeSynologyError catch (e) {
      return _error(e.code);
    }
  }

  FakeHandler? _builtIn(String api, String method) => switch ((api, method)) {
    ('SYNO.API.Info', 'query') => (_) => {
      for (final info in apis.values)
        info.name: {
          'path': info.path,
          'minVersion': info.minVersion,
          'maxVersion': info.maxVersion,
          'requestFormat': 'JSON',
        },
    },
    (authApi, 'login') => _login,
    (authApi, 'logout') => (call) {
      _sessions.remove(call.params['_sid']);
      return {};
    },
    ('SYNO.DSM.Info', 'getinfo') => (_) => {
      'model': model,
      'ram': 4096,
      'serial': 'FAKE0001',
      'temperature': 42,
      'temperature_warn': false,
      'uptime': 3600,
      'version_string': versionString,
    },
    _ => null,
  };

  Map<String, dynamic> _login(FakeCall call) {
    final account = call.params['account'];
    if (account == null || accounts[account] != call.params['passwd']) {
      throw const FakeSynologyError(400);
    }

    final expectedOtp = otpCodes[account];
    final trusted = _trustedDevices[call.params['device_id']] == account;
    if (expectedOtp != null && !trusted) {
      final otp = call.params['otp_code'];
      if (otp == null) throw const FakeSynologyError(403);
      if (otp != expectedOtp) throw const FakeSynologyError(404);
    }

    final id = ++_counter;
    final session = _FakeSession(
      account,
      call.params['enable_syno_token'] == 'yes' ? 'token-$id' : null,
    );
    _sessions['sid-$id'] = session;

    final deviceId = call.params['enable_device_token'] == 'yes'
        ? 'device-$id'
        : null;
    if (deviceId != null) _trustedDevices[deviceId] = account;
    return {
      'sid': 'sid-$id',
      'synotoken': ?session.synoToken,
      'did': ?deviceId,
    };
  }

  static (int, String) _error(int code) => (
    200,
    jsonEncode({
      'success': false,
      'error': {'code': code},
    }),
  );
}

final class _FakeSession {
  const _FakeSession(this.account, this.synoToken);

  final String account;
  final String? synoToken;
}
