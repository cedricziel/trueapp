/// Base for every failure this library reports.
sealed class SynologyException implements Exception {
  const SynologyException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// DSM answered with `success: false` and an error code.
///
/// Codes below 400 are shared by every API; codes from 400 up belong to the
/// API that was called, so [api] is needed to interpret them.
class SynologyApiException extends SynologyException {
  SynologyApiException(this.code, {required this.api})
    : super(_describe(code, api));

  /// The most specific exception for [code], e.g. an OTP prompt at login.
  factory SynologyApiException.from(int code, {required String api}) =>
      api == authApi && const {403, 404, 406}.contains(code)
      ? SynologyOtpRequiredException(code)
      : SynologyApiException(code, api: api);

  final int code;
  final String api;

  /// The session is gone and a new login is required.
  bool get isSessionLost => const {106, 107, 119}.contains(code);

  static String _describe(int code, String api) {
    final text = _commonCodes[code] ?? _apiCodes[api]?[code] ?? 'Unknown error';
    return '$api error $code: $text';
  }
}

/// Login failed because DSM wants a one-time password, or rejected the one
/// it was given.
class SynologyOtpRequiredException extends SynologyApiException {
  SynologyOtpRequiredException(super.code) : super(api: authApi);
}

/// The NAS does not offer an API, or no version of it this library speaks.
class SynologyUnsupportedException extends SynologyException {
  const SynologyUnsupportedException(super.message);
}

/// The response was not the JSON envelope DSM normally sends.
class SynologyProtocolException extends SynologyException {
  const SynologyProtocolException(super.message);
}

const authApi = 'SYNO.API.Auth';

const _commonCodes = {
  100: 'Unknown error',
  101: 'Missing API, method or version parameter',
  102: 'API does not exist',
  103: 'Method does not exist',
  104: 'Version does not support this functionality',
  105: 'Session lacks permission',
  106: 'Session timed out',
  107: 'Session interrupted by duplicate login',
  108: 'File upload failed',
  109: 'Network connection unstable or system busy',
  110: 'Network connection unstable or system busy',
  111: 'Network connection unstable or system busy',
  117: 'Manager privilege required',
  119: 'Session ID not found',
  150: 'Request source IP does not match login IP',
};

/// Codes from 400 up, per API.
const _apiCodes = {authApi: _authCodes};

const _authCodes = {
  400: 'No such account or incorrect password',
  401: 'Account disabled',
  402: 'Permission denied',
  403: 'Two-factor authentication code required',
  404: 'Two-factor authentication code rejected',
  406: 'Two-factor authentication enforced; code required',
  407: 'Source IP blocked',
  408: 'Password expired and cannot be changed',
  409: 'Password expired',
  410: 'Password must be changed',
};
