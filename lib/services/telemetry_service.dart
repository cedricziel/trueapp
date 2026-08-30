import 'package:flutter_otel/flutter_otel.dart';
import 'package:truehub/services/telemetry_config.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Default [TelemetryServiceInterface] implementation, wrapping [OTelSdk].
///
/// [initialize] always sets up the SDK, even when [TelemetryConfig.enabled]
/// is `false` - it just passes that through as [OTelSdkConfig.enabled],
/// which makes the SDK wire up a no-op exporter internally. The rest of the
/// app therefore never needs to null-check a "telemetry might not exist"
/// case: logging calls always succeed, they just go nowhere when disabled.
class TelemetryService implements TelemetryServiceInterface {
  TelemetryService._(this._sdk);

  final OTelSdk _sdk;

  /// Initializes the underlying [OTelSdk] from [config] and returns a
  /// service wrapping it.
  ///
  /// [config.otlpEndpoint] is a build-time string (see [TelemetryConfig])
  /// that could be malformed - e.g. a misconfigured CI secret. Parsing it
  /// with [Uri.tryParse] instead of [Uri.parse] means a bad value falls back
  /// to the same disabled/no-op SDK path used when no endpoint is configured
  /// at all, rather than throwing a [FormatException] that would crash the
  /// app on startup before the UI ever renders (`main()` awaits this before
  /// `runApp`).
  static Future<TelemetryService> initialize(TelemetryConfig config) async {
    final endpoint = config.enabled ? Uri.tryParse(config.otlpEndpoint) : null;

    final sdk = await OTelSdk.initialize(
      OTelSdkConfig(
        resource: OTelResource(
          serviceName: config.serviceName,
          deploymentEnvironment: config.deploymentEnvironment,
        ),
        enabled: config.enabled && endpoint != null,
        otlpEndpoint: endpoint,
        otlpHeaders: config.otlpHeaders,
      ),
    );
    return TelemetryService._(sdk);
  }

  @override
  Logger getLogger({String name = 'truehub', String? version}) =>
      _sdk.getLogger(name: name, version: version);

  @override
  void recordError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    final logger = getLogger();
    final body = context == null ? error.toString() : '$context: $error';

    if (fatal) {
      logger.emit(
        LogRecord(
          body: body,
          severity: LogSeverity.fatal,
          attributes: {
            'exception.type': error.runtimeType.toString(),
            'exception.message': error.toString(),
            'exception.stacktrace': stackTrace.toString(),
          },
        ),
      );
    } else {
      logger.error(body, error: error, stackTrace: stackTrace);
    }
  }

  @override
  Future<void> flush() => _sdk.forceFlush();

  @override
  Future<void> shutdown() => _sdk.shutdown();
}
