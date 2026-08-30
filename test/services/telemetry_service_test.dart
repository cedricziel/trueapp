import 'package:flutter_otel/flutter_otel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/telemetry_config.dart';
import 'package:truehub/services/telemetry_service.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

import '../helpers/fake_telemetry_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Every test below runs with telemetry disabled (no OTLP endpoint), which
  // makes OTelSdk wire up a no-op exporter internally - real behaviour, no
  // network I/O. That path is exactly what CI and every un-configured local
  // build exercise, and it's the only path safe to hit from a unit test.
  const disabledConfig = TelemetryConfig(
    otlpEndpoint: '',
    otlpHeaders: {},
    serviceName: 'truehub-test',
    deploymentEnvironment: 'test',
  );

  tearDown(() async {
    await OTelSdk.reset();
  });

  group('TelemetryService (real, disabled config)', () {
    test(
      'initialize returns a usable service without a network call',
      () async {
        final service = await TelemetryService.initialize(disabledConfig);

        expect(service, isA<TelemetryServiceInterface>());
      },
    );

    test(
      'getLogger returns a Logger that can be used without throwing',
      () async {
        final service = await TelemetryService.initialize(disabledConfig);

        final logger = service.getLogger();

        expect(logger, isA<Logger>());
        expect(() => logger.info('hello from a test'), returnsNormally);
      },
    );

    test(
      'recordError with fatal: false emits an ERROR-severity record via the logger',
      () async {
        final service = await TelemetryService.initialize(disabledConfig);

        expect(
          () => service.recordError(
            Exception('boom'),
            StackTrace.current,
            context: 'unit test',
          ),
          returnsNormally,
        );
      },
    );

    test('recordError with fatal: true does not throw', () async {
      final service = await TelemetryService.initialize(disabledConfig);

      expect(
        () => service.recordError(
          Exception('fatal boom'),
          StackTrace.current,
          fatal: true,
        ),
        returnsNormally,
      );
    });

    test('flush completes', () async {
      final service = await TelemetryService.initialize(disabledConfig);

      await expectLater(service.flush(), completes);
    });

    test('shutdown completes', () async {
      final service = await TelemetryService.initialize(disabledConfig);

      await expectLater(service.shutdown(), completes);
    });
  });

  // Exercises the interface contract itself via a fake, per this repo's
  // interfaces + DI testing guidelines - anything coded against
  // TelemetryServiceInterface should be testable without a real OTelSdk.
  group('TelemetryServiceInterface contract (fake)', () {
    test('getLogger is recorded and returns a Logger', () {
      final fake = FakeTelemetryService();

      final logger = fake.getLogger(name: 'my-scope');

      expect(logger, isA<Logger>());
      expect(fake.loggerNames, ['my-scope']);
    });

    test(
      'recordError records the error, stack trace, context, and fatal flag',
      () {
        final fake = FakeTelemetryService();
        final error = Exception('boom');
        final stackTrace = StackTrace.current;

        fake.recordError(error, stackTrace, context: 'ctx', fatal: true);

        expect(fake.recordedErrors, hasLength(1));
        final recorded = fake.recordedErrors.single;
        expect(recorded.error, same(error));
        expect(recorded.stackTrace, same(stackTrace));
        expect(recorded.context, 'ctx');
        expect(recorded.fatal, isTrue);
      },
    );

    test('flush and shutdown are counted', () async {
      final fake = FakeTelemetryService();

      await fake.flush();
      await fake.flush();
      await fake.shutdown();

      expect(fake.flushCount, 2);
      expect(fake.shutdownCount, 1);
    });
  });
}
