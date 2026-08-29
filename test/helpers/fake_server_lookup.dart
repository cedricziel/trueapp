import 'dart:async';

import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_lookup.dart';

/// An in-memory [ServerLookup] for unit-testing navigation code that
/// resolves a server by id without needing a real [UnifiedServerService]
/// (database, keychain, repository).
///
/// [getServer] reads the current in-memory map, matching the "seeded once,
/// looked up on demand" shape of the repository-backed implementation.
/// [serversStream] is a plain broadcast stream the test drives directly with
/// [emit] - it does not replay past events to a late subscriber, on purpose:
/// that mirrors [UnifiedServerService.serversStream] exactly, and a resolver
/// that only works because a fake replays history would pass here and hang
/// in production.
class FakeServerLookup implements ServerLookup {
  FakeServerLookup({List<NasServer> initial = const []}) {
    for (final server in initial) {
      _servers[server.id] = server;
    }
  }

  final Map<String, NasServer> _servers = {};
  final StreamController<List<NasServer>> _controller =
      StreamController<List<NasServer>>.broadcast();

  /// When set, [getServer] throws this instead of returning a result -
  /// simulates an offline CloudKit/DB error.
  Object? getServerError;

  /// Number of times [getServer] has been called - lets a test assert a
  /// lookup was (or, more importantly, was NOT) performed.
  int getServerCallCount = 0;

  @override
  Future<NasServer?> getServer(String id) async {
    getServerCallCount++;
    if (getServerError != null) {
      throw getServerError!;
    }
    return _servers[id];
  }

  @override
  Stream<List<NasServer>> get serversStream => _controller.stream;

  /// Publishes [servers] on [serversStream], as the repository does after a
  /// change lands.
  void emit(List<NasServer> servers) {
    _servers
      ..clear()
      ..addEntries(servers.map((s) => MapEntry(s.id, s)));
    _controller.add(servers);
  }

  Future<void> dispose() => _controller.close();
}
