import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

/// Keeps at most one API client checked out of an
/// [ApiClientManagerInterface], for whichever server its owner currently
/// shows.
///
/// Switching servers releases the previous client before checking out the
/// next one. When a newer [connect] or [disconnect] call starts before an
/// older [connect] finishes, the older one gives its client back and reports
/// that it was superseded, so a slow connection never overwrites a newer one.
class ServerClientSession {
  ServerClientSession({
    required String owner,
    required ApiClientManagerInterface clientManager,
    required ServerCredentialsLookup credentials,
    TelemetryServiceInterface? telemetry,
  }) : _owner = owner,
       _clientManager = clientManager,
       _credentials = credentials,
       _telemetry = telemetry;

  final String _owner;
  final ApiClientManagerInterface _clientManager;
  final ServerCredentialsLookup _credentials;
  final TelemetryServiceInterface? _telemetry;

  ApiClientInterface? _client;
  String? _serverId;
  int _generation = 0;

  /// The checked-out client, or `null` when there is none.
  ApiClientInterface? get client => _client;

  /// The server this session currently belongs to, even when connecting to
  /// it failed.
  String? get serverId => _serverId;

  /// Releases the current client and checks one out for [server].
  ///
  /// Returns `false` when a later call superseded this one; the caller must
  /// then leave its own state alone. Missing credentials and connection
  /// failures still return `true`, with [client] left `null`.
  Future<bool> connect(NasServer server) async {
    final generation = await _releaseCurrent();
    if (generation != _generation) return false;

    _serverId = server.id;

    try {
      final password = await _credentials.getPassword(server.id);
      if (generation != _generation) return false;
      if (password == null) {
        if (kDebugMode) {
          print('$_owner: No credentials available for server ${server.id}');
        }
        return true;
      }

      final client = await _clientManager.getClient(
        server.copyWith(password: password),
      );
      if (generation != _generation) {
        if (client != null) await _clientManager.releaseClient(server.id);
        return false;
      }
      _client = client;
    } catch (e, stackTrace) {
      if (generation != _generation) return false;
      if (kDebugMode) {
        print('$_owner: Failed to get API client: $e');
      }
      _telemetry?.recordError(e, stackTrace, context: '$_owner.connect');
    }
    return true;
  }

  /// Releases the current client, leaving the session without a server.
  Future<void> disconnect() async {
    await _releaseCurrent();
  }

  /// Releases the current client without waiting, for use from `dispose`.
  void dispose() {
    _generation++;
    final serverId = _serverId;
    _client = null;
    _serverId = null;
    if (serverId != null) _clientManager.releaseClient(serverId);
  }

  Future<int> _releaseCurrent() async {
    final generation = ++_generation;
    final serverId = _serverId;
    _client = null;
    _serverId = null;
    if (serverId != null) await _clientManager.releaseClient(serverId);
    return generation;
  }
}
