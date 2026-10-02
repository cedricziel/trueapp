import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/services/api_client_manager_interface.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/telemetry_service_interface.dart';
import 'package:truehub/services/unified_server_service.dart';
import 'package:truehub/services/app_logger.dart';
import 'package:truehub/services/server_auth_session.dart';
import 'package:truehub/services/tray_status_ports.dart';

export 'package:truehub/services/server_auth_session.dart'
    show AuthenticationState, AuthenticationStatus;

final _log = appLogger('providers.server');

class ServerProvider extends ChangeNotifier implements TrayServerSource {
  final UnifiedServerService _serverService;
  final ApiClientManagerInterface _clientManager;
  final ServersDaoSource? _serversDaoSource;
  final TelemetryServiceInterface? _telemetryService;
  List<models.NasServer> _servers = [];
  final ServerAuthSession _auth;

  bool _isLoadingServers = true;

  late StreamSubscription<List<models.NasServer>> _serversSubscription;
  bool _disposed = false;

  /// [serversDaoSource] is used to clean up the local `nas_servers`
  /// foreign-key anchor row (see [ServersDao.upsertServerAnchor]) on server
  /// deletion. It has no default - callers that want that cleanup pass one
  /// explicitly (see `AppDependencies`); left null, deletion skips it.
  ServerProvider(
    this._serverService, {
    required ApiClientManagerInterface clientManager,
    ServersDaoSource? serversDaoSource,
    TelemetryServiceInterface? telemetryService,
  }) : _clientManager = clientManager,
       _serversDaoSource = serversDaoSource,
       _telemetryService = telemetryService,
       _auth = ServerAuthSession(
         credentials: _serverService,
         clientManager: clientManager,
         telemetry: telemetryService,
       ) {
    _auth.addListener(notifyListeners);
    _initializeProvider();
  }

  void _initializeProvider() {
    // Listen to server changes from the unified service
    _serversSubscription = _serverService.serversStream.listen((servers) {
      _servers = servers;
      _isLoadingServers = false;
      notifyListeners();

      // Auto-select server if needed
      _autoSelectServer();
    });

    // Load initial servers
    _loadServers();
  }

  @override
  List<models.NasServer> get servers => _servers;
  bool get isLoadingServers => _isLoadingServers;
  models.NasServer? get selectedServer => _auth.server;

  Stream<AuthenticationStatus> get authenticationStream => _auth.stream;

  AuthenticationStatus get currentAuthStatus => _auth.status;

