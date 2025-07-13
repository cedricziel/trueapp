import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/providers/connection_status_provider.dart';

class ApiClientManager {
  static final Map<String, TrueNasApiClient> _clients = {};
  static final Map<String, int> _refCounts = {};
  static final Map<String, Completer<TrueNasApiClient>?> _connectionCompleters =
      {};
  static ConnectionStatusProvider? _connectionStatusProvider;

  static void setConnectionStatusProvider(ConnectionStatusProvider? provider) {
    _connectionStatusProvider = provider;
  }

  static Future<TrueNasApiClient?> getClient(NasServer server) async {
    final serverId = server.id;

    if (kDebugMode) {
      print(
        'ApiClientManager: getClient called for ${server.name} - username: "${server.username}"',
      );
    }

    if (_clients.containsKey(serverId)) {
      _refCounts[serverId] = (_refCounts[serverId] ?? 0) + 1;
      if (kDebugMode) {
        print(
          'ApiClientManager: Reusing existing client for server ${server.name} (ref count: ${_refCounts[serverId]})',
        );
      }
      return _clients[serverId];
    }

    // Check if there's already a connection in progress
    if (_connectionCompleters[serverId] != null) {
      if (kDebugMode) {
        print(
          'ApiClientManager: Waiting for existing connection to server ${server.name}',
        );
      }
      return await _connectionCompleters[serverId]!.future;
    }

    // Create a new connection
    final completer = Completer<TrueNasApiClient>();
    _connectionCompleters[serverId] = completer;

    try {
      if (kDebugMode) {
        print(
          'ApiClientManager: Creating new client for server ${server.name}',
        );
      }

      final client = TrueNasApiClient(server, _connectionStatusProvider);
      _clients[serverId] = client;
      _refCounts[serverId] = 1;

      if (kDebugMode) {
        print(
          'ApiClientManager: Successfully created client for server ${server.name}',
        );
      }

      completer.complete(client);
      return client;
    } catch (e) {
      if (kDebugMode) {
        print(
          'ApiClientManager: Failed to create client for server ${server.name}: $e',
        );
      }
      completer.completeError(e);
      rethrow;
    } finally {
      _connectionCompleters[serverId] = null;
    }
  }

  static Future<void> releaseClient(String serverId) async {
    if (!_clients.containsKey(serverId)) {
      return;
    }

    final refCount = (_refCounts[serverId] ?? 1) - 1;
    _refCounts[serverId] = refCount;

    if (kDebugMode) {
      print(
        'ApiClientManager: Released client for server $serverId (ref count: $refCount)',
      );
    }

    if (refCount <= 0) {
      if (kDebugMode) {
        print(
          'ApiClientManager: Closing client for server $serverId (no more references)',
        );
      }

      final client = _clients.remove(serverId);
      _refCounts.remove(serverId);
      _connectionCompleters.remove(serverId);

      if (client != null) {
        try {
          await client.close();
        } catch (e) {
          if (kDebugMode) {
            print('ApiClientManager: Error closing client for $serverId: $e');
          }
        }
      }
    }
  }

  static Future<void> closeClient(String serverId) async {
    if (kDebugMode) {
      print('ApiClientManager: Force closing client for server $serverId');
      print('  - Had cached client: ${_clients.containsKey(serverId)}');
      print('  - Ref count was: ${_refCounts[serverId]}');
    }

    final client = _clients.remove(serverId);
    _refCounts.remove(serverId);
    _connectionCompleters.remove(serverId);

    if (client != null) {
      try {
        await client.close();
        if (kDebugMode) {
          print(
            'ApiClientManager: Successfully closed client for server $serverId',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print(
            'ApiClientManager: Error closing client for server $serverId: $e',
          );
        }
      }
    } else {
      if (kDebugMode) {
        print(
          'ApiClientManager: No client found to close for server $serverId',
        );
      }
    }
  }

  static Future<void> closeAllClients() async {
    if (kDebugMode) {
      print('ApiClientManager: Closing all clients');
    }

    final clients = List<TrueNasApiClient>.from(_clients.values);
    _clients.clear();
    _refCounts.clear();
    _connectionCompleters.clear();

    await Future.wait(clients.map((client) => client.close()));
  }

  static TrueNasApiClient? getExistingClient(String serverId) {
    return _clients[serverId];
  }

  static bool hasClient(String serverId) {
    return _clients.containsKey(serverId);
  }

  static int getClientCount() {
    return _clients.length;
  }

  static List<String> getActiveServerIds() {
    return _clients.keys.toList();
  }

  static Map<String, int> getRefCounts() {
    return Map.from(_refCounts);
  }

  /// Force recreation of a client by closing any existing one and creating a fresh one
  /// This ensures no cached state affects the new client
  static Future<TrueNasApiClient?> forceRecreateClient(NasServer server) async {
    final serverId = server.id;

    if (kDebugMode) {
      print(
        'ApiClientManager: Force recreating client for server ${server.name}',
      );
    }

    // First, forcefully close any existing client
    await closeClient(serverId);

    // Wait a brief moment to ensure cleanup is complete
    await Future.delayed(const Duration(milliseconds: 50));

    // Now create a fresh client
    return await getClient(server);
  }

  /// Clears all cached clients and state. Used for testing only.
  @visibleForTesting
  static Future<void> clearAllForTesting() async {
    if (kDebugMode) {
      print('ApiClientManager: Clearing all clients for testing');
    }

    // Close all existing clients
    final clientIds = List<String>.from(_clients.keys);
    for (final id in clientIds) {
      await closeClient(id);
    }

    // Clear all maps
    _clients.clear();
    _refCounts.clear();
    _connectionCompleters.clear();
    _connectionStatusProvider = null;
  }
}
