import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:truehub/services/telemetry_config.dart';
import 'package:truehub/services/telemetry_service.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Initializes telemetry from build-time config and wires uncaught Flutter
/// framework errors and uncaught platform/async errors through to it, so
/// crashes and unhandled exceptions turn into OTel log records automatically
/// without every call site needing to know telemetry exists.
///
/// Always returns a usable [TelemetryServiceInterface] - when
/// [TelemetryConfig.enabled] is `false` (no OTLP endpoint configured), the
/// underlying SDK is initialized in its own no-op mode rather than skipped,
/// so callers elsewhere in the app never need a null check.
///
/// [config] and [initializeService] are injectable so tests can exercise the
/// error-handler wiring below without a real [TelemetryConfig.fromEnvironment]
/// / [TelemetryService.initialize] round trip.
Future<TelemetryServiceInterface> bootstrapTelemetry({
  TelemetryConfig? config,
  Future<TelemetryServiceInterface> Function(TelemetryConfig)?
  initializeService,
}) async {
  final telemetryService =
      await (initializeService ?? TelemetryService.initialize)(
        config ?? TelemetryConfig.fromEnvironment(),
      );

  final previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    telemetryService.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      context: 'FlutterError.onError',
    );
    previousOnError?.call(details);
  };

  final previousPlatformOnError = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    telemetryService.recordError(
      error,
      stack,
      context: 'PlatformDispatcher.instance.onError',
      fatal: true,
    );
    // Per Flutter's own docs, the VM/process may exit or become
    // unresponsive once this callback returns, so buffered telemetry must be
    // flushed explicitly here rather than relying on a graceful shutdown
    // path that may never run.
    unawaited(telemetryService.flush());
    return previousPlatformOnError?.call(error, stack) ?? false;
  };

  return telemetryService;
}
