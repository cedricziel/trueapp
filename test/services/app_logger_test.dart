import 'package:flutter_otel/flutter_otel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/app_logger.dart';

class _RecordingExporter implements LogRecordExporter {
  final records = <LogRecord>[];

  @override
  Future<ExportResult> export(
    List<LogRecord> records,
    OTelResource resource,
  ) async {
    this.records.addAll(records);
    return const ExportResult.success();
  }

  @override
  Future<void> shutdown() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await OTelSdk.reset();
  });

  test('is a no-op while the SDK is not initialized', () {
    final log = appLogger('test');

    expect(() => log.info('nobody is listening'), returnsNormally);
    expect(
      () => log.error(
        'boom',
        error: Exception('x'),
        stackTrace: StackTrace.current,
      ),
      returnsNormally,
    );
  });

  test('forwards to the SDK logger scoped as truehub.<scope>', () async {
    final log = appLogger('api.client');
    final exporter = _RecordingExporter();
    await OTelSdk.initialize(
      OTelSdkConfig(
        resource: OTelResource(
          serviceName: 'truehub-test',
          deploymentEnvironment: 'test',
        ),
        enabled: true,
        logExporter: exporter,
      ),
    );

    log.warn('hello', attributes: {'server.id': 'abc'});
    await OTelSdk.instance.forceFlush();

    expect(exporter.records, hasLength(1));
    final record = exporter.records.single;
    expect(record.body, 'hello');
    expect(record.severity, LogSeverity.warn);
    expect(record.attributes['server.id'], 'abc');
    expect(record.scopeName, 'truehub.api.client');
  });
}
