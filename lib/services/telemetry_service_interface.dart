import 'package:flutter_otel/flutter_otel.dart';

/// Abstraction over the telemetry SDK so the rest of the app codes against
/// an interface rather than `package:flutter_otel` directly (per this
/// repo's interfaces + dependency-injection philosophy) - real usage is
/// [TelemetryService], tests can fake this instead of the SDK.
abstract class TelemetryServiceInterface {
  /// Returns a [Logger] for the given instrumentation scope. Implementations
  /// typically cache and return the same instance for a given
  /// name/version pair.
  Logger getLogger({String name = 'truehub', String? version});

  /// Returns a [Tracer] for the given instrumentation scope. Implementations
  /// typically cache and return the same instance for a given
  /// name/version pair.
  Tracer getTracer({String name = 'truehub', String? version});

  /// Records an error and its stack trace as a log record - the intended
  /// target for `FlutterError.onError` / `PlatformDispatcher.instance.onError`
  /// hooks, and for any `catch` block that wants a caught error to surface
  /// in telemetry.
  ///
  /// [context] is an optional human-readable note on where the error was
  /// caught (e.g. `'FlutterError.onError'`), prepended to the log body.
  /// [fatal] marks the record FATAL severity instead of ERROR - use it for
  /// errors the app cannot recover from.
  void recordError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  });

  /// Forces any buffered telemetry to be exported now.
  Future<void> flush();

  /// Flushes and releases the underlying SDK resources. After this
  /// resolves, this service should no longer be used.
  Future<void> shutdown();
}
