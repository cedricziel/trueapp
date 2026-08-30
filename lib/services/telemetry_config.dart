/// Build-time telemetry configuration, read from `--dart-define` values at
/// compile time (see the `--dart-define` flags added in
/// `.github/workflows/ci.yml` and `fastlane/Fastfile`).
///
/// Telemetry is enabled solely by [otlpEndpoint] being non-empty - there is
/// no separate on/off flag. This keeps a single source of truth: set the
/// endpoint to turn telemetry on, leave it unset (the default) to turn it
/// off, everywhere including local `flutter run` with no `--dart-define`s
/// at all.
class TelemetryConfig {
  const TelemetryConfig({
    required this.otlpEndpoint,
    required this.otlpHeaders,
    required this.serviceName,
    required this.deploymentEnvironment,
  });

  /// Reads the configuration compiled into this build via `--dart-define`.
  factory TelemetryConfig.fromEnvironment() => TelemetryConfig(
    otlpEndpoint: _otlpEndpointRaw,
    otlpHeaders: parseHeaders(_otlpHeadersRaw),
    serviceName: _serviceName,
    deploymentEnvironment: _deploymentEnvironment,
  );

  // `String.fromEnvironment` only accepts compile-time-constant arguments,
  // so the dart-define names are read once here rather than inlined in
  // `fromEnvironment` above - keeps the env var names in exactly one place.
  static const String _otlpEndpointRaw = String.fromEnvironment(
    'OTEL_EXPORTER_OTLP_ENDPOINT',
    defaultValue: '',
  );
  static const String _otlpHeadersRaw = String.fromEnvironment(
    'OTEL_EXPORTER_OTLP_HEADERS',
    defaultValue: '',
  );
  static const String _serviceName = String.fromEnvironment(
    'OTEL_SERVICE_NAME',
    defaultValue: 'truehub',
  );
  static const String _deploymentEnvironment = String.fromEnvironment(
    'OTEL_DEPLOYMENT_ENVIRONMENT',
    defaultValue: 'development',
  );

  /// SignalDB OTLP ingest base URL. Empty (the default) means telemetry is
  /// disabled - see [enabled].
  final String otlpEndpoint;

  /// Extra headers sent with every OTLP export request, parsed from the
  /// standard `OTEL_EXPORTER_OTLP_HEADERS` comma-separated `key=value`
  /// format via [parseHeaders].
  final Map<String, String> otlpHeaders;

  /// `service.name` resource attribute.
  final String serviceName;

  /// `deployment.environment` resource attribute.
  final String deploymentEnvironment;

  /// Telemetry is enabled if and only if [otlpEndpoint] is non-empty.
  bool get enabled => otlpEndpoint.isNotEmpty;

  /// Parses the standard `OTEL_EXPORTER_OTLP_HEADERS` env var format:
  /// comma-separated `key=value` pairs, e.g.
  /// `x-api-key=secret,x-tenant=homelab`.
  ///
  /// Splits on `,` first, then on the *first* `=` in each pair, so values
  /// are free to contain `=` themselves (e.g. base64). Blank entries, and
  /// entries with no `=` or an empty key, are skipped rather than throwing -
  /// this parses build-time configuration, not user input worth failing
  /// loudly over.
  static Map<String, String> parseHeaders(String raw) {
    final headers = <String, String>{};
    for (final pair in raw.split(',')) {
      final trimmedPair = pair.trim();
      if (trimmedPair.isEmpty) continue;

      final separatorIndex = trimmedPair.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = trimmedPair.substring(0, separatorIndex).trim();
      final value = trimmedPair.substring(separatorIndex + 1).trim();
      if (key.isEmpty) continue;

      headers[key] = value;
    }
    return headers;
  }
}
