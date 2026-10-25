import 'package:flutter_otel/flutter_otel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/tracing_server_repository.dart';

import '../helpers/fake_server_repository.dart';
import '../helpers/fake_telemetry_service.dart';

void main() {
  const server = NasServer(
    id: 'srv-1',
    name: 'secret-name',
    host: 'secret.host',
    username: 'secret-user',
    password: 'secret-pass',
  );

  late FakeServerRepository inner;
  late FakeTelemetryService telemetry;
  late TracingServerRepository repository;

  setUp(() {
    inner = FakeServerRepository();
    telemetry = FakeTelemetryService();
    repository = TracingServerRepository(
      inner: inner,
      telemetry: telemetry,
      dbSystem: 'sqlite',
    );
  });

  test('wraps an operation in an internal span with the backend', () async {
    await repository.saveServer(server);

    final span = telemetry.spans.single;
    expect(span.name, 'server_repository.save_server');
    expect(span.kind, SpanKind.internal);
    expect(span.attributes['db.system.name'], 'sqlite');
    expect(span.attributes['server.id'], 'srv-1');
    expect(span.isEnded, isTrue);
    expect(inner.servers, contains('srv-1'));
  });

  test('records the server count on getAllServers', () async {
    await repository.saveServer(server);
    final result = await repository.getAllServers();

    expect(result, [server]);
    expect(telemetry.spans.last.name, 'server_repository.get_all_servers');
    expect(telemetry.spans.last.attributes['server.count'], 1);
  });

  test('records whether getServer found a server', () async {
    expect(await repository.getServer('missing'), isNull);

    expect(telemetry.spans.single.attributes['server.found'], isFalse);
  });

  test('never puts sensitive fields on any span', () async {
    await repository.saveServer(server);
    await repository.getServer('srv-1');
    await repository.getAllServers();

    final values = telemetry.spans
        .expand((s) => s.attributes.values)
        .map((v) => '$v')
        .toList();
    for (final secret in [
      'secret-name',
      'secret.host',
      'secret-user',
      'secret-pass',
    ]) {
      expect(values, isNot(contains(secret)));
    }
  });

  test('delegates the remaining operations under their own spans', () async {
    await repository.initialize();
    await repository.setDefaultServer('srv-1');
    await repository.getDefaultServer();
    await repository.clearDefaultServer();
    await repository.deleteServer('srv-1');
    await repository.sync();

    expect(telemetry.spans.map((s) => s.name), [
      'server_repository.initialize',
      'server_repository.set_default_server',
      'server_repository.get_default_server',
      'server_repository.clear_default_server',
      'server_repository.delete_server',
      'server_repository.sync',
    ]);
  });

  test('records the error on the span and rethrows', () async {
    inner.failWith = StateError('boom');

    await expectLater(repository.getAllServers(), throwsStateError);

    final span = telemetry.spans.single;
    expect(span.status, StatusCode.error);
    expect(span.exceptions.single.exception, isA<StateError>());
    expect(span.isEnded, isTrue);
  });

  test('passes streams, capabilities and dispose straight through', () async {
    final emitted = expectLater(repository.serversStream, emits([server]));
    inner.controller.add([server]);
    await emitted;
    expect(repository.supportsOfflineAccess, isTrue);
    expect(repository.supportsAutoSync, isFalse);

    await repository.dispose();

    expect(inner.disposeCount, 1);
    expect(telemetry.spans, isEmpty);
  });
}
