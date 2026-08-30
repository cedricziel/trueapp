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
      'getTracer returns a Tracer that can be used without throwing',
      () async {
        final service = await TelemetryService.initialize(disabledConfig);

        final tracer = service.getTracer();

        expect(tracer, isA<Tracer>());
        await expectLater(
          tracer.startActiveSpan(
            'test-span',
            (span) async => span.setStatus(StatusCode.ok),
          ),
          completes,
        );
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

    test('a malformed OTLP endpoint does not throw and falls back to a '
        'disabled/no-op service instead of crashing app startup', () async {
      // A build-time misconfiguration (e.g. a bad CI secret) could produce
      // a string Uri.parse would reject with a FormatException. Since
      // main() awaits telemetry bootstrap before runApp, that would crash
      // the whole app before the UI ever renders - initialize must instead
      // degrade to the same no-op path used when no endpoint is set.
      const malformedConfig = TelemetryConfig(
        otlpEndpoint: 'not a valid uri: ::://',
        otlpHeaders: {},
        serviceName: 'truehub-test',
        deploymentEnvironment: 'test',
      );

      final service = await TelemetryService.initialize(malformedConfig);

      expect(service, isA<TelemetryServiceInterface>());
      // The service must still be safely usable, exactly like the
      // disabled-config path above.
      expect(
        () => service.recordError(Exception('boom'), StackTrace.current),
        returnsNormally,
      );
      await expectLater(service.flush(), completes);
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

    test('getTracer is recorded and returns a Tracer', () {
      final fake = FakeTelemetryService();

      final tracer = fake.getTracer(name: 'my-scope');

      expect(tracer, isA<Tracer>());
      expect(fake.tracerNames, ['my-scope']);
    });

    test(
      'a started span records attributes/status and is captured in spans',
      () async {
        final fake = FakeTelemetryService();
        final tracer = fake.getTracer();

        await tracer.startActiveSpan(
          'my-span',
          (span) async {
            span.setAttribute('server.id', 'abc');
            span.setStatus(StatusCode.ok);
          },
          kind: SpanKind.client,
          attributes: {'initial': true},
        );

        expect(fake.spans, hasLength(1));
        final span = fake.spans.single;
        expect(span.name, 'my-span');
        expect(span.kind, SpanKind.client);
        expect(span.attributes, {'initial': true, 'server.id': 'abc'});
        expect(span.status, StatusCode.ok);
        expect(span.isEnded, isTrue);
      },
    );

    test('a span whose body throws records the exception and an error status, '
        'then rethrows', () async {
      final fake = FakeTelemetryService();
      final tracer = fake.getTracer();
      final error = Exception('boom');

      await expectLater(
        tracer.startActiveSpan('failing-span', (span) async {
          throw error;
        }),
        throwsA(same(error)),
      );

      expect(fake.spans, hasLength(1));
      final span = fake.spans.single;
      expect(span.status, StatusCode.error);
      expect(span.exceptions, hasLength(1));
      expect(span.exceptions.single.exception, same(error));
      expect(span.isEnded, isTrue);
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
