import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/app_logger.dart';

final _log = appLogger('api.manager');

/// Default implementation of ApiClientManagerInterface
class ApiClientManagerImpl implements ApiClientManagerInterface {
  final Map<String, TrueNasApiClient> _clients = {};
  final Map<String, int> _refCounts = {};
  final Map<String, Completer<TrueNasApiClient>?> _connectionCompleters = {};
  final ConnectionStatusProvider? _connectionStatusProvider;
  final TelemetryServiceInterface? _telemetry;

  ApiClientManagerImpl({
    ConnectionStatusProvider? connectionStatusProvider,
    TelemetryServiceInterface? telemetry,
  }) : _connectionStatusProvider = connectionStatusProvider,
       _telemetry = telemetry;

  @override
  Future<ApiClientInterface?> getClient(NasServer server) async {
    final serverId = server.id;

    if (_clients.containsKey(serverId)) {
      _refCounts[serverId] = (_refCounts[serverId] ?? 0) + 1;
      _log.debug(
        'Reusing existing client',
        attributes: {'server.id': serverId, 'ref_count': _refCounts[serverId]},
      );
      return _clients[serverId];
    }

    // Check if there's already a connection in progress
    if (_connectionCompleters[serverId] != null) {
      _log.debug(
        'Waiting for existing connection',
        attributes: {'server.id': serverId},
      );
      return await _connectionCompleters[serverId]!.future;
    }

    // Create a new connection
    final completer = Completer<TrueNasApiClient>();
    _connectionCompleters[serverId] = completer;

    try {
      _log.debug('Creating new client', attributes: {'server.id': serverId});

      final client = TrueNasApiClient(
        server,
        _connectionStatusProvider,
        _telemetry,
      );
      _clients[serverId] = client;
      _refCounts[serverId] = 1;

      _log.info('Created client', attributes: {'server.id': serverId});

      completer.complete(client);
      return client;
    } catch (e) {
      _log.error(
        'Failed to create client',
        error: e,
        attributes: {'server.id': serverId},
      );
      completer.completeError(e);
      rethrow;
    } finally {
      _connectionCompleters[serverId] = null;
    }
  }

  @override
  Future<void> releaseClient(String serverId) async {
    if (!_clients.containsKey(serverId)) {
      return;
    }

    final refCount = (_refCounts[serverId] ?? 1) - 1;
    _refCounts[serverId] = refCount;

    _log.debug(
      'Released client',
      attributes: {'server.id': serverId, 'ref_count': refCount},
    );

    if (refCount <= 0) {
      _log.info(
        'Closing client, no more references',
        attributes: {'server.id': serverId},
      );

      final client = _clients.remove(serverId);
      _refCounts.remove(serverId);
      _connectionCompleters.remove(serverId);

      if (client != null) {
        try {
          await client.close();
        } catch (e) {
          _log.error(
            'Error closing client',
            error: e,
            attributes: {'server.id': serverId},
          );
        }
      }
    }
  }

  @override
  Future<void> closeClient(String serverId) async {
    _log.info(
      'Force closing client',
      attributes: {
        'server.id': serverId,
        'had_cached_client': _clients.containsKey(serverId),
        'ref_count': _refCounts[serverId],
      },
    );

    final client = _clients.remove(serverId);
    _refCounts.remove(serverId);
    _connectionCompleters.remove(serverId);

    if (client != null) {
      try {
        await client.close();
        _log.info('Closed client', attributes: {'server.id': serverId});
      } catch (e) {
        _log.error(
          'Error closing client',
          error: e,
          attributes: {'server.id': serverId},
        );
      }
    } else {
      _log.debug(
        'No client found to close',
        attributes: {'server.id': serverId},
      );
    }
  }

  @override
  Future<Map<String, Object>> ensureAllConnectionsAlive() async {
    final failures = <String, Object>{};

    await Future.wait(
      getActiveServerIds().map((serverId) async {
        final client = getExistingClient(serverId);
        if (client == null) return;
        try {
          await client.ensureConnectionAlive();
        } catch (e) {
          failures[serverId] = e;
          _log.error(
            'Recovery failed',
            error: e,
            attributes: {'server.id': serverId},
          );
        }
      }),
    );

    return failures;
  }

  @override
  Future<void> closeAllClients() async {
    _log.info('Closing all clients');

    final clients = List<TrueNasApiClient>.from(_clients.values);
    _clients.clear();
    _refCounts.clear();
    _connectionCompleters.clear();

    await Future.wait(clients.map((client) => client.close()));
  }

  @override
  ApiClientInterface? getExistingClient(String serverId) {
    return _clients[serverId];
  }

  @override
  bool hasClient(String serverId) {
    return _clients.containsKey(serverId);
  }

  @override
  int getClientCount() {
    return _clients.length;
  }

  @override
  List<String> getActiveServerIds() {
    return _clients.keys.toList();
  }

  @override
  Map<String, int> getRefCounts() {
    return Map.from(_refCounts);
  }

  @override
  Future<ApiClientInterface?> forceRecreateClient(NasServer server) async {
    final serverId = server.id;

    _log.debug('Force recreating client', attributes: {'server.id': serverId});

    // First, forcefully close any existing client
    await closeClient(serverId);

    // Wait a brief moment to ensure cleanup is complete
    await Future.delayed(const Duration(milliseconds: 50));

    // Now create a fresh client
    return await getClient(server);
  }

  @override
  @visibleForTesting
  Future<void> clearAllForTesting() async {
    _log.debug('Clearing all clients for testing');

    // Close all existing clients
    final clientIds = List<String>.from(_clients.keys);
    for (final id in clientIds) {
      await closeClient(id);
    }

    // Clear all maps
    _clients.clear();
    _refCounts.clear();
    _connectionCompleters.clear();
  }
}
