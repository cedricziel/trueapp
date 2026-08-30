import 'package:flutter_otel/flutter_otel.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Records what it was asked to do, for widget/provider tests that take a
/// [TelemetryServiceInterface] dependency but don't want a real [OTelSdk]
/// (which would need `WidgetsFlutterBinding` and, if enabled, a network
/// call) in the loop.
class FakeTelemetryService implements TelemetryServiceInterface {
  final List<RecordedTelemetryError> recordedErrors = [];
  final List<String> loggerNames = [];
  final List<String> tracerNames = [];

  /// Every [FakeSpan] started by any [Tracer] this service has vended, in
  /// start order - the seam tests use to assert on attributes/status/
  /// exceptions without needing a real SDK span pipeline.
  final List<FakeSpan> spans = [];

  int flushCount = 0;
  int shutdownCount = 0;

  @override
  Logger getLogger({String name = 'truehub', String? version}) {
    loggerNames.add(name);
    return _FakeLogger();
  }

  @override
  Tracer getTracer({String name = 'truehub', String? version}) {
    tracerNames.add(name);
    return _FakeTracer(name, spans);
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

/// Minimal [Tracer] fake that records started spans into a shared list and
/// mirrors `SdkTracer.startActiveSpan`'s real contract (record the
/// exception, set an error status, end the span, rethrow) so tests can
/// assert against it the same way they would against the real SDK.
class _FakeTracer implements Tracer {
  _FakeTracer(this.name, this._spans);

  @override
  final String name;

  final List<FakeSpan> _spans;

  @override
  Span startSpan(
    String name, {
    SpanKind kind = SpanKind.internal,
    Map<String, Object?>? attributes,
    SpanContext? parentContext,
  }) {
    final span = FakeSpan(name, kind: kind, attributes: attributes);
    _spans.add(span);
    return span;
  }

  @override
  Future<T> startActiveSpan<T>(
    String name,
    Future<T> Function(Span span) body, {
    SpanKind kind = SpanKind.internal,
    Map<String, Object?>? attributes,
  }) async {
    final span = startSpan(name, kind: kind, attributes: attributes);
    try {
      return await Span.runWithSpan(span, () => body(span));
    } catch (e, stackTrace) {
      span.recordException(e, stackTrace: stackTrace);
      span.setStatus(StatusCode.error, description: e.toString());
      rethrow;
    } finally {
      span.end();
    }
  }
}

/// A [Span] fake that records every mutation made to it - attributes,
/// events, status, and recorded exceptions - for tests to assert against.
/// Following [_FakeLogger]'s "record what it was asked to do" philosophy.
class FakeSpan implements Span {
  FakeSpan(this.name, {required this.kind, Map<String, Object?>? attributes})
    : attributes = Map.of(attributes ?? const {});

  @override
  final String name;

  /// The [SpanKind] this span was started with.
  final SpanKind kind;

  /// Merged attribute set, updated in place by [setAttribute]/
  /// [setAttributes] - reflects the span's current attributes, not a log of
  /// individual calls.
  final Map<String, Object?> attributes;

  /// Every [addEvent] call, in order.
  final List<RecordedSpanEvent> events = [];

  /// Every [recordException] call, in order.
  final List<RecordedSpanException> exceptions = [];

  /// The status set by the most recent [setStatus] call - [StatusCode.unset]
  /// until one is made.
  StatusCode status = StatusCode.unset;

  /// The `description` from the most recent [setStatus] call, if any.
  String? statusDescription;

  bool _ended = false;

  /// Whether [end] has been called on this span.
  bool get isEnded => _ended;

  @override
  final SpanContext spanContext = const SpanContext(
    traceId: 'ffffffffffffffffffffffffffffffff',
    spanId: 'ffffffffffffffff',
  );

  @override
  bool get isRecording => !_ended;

  @override
  void setAttribute(String key, Object? value) {
    if (_ended) return;
    attributes[key] = value;
  }

  @override
  void setAttributes(Map<String, Object?> attributes) {
    if (_ended) return;
    this.attributes.addAll(attributes);
  }

  @override
  void addEvent(
    String name, {
    Map<String, Object?>? attributes,
    DateTime? timestamp,
  }) {
    if (_ended) return;
    events.add(
      RecordedSpanEvent(
        name: name,
        attributes: attributes ?? const {},
        timestamp: timestamp,
      ),
    );
  }

  @override
  void setStatus(StatusCode code, {String? description}) {
    if (_ended) return;
    status = code;
    statusDescription = description;
  }

  @override
  void recordException(
    Object exception, {
    StackTrace? stackTrace,
    Map<String, Object?>? attributes,
  }) {
    if (_ended) return;
    exceptions.add(
      RecordedSpanException(
        exception: exception,
        stackTrace: stackTrace,
        attributes: attributes ?? const {},
      ),
    );
  }

  @override
  void end([DateTime? endTime]) {
    _ended = true;
  }
}

/// One [FakeSpan.addEvent] call, captured for assertions.
class RecordedSpanEvent {
  RecordedSpanEvent({
    required this.name,
    required this.attributes,
    required this.timestamp,
  });

  final String name;
  final Map<String, Object?> attributes;
  final DateTime? timestamp;
}

/// One [FakeSpan.recordException] call, captured for assertions.
class RecordedSpanException {
  RecordedSpanException({
    required this.exception,
    required this.stackTrace,
    required this.attributes,
  });

  final Object exception;
  final StackTrace? stackTrace;
  final Map<String, Object?> attributes;
}
