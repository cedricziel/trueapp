import 'dart:math' as math;

/// One entry of `SYNO.API.Info`: where an API lives and which versions the
/// NAS serves.
final class ApiInfo {
  const ApiInfo({
    required this.name,
    required this.path,
    required this.minVersion,
    required this.maxVersion,
  });

  factory ApiInfo.fromJson(String name, Map<String, dynamic> json) => ApiInfo(
    name: name,
    path: json['path'] as String,
    minVersion: json['minVersion'] as int,
    maxVersion: json['maxVersion'] as int,
  );

  final String name;

  /// CGI path below `/webapi/`, e.g. `entry.cgi` or DSM 6's `auth.cgi`.
  final String path;
  final int minVersion;
  final int maxVersion;

  bool supports(int version) => version >= minVersion && version <= maxVersion;

  /// The highest version in [low]..[high] this API also serves, or null when
  /// the ranges do not overlap.
  int? negotiate(int low, int high) {
    final best = math.min(high, maxVersion);
    return best >= math.max(low, minVersion) ? best : null;
  }
}

/// The APIs a NAS advertises, keyed by name.
final class ApiCatalog {
  const ApiCatalog(this._apis);

  factory ApiCatalog.fromJson(Map<String, dynamic> json) => ApiCatalog({
    for (final MapEntry(:key, :value) in json.entries)
      key: ApiInfo.fromJson(key, value as Map<String, dynamic>),
  });

  final Map<String, ApiInfo> _apis;

  ApiInfo? operator [](String api) => _apis[api];

  bool has(String api) => _apis.containsKey(api);
}
