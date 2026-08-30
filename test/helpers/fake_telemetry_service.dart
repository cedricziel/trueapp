import 'package:flutter_otel/flutter_otel.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Records what it was asked to do, for widget/provider tests that take a
/// [TelemetryServiceInterface] dependency but don't want a real [OTelSdk]
/// (which would need `WidgetsFlutterBinding` and, if enabled, a network
/// call) in the loop.
class FakeTelemetryService implements TelemetryServiceInterface {
  final List<RecordedTelemetryError> recordedErrors = [];
  final List<String> loggerNames = [];
  int flushCount = 0;
  int shutdownCount = 0;

  @override
  Logger getLogger({String name = 'truehub', String? version}) {
    loggerNames.add(name);
    return _FakeLogger();
  }

  @override
  void recordError(
    Object error,
    StackTrace stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    recordedErrors.add(
      RecordedTelemetryError(
        error: error,
        stackTrace: stackTrace,
        context: context,
        fatal: fatal,
      ),
    );
  }

  @override
  Future<void> flush() async => flushCount++;

  @override
  Future<void> shutdown() async => shutdownCount++;
}

/// One call to [FakeTelemetryService.recordError], captured for assertions.
class RecordedTelemetryError {
  RecordedTelemetryError({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.fatal,
  });

  final Object error;
  final StackTrace stackTrace;
  final String? context;
  final bool fatal;
}

/// Discards every record - [FakeTelemetryService] only needs to prove
/// [TelemetryServiceInterface.getLogger] was called with the right scope,
/// not to inspect what was logged through it.
class _FakeLogger extends Logger {
  final List<LogRecord> records = [];

  @override
  void emit(LogRecord record) => records.add(record);
}
