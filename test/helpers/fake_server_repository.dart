import 'dart:async';

import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';

/// In-memory [ServerRepositoryInterface]; set [failWith] to make every
/// future-returning operation throw it.
class FakeServerRepository implements ServerRepositoryInterface {
  final Map<String, NasServer> servers = {};
  final StreamController<List<NasServer>> controller =
      StreamController<List<NasServer>>.broadcast();
  Object? failWith;
  String? defaultId;
  int disposeCount = 0;

  Future<T> _run<T>(T Function() body) async {
    final error = failWith;
    if (error != null) throw error;
    return body();
  }

  @override
  Future<bool> initialize() => _run(() => true);

  @override
  Future<List<NasServer>> getAllServers() =>
      _run(() => servers.values.toList());

  @override
  Future<NasServer?> getServer(String id) => _run(() => servers[id]);

  @override
  Future<bool> saveServer(NasServer server) => _run(() {
    servers[server.id] = server;
    return true;
  });

  @override
  Future<bool> deleteServer(String id) =>
      _run(() => servers.remove(id) != null);

  @override
  Future<NasServer?> getDefaultServer() => _run(() => servers[defaultId]);

  @override
  Future<bool> setDefaultServer(String id) => _run(() {
    defaultId = id;
    return true;
  });

  @override
  Future<bool> clearDefaultServer() => _run(() {
    defaultId = null;
    return true;
  });

  @override
  Stream<List<NasServer>> get serversStream => controller.stream;

  @override
  bool get supportsOfflineAccess => true;

  @override
  bool get supportsAutoSync => false;

  @override
  Future<bool> sync() => _run(() => true);

  @override
  Future<void> dispose() async => disposeCount++;
}