  Future<void> _loadServers() async {
    try {
      _servers = await _serverService.getAllServers();
      if (_disposed) return;
      _isLoadingServers = false;
      notifyListeners();
    } catch (e, stackTrace) {
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'ServerProvider._loadServers',
      );
      _isLoadingServers = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> loadServersAndAutoSelect() async {
    await _loadServers();
    await _autoSelectServer();
  }

  Future<void> _autoSelectServer() async {
    if (_disposed) return;

    if (_auth.server != null) {
      return; // Don't auto-select if server already selected
    }

    // First check for default server
    final defaultServer = await _serverService.getDefaultServer();
    if (_disposed) return;
    if (defaultServer != null) {
      await selectServer(defaultServer);
      return;
    }

    // If no default server and only one server exists, auto-select it
    if (_servers.length == 1) {
      await selectServer(_servers.first);
    }
  }

  Future<void> addServer(models.NasServer server, String password) async {
    final success = await _serverService.saveServerConfig(
      server: server,
      password: password,
    );

    if (!success) {
      throw Exception('Failed to save server configuration');
    }
  }

  Future<void> updateServer(models.NasServer server, {String? password}) async {
    bool success;

    if (password != null) {
      success = await _serverService.saveServerConfig(
        server: server,
        password: password,
      );
    } else {
      success = await _serverService.updateServerConfig(server);
    }

    if (!success) {
      throw Exception('Failed to update server configuration');
    }

    if (_auth.server?.id == server.id) {
      _log.debug(
        'Forcing complete client recreation for updated server',
        attributes: {'server.id': server.id},
      );

      _auth.reset();
      final updatedServer = await _serverService.getServer(server.id);
      await _auth.reauthenticateWith(updatedServer);
    } else {
      await _clientManager.closeClient(server.id);
    }
  }

  Future<void> deleteServer(String id) async {
    final success = await _serverService.deleteServerConfig(id);

    if (!success) {
      throw Exception('Failed to delete server configuration');
    }

    // The server no longer exists, so its cached client (and any live
    // websocket/keepalive timer it holds) must not survive the deletion.
    await _clientManager.closeClient(id);

    // Drop the local foreign-key anchor row too (see
    // ServersDao.upsertServerAnchor) so it doesn't linger forever on
    // platforms where the real server metadata lives in CloudKit; this
    // cascade-deletes any app_configs left over for the server as well.
    final serversDaoSource = _serversDaoSource;
    if (serversDaoSource != null) {
      try {
        await serversDaoSource.serversDao.deleteServer(id);
      } catch (e, stackTrace) {
        _telemetryService?.recordError(
          e,
          stackTrace,
          context: 'ServerProvider.deleteServer',
        );
      }
    }

    if (_auth.server?.id == id) {
      _auth.clearServer();
    }
  }

  Future<void> selectServer(models.NasServer? server) => _auth.connect(server);

  /// Static method to load credentials for any server object
  /// Can be used by other providers without needing a ServerProvider instance
  static Future<models.NasServer?> loadServerCredentials(
    models.NasServer server,
    UnifiedServerService serverService,
  ) async {
    try {
      final password = await serverService.getPassword(server.id);

      if (password != null) {
        final serverWithCreds = server.copyWith(password: password);
        return serverWithCreds;
      } else {
        _log.warn('No password found', attributes: {'server.id': server.id});
        return null;
      }
    } catch (e) {
      _log.error('Error loading server credentials', error: e);
      return null;
    }
  }

  Future<void> retryAuthentication() => _auth.retry();

  Future<void> clearSelectedServer() => _auth.disconnect();

  @override
  Future<void> refreshSelectedServer() async {
    final selected = _auth.server;
    if (selected == null) return;
    final updated = await _serverService.getServer(selected.id);
    if (updated != null) {
      _auth.replaceServer(updated);
      notifyListeners();
    }
  }

  /// Revives the connection after the app was suspended and refreshes what the
  /// screens display. Safe to call when nothing is connected.
  Future<void> refreshConnection() => _auth.refreshConnection();

  Future<bool> testServerConnection(models.NasServer server) async {
    try {
      // For testing, use the credentials passed in the server object
      if (server.username.isEmpty || server.password.isEmpty) {
        _log.debug('Username or password empty for connection test');
        return false;
      }

      final apiClient = TrueNasApiClient(server, null);
      final result = await apiClient.testConnection();
      await apiClient.close();
      return result;
    } catch (e, stackTrace) {
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'ServerProvider.testServerConnection',
      );
      return false;
    }
  }

  Future<bool> validateServerCredentials(models.NasServer server) async {
    try {
      // For validation, use the credentials passed in the server object
      if (server.username.isEmpty || server.password.isEmpty) {
        _log.debug('Username or password empty for credential validation');
        return false;
      }

      final apiClient = TrueNasApiClient(server, null);
      final result = await apiClient
          .validateLogin(server.username, server.password)
          .timeout(const Duration(seconds: 15));
      await apiClient.close();
      return result;
    } catch (e, stackTrace) {
      _telemetryService?.recordError(
        e,
        stackTrace,
        context: 'ServerProvider.validateServerCredentials',
      );
      return false;
    }
  }

  Future<void> setDefaultServer(String serverId) async {
    final success = await _serverService.setDefaultServer(serverId);
    if (!success) {
      throw Exception('Failed to set default server');
    }
  }

  Future<void> clearDefaultServer() async {
    final success = await _serverService.clearDefaultServer();
    if (!success) {
      throw Exception('Failed to clear default server');
    }
  }

  models.NasServer? get defaultServer {
    try {
      return _servers.firstWhere((server) => server.isDefault);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(notifyListeners);
    _auth.dispose();
    _serversSubscription.cancel();
    super.dispose();
  }
}
