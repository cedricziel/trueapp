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
  static Future<TelemetryService> initialize(TelemetryConfig config) async {
    final sdk = await OTelSdk.initialize(
      OTelSdkConfig(
        resource: OTelResource(
          serviceName: config.serviceName,
          deploymentEnvironment: config.deploymentEnvironment,
        ),
        enabled: config.enabled,
        otlpEndpoint: config.enabled ? Uri.parse(config.otlpEndpoint) : null,
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
