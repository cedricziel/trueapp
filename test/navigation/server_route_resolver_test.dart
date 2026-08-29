import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/server_route_resolver.dart';
import '../helpers/fake_server_lookup.dart';

/// Unit coverage for [LookupServerRouteResolver] (ticket #84): every
/// `/server/:serverId` page builder used to do `state.extra as NasServer`,
/// which throws whenever `extra` is absent - a cold start, a deep link, or a
/// restored location. This resolver replaces that cast with id-based,
/// streamed resolution so those routes can build a loading state instead of
/// crashing, and stay live as the underlying server changes or disappears.
void main() {
  NasServer server({String id = 'srv-1', String name = 'Test Server'}) {
    return NasServer(
      id: id,
      name: name,
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  }

  late FakeServerLookup lookup;
  late LookupServerRouteResolver resolver;

  setUp(() {
    lookup = FakeServerLookup();
    resolver = LookupServerRouteResolver(lookup);
  });

  tearDown(() async {
    await lookup.dispose();
  });

  test('resolve emits resolving then resolved for a known id', () async {
    final known = server();
    lookup.emit([known]);

    await expectLater(
      resolver.resolve('srv-1'),
      emitsInOrder([
        isA<ServerResolving>(),
        isA<ServerResolved>().having((r) => r.server.id, 'server.id', 'srv-1'),
      ]),
    );
  });

  test('resolve emits resolving then unknown for an unregistered id', () async {
    await expectLater(
      resolver.resolve('does-not-exist'),
      emitsInOrder([isA<ServerResolving>(), isA<ServerUnknown>()]),
    );
  });

  test(
    'resolve re-emits the server when the lookup stream reports an update',
    () async {
      lookup.emit([server(name: 'Original Name')]);

      final events = resolver.resolve('srv-1');
      final expectation = expectLater(
        events,
        emitsInOrder([
          isA<ServerResolving>(),
          isA<ServerResolved>().having(
            (r) => r.server.name,
            'server.name',
            'Original Name',
          ),
          isA<ServerResolved>().having(
            (r) => r.server.name,
            'server.name',
            'Renamed',
          ),
        ]),
      );

      // Give the initial getServer() lookup a turn to complete before the
      // stream emits, matching production ordering.
      await Future<void>.delayed(Duration.zero);
      lookup.emit([server(name: 'Renamed')]);

      await expectation;
    },
  );

  test('resolve emits unknown when the server is deleted', () async {
    lookup.emit([server()]);

    final events = resolver.resolve('srv-1');
    final expectation = expectLater(
      events,
      emitsInOrder([
        isA<ServerResolving>(),
        isA<ServerResolved>(),
        isA<ServerUnknown>(),
      ]),
    );

    await Future<void>.delayed(Duration.zero);
    lookup.emit(const []);

    await expectation;
  });

  test('resolve emits unknown when the lookup throws', () async {
    lookup.getServerError = Exception('boom');

    await expectLater(
      resolver.resolve('srv-1'),
      emitsInOrder([isA<ServerResolving>(), isA<ServerUnknown>()]),
    );
  });

  test(
    'resolve seeds from a known server without calling getServer at all',
    () async {
      final known = server(name: 'Cached Copy');

      await expectLater(
        resolver.resolve('srv-1', initialServer: known),
        emitsInOrder([
          isA<ServerResolved>().having(
            (r) => r.server.name,
            'server.name',
            'Cached Copy',
          ),
        ]),
      );

      expect(
        lookup.getServerCallCount,
        0,
        reason:
            'a known initial server must skip the async lookup entirely - '
            'an un-awaited real query left pending is exactly what stalls '
            'drift\'s serialized queue for the rest of a FakeAsync test',
      );
    },
  );

  test(
    'resolve still tracks live updates after seeding from a known server',
    () async {
      final known = server(name: 'Cached Copy');

      final events = resolver.resolve('srv-1', initialServer: known);
      final expectation = expectLater(
        events,
        emitsInOrder([
          isA<ServerResolved>().having(
            (r) => r.server.name,
            'server.name',
            'Cached Copy',
          ),
          isA<ServerResolved>().having(
            (r) => r.server.name,
            'server.name',
            'Renamed',
          ),
        ]),
      );

      await Future<void>.delayed(Duration.zero);
      lookup.emit([server(name: 'Renamed')]);

      await expectation;
    },
  );
}
