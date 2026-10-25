import 'api_catalog.dart';
import 'errors.dart';
import 'features.dart';
import 'models.dart';
import 'transport.dart';

/// Entry point to a single NAS: discovers its APIs, logs in, and routes each
/// call to the path and highest version both sides support.
class SynologyClient {
  SynologyClient(this._transport, {this.sessionName = 'TrueHub'});

  final SynologyTransport _transport;

  /// Session label DSM shows in its connection list.
  final String sessionName;
  Future<ApiCatalog>? _catalog;
  SynologySession? _session;

  SynologySession? get session => _session;

  /// Fetches the API catalog once and caches it for the client's lifetime;
  /// a failed fetch is retried on the next call.
  Future<ApiCatalog> discover() => _catalog ??= _fetchCatalog();

  Future<ApiCatalog> _fetchCatalog() async {
    try {
      return ApiCatalog.fromJson(
        await _transport.send(
          const SynologyRequest(
            path: 'query.cgi',
            api: 'SYNO.API.Info',
            version: 1,
            method: 'query',
            params: {'query': 'all'},
          ),
        ),
      );
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  /// Logs in and keeps the session for subsequent [call]s.
  ///
  /// Throws [SynologyOtpRequiredException] when the account uses two-factor
  /// authentication and [otpCode] is missing or wrong. Pass [deviceName] with
  /// the code to have DSM trust this device, then reuse the returned
  /// [SynologySession.deviceId] as [deviceId] to skip the code next time.
  Future<SynologySession> login(
    String account,
    String password, {
    String? otpCode,
    String? deviceName,
    String? deviceId,
  }) async {
    final data = await call(
      authApi,
      'login',
      minVersion: 3,
      // Clients that log in at v7 add a key exchange this library does not
      // implement; v6 works on DSM 6 and 7 alike.
      maxVersion: 6,
      authenticated: false,
      params: {
        'account': account,
        'passwd': password,
        'session': sessionName,
        'format': 'sid',
        'enable_syno_token': 'yes',
        'otp_code': ?otpCode,
        if (deviceName != null) ...{
          'enable_device_token': 'yes',
          'device_name': deviceName,
        },
        'device_id': ?deviceId,
      },
    );
    return _session = SynologySession.fromJson(data);
  }

  Future<void> logout() async {
    if (_session == null) return;
    try {
      await call(
        authApi,
        'logout',
        minVersion: 1,
        maxVersion: 7,
        params: {'session': sessionName},
      );
    } finally {
      _session = null;
    }
  }

  Future<DsmInfo> dsmInfo() async => DsmInfo.fromJson(
    await call('SYNO.DSM.Info', 'getinfo', minVersion: 1, maxVersion: 2),
  );

  /// Which [SynologyFeature]s this NAS supports. Needs a session, since the
  /// DSM version comes from [dsmInfo].
  Future<SynologyCapabilities> capabilities() async {
    final info = await dsmInfo();
    return SynologyCapabilities(await discover(), dsmVersion: info.version);
  }

  /// Calls [method] on [api] at the highest version in
  /// [minVersion]..[maxVersion] the NAS also serves.
  ///
  /// Throws [SynologyUnsupportedException] when no such version exists, and
  /// [StateError] when [authenticated] and nobody has logged in.
  Future<Map<String, dynamic>> call(
    String api,
    String method, {
    required int minVersion,
    required int maxVersion,
    Map<String, String> params = const {},
    bool authenticated = true,
  }) async {
    final info = (await discover())[api];
    if (info == null) {
      throw SynologyUnsupportedException('$api is not available on this NAS');
    }
    final version = info.negotiate(minVersion, maxVersion);
    if (version == null) {
      throw SynologyUnsupportedException(
        '$api v${info.minVersion}-${info.maxVersion} does not overlap '
        'the supported v$minVersion-$maxVersion',
      );
    }
    final session = _session;
    if (authenticated && session == null) {
      throw StateError('$api.$method requires login');
    }
    return _transport.send(
      SynologyRequest(
        path: info.path,
        api: api,
        version: version,
        method: method,
        params: {...params, '_sid': ?session?.sid},
        synoToken: session?.synoToken,
      ),
    );
  }
}
