import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';

/// One DSM Web API call.
final class SynologyRequest {
  const SynologyRequest({
    required this.path,
    required this.api,
    required this.version,
    required this.method,
    this.params = const {},
    this.synoToken,
  });

  /// CGI path below `/webapi/`.
  final String path;
  final String api;
  final int version;
  final String method;
  final Map<String, String> params;

  /// CSRF token DSM hands out at login; sent as `X-SYNO-TOKEN`.
  final String? synoToken;
}

/// Sends a [SynologyRequest] and returns the `data` member of a successful
/// response, throwing a [SynologyException] otherwise.
abstract interface class SynologyTransport {
  Future<Map<String, dynamic>> send(SynologyRequest request);
}

/// [SynologyTransport] over HTTP(S), using form-encoded POSTs so credentials
/// never end up in a URL.
///
/// Pass an [http.Client] configured to accept the NAS's certificate when it
/// is self-signed.
final class HttpSynologyTransport implements SynologyTransport {
  HttpSynologyTransport(this.baseUri, {http.Client? client})
    : _client = client ?? http.Client();

  /// Scheme, host and port of the NAS, e.g. `https://nas.local:5001`.
  final Uri baseUri;
  final http.Client _client;

  @override
  Future<Map<String, dynamic>> send(SynologyRequest request) async {
    final response = await _client.post(
      baseUri.replace(path: '/webapi/${request.path}'),
      headers: {'X-SYNO-TOKEN': ?request.synoToken},
      body: {
        'api': request.api,
        'version': '${request.version}',
        'method': request.method,
        ...request.params,
      },
    );
    if (response.statusCode != 200) {
      throw SynologyProtocolException(
        '${request.api} returned HTTP ${response.statusCode}',
      );
    }
    return _unwrap(request.api, response.body);
  }

  void close() => _client.close();

  static Map<String, dynamic> _unwrap(String api, String body) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw SynologyProtocolException('$api returned a non-JSON body');
    }
    if (decoded case {'success': true}) {
      return switch (decoded['data']) {
        final Map<String, dynamic> data => data,
        _ => const {},
      };
    }
    if (decoded case {'success': false, 'error': {'code': final int code}}) {
      throw SynologyApiException.from(code, api: api);
    }
    throw SynologyProtocolException('$api returned an unexpected envelope');
  }
}
