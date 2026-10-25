import 'package:flutter_otel/flutter_otel.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_repository_interface.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Wraps a [ServerRepositoryInterface] so each operation runs in an INTERNAL
/// span. Attributes are limited to the backend, server ids and counts - never
/// names, hosts, usernames or passwords.
class TracingServerRepository implements ServerRepositoryInterface {
  TracingServerRepository({
    required this._inner,
    required this._telemetry,
    required this._dbSystem,
  });

  final ServerRepositoryInterface _inner;
  final TelemetryServiceInterface _telemetry;
  final String _dbSystem;

  Future<T> _traced<T>(
    String operation,
    Future<T> Function() body, {
    Map<String, Object?> attributes = const {},
    Map<String, Object?> Function(T result)? resultAttributes,
  }) {
    return _telemetry.getTracer().startActiveSpan<T>(
      'server_repository.$operation',
      (span) async {
        final result = await body();
        if (resultAttributes != null) {
          span.setAttributes(resultAttributes(result));
        }
        return result;
      },
      kind: SpanKind.internal,
      attributes: {'db.system.name': _dbSystem, ...attributes},
    );
  }

  @override
  Future<bool> initialize() => _traced('initialize', _inner.initialize);

  @override
  Future<List<NasServer>> getAllServers() => _traced(
    'get_all_servers',
    _inner.getAllServers,
    resultAttributes: (servers) => {'server.count': servers.length},
  );

  @override
  Future<NasServer?> getServer(String id) => _traced(
    'get_server',
    () => _inner.getServer(id),
    attributes: {'server.id': id},
    resultAttributes: (server) => {'server.found': server != null},
  );

  @override
  Future<bool> saveServer(NasServer server) => _traced(
    'save_server',
    () => _inner.saveServer(server),
    attributes: {'server.id': server.id},
  );

  @override
  Future<bool> deleteServer(String id) => _traced(
    'delete_server',
    () => _inner.deleteServer(id),
    attributes: {'server.id': id},
  );

  @override
  Future<NasServer?> getDefaultServer() => _traced(
    'get_default_server',
    _inner.getDefaultServer,
    resultAttributes: (server) => {'server.found': server != null},
  );

  @override
  Future<bool> setDefaultServer(String id) => _traced(
    'set_default_server',
    () => _inner.setDefaultServer(id),
    attributes: {'server.id': id},
  );

  @override
  Future<bool> clearDefaultServer() =>
      _traced('clear_default_server', _inner.clearDefaultServer);

  @override
  Future<bool> sync() => _traced('sync', _inner.sync);

  @override
  Stream<List<NasServer>> get serversStream => _inner.serversStream;

  @override
  bool get supportsOfflineAccess => _inner.supportsOfflineAccess;

  @override
  bool get supportsAutoSync => _inner.supportsAutoSync;

  @override
  Future<void> dispose() => _inner.dispose();
}
