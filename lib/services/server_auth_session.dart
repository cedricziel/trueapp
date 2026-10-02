import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/server_credentials_lookup.dart';
import 'package:truehub/services/telemetry_service_interface.dart';

final _log = appLogger('services.server_auth_session');

enum AuthenticationState {
  none,
  required,
  authenticating,
  authenticated,
  failed,
}

class AuthenticationStatus {
  final AuthenticationState state;
  final String? error;
  final NasServer? server;

  const AuthenticationStatus({required this.state, this.error, this.server});

  bool get isAuthenticated => state == AuthenticationState.authenticated;
  bool get requiresAuthentication => state == AuthenticationState.required;
  bool get isAuthenticating => state == AuthenticationState.authenticating;
  bool get hasFailed => state == AuthenticationState.failed;
}

/// The selected server's authentication state machine and the API client it
/// holds. Notifies its listeners on every state change and mirrors each
/// status on [stream].
class ServerAuthSession extends ChangeNotifier {
  ServerAuthSession({
    required ServerCredentialsSource credentials,
    required ApiClientManagerInterface clientManager,
    TelemetryServiceInterface? telemetry,
  }) : _credentials = credentials,
       _clientManager = clientManager,
       _telemetry = telemetry;

  final ServerCredentialsSource _credentials;
  final ApiClientManagerInterface _clientManager;
  final TelemetryServiceInterface? _telemetry;
  final StreamController<AuthenticationStatus> _controller =
      StreamController<AuthenticationStatus>.broadcast();

  NasServer? _server;
  ApiClientInterface? _client;
  AuthenticationState _state = AuthenticationState.none;
  String? _error;
  bool _disposed = false;

  NasServer? get server => _server;
  ApiClientInterface? get client => _client;
  Stream<AuthenticationStatus> get stream => _controller.stream;

  AuthenticationStatus get status =>
      AuthenticationStatus(state: _state, error: _error, server: _server);

  /// Releases the previous server's client and authenticates against
  /// [server]; `null` just deselects.
  Future<void> connect(NasServer? server) async {
    final previous = _server;
    if (previous != null) await _clientManager.releaseClient(previous.id);
    reset();
    _server = server;

    if (server != null) {
      await _authenticate(server);
    }
    if (_disposed) return;
    notifyListeners();
  }

  Future<void> retry() async {
    final server = _server;
    if (server == null) return;
    await _authenticate(server);
    notifyListeners();
  }

  Future<void> disconnect() async {
    final previous = _server;
    if (previous != null) await _clientManager.releaseClient(previous.id);
    _server = null;
    reset();
    _emit();
    notifyListeners();
  }

  /// Drops the client and authentication state but keeps the selected
  /// server, without notifying.
  void reset() {
    _client = null;
    _state = AuthenticationState.none;
    _error = null;
  }

  /// Swaps in a refreshed copy of the selected server. A copy of a server
  /// that is no longer selected is dropped, because the held client belongs
  /// to the current one.
  void replaceServer(NasServer server) {
    if (_server?.id != server.id) return;
    _server = server;
  }

  void clearServer() {
    _server = null;
    reset();
  }

  /// Rebuilds the client for [updated] with its freshly stored credentials.
  /// A `null` [updated] leaves the session unauthenticated.
  Future<void> reauthenticateWith(NasServer? updated) async {
    if (updated != null) {
      _server = updated;

      final (serverWithCreds, password) = await _credentials
          .getServerWithPassword(updated.id);
      if (serverWithCreds != null && password != null) {
        _client = await _clientManager.forceRecreateClient(
          serverWithCreds.copyWith(password: password),
        );
        _state = AuthenticationState.authenticated;
        _error = null;
        _log.info(
          'Recreated client with fresh credentials',
          attributes: {'server.id': updated.id},
        );
      } else {
        _state = AuthenticationState.required;
        _error = 'Authentication required to access server credentials';
      }
      _emit();
    }
    notifyListeners();
  }

  /// Revives the pooled connections after the app was suspended. Safe to
  /// call when nothing is connected.
  Future<void> refreshConnection() async {
    final server = _server;
    final client = _client;
    if (client == null || server == null) return;

    // Every pooled client matters, not just the selected server's: other
    // providers hold clients the OS dropped just the same.
    final failures = await _clientManager.ensureAllConnectionsAlive();

    // The user may have switched servers (or the client may have been
    // recreated) while recovery ran; its result would describe the wrong one.
    if (!identical(_client, client) || _server?.id != server.id) return;

    final failure = failures[server.id];
    if (failure == null) {
      _state = AuthenticationState.authenticated;
      _error = null;
    } else {
      _state = AuthenticationState.failed;
      _error = 'Connection lost: $failure';
      _log.error('Failed to refresh connection', error: failure);
    }

    _emit();
    notifyListeners();
  }

  Future<void> _authenticate(NasServer server) async {
    try {
      _state = AuthenticationState.authenticating;
      _error = null;
      _emit();
      notifyListeners();

      final (serverWithCreds, password) = await _credentials
          .getServerWithPassword(server.id);

      if (_disposed) return;

      if (serverWithCreds != null && password != null) {
        _client = await _clientManager.getClient(
          serverWithCreds.copyWith(password: password),
        );
        _state = AuthenticationState.authenticated;
        _error = null;
        _log.info(
          'Authenticated and connected',
          attributes: {'server.id': server.id},
        );
      } else {
        _state = AuthenticationState.required;
        _error = 'Authentication required to access server credentials';
        _log.debug(
          'Authentication required',
          attributes: {'server.id': server.id},
        );
      }
    } catch (e, stackTrace) {
      _state = AuthenticationState.failed;
      _error = 'Authentication failed: ${e.toString()}';
      _telemetry?.recordError(
        e,
        stackTrace,
        context: 'ServerAuthSession._authenticate',
      );
    }
    _emit();
  }

  void _emit() {
    if (_disposed || _controller.isClosed) return;
    _controller.add(status);
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final server = _server;
    if (server != null) {
      _clientManager.releaseClient(server.id);
    }
    _controller.close();
    super.dispose();
  }
}
