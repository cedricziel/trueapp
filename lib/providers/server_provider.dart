import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart' as models;
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/services/api_client_manager.dart';
import 'package:truehub/services/unified_server_service.dart';

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
  final models.NasServer? server;

  const AuthenticationStatus({required this.state, this.error, this.server});

  bool get isAuthenticated => state == AuthenticationState.authenticated;
  bool get requiresAuthentication => state == AuthenticationState.required;
  bool get isAuthenticating => state == AuthenticationState.authenticating;
  bool get hasFailed => state == AuthenticationState.failed;
}

class ServerProvider extends ChangeNotifier {
  final UnifiedServerService _serverService;
  List<models.NasServer> _servers = [];
  models.NasServer? _selectedServer;
  TrueNasApiClient? _apiClient;

  // Authentication state stream
  final StreamController<AuthenticationStatus> _authController =
      StreamController<AuthenticationStatus>.broadcast();
  AuthenticationState _authState = AuthenticationState.none;
  String? _authError;

  ServerHealth? _serverHealth;
  bool _isLoadingHealth = false;
  String? _healthError;
  UserInfo? _currentUser;
  bool _isLoadingUser = false;
  String? _userError;

  late StreamSubscription<List<models.NasServer>> _serversSubscription;

  ServerProvider(this._serverService) {
    _initializeProvider();
  }

  void _initializeProvider() {
    // Listen to server changes from the unified service
    _serversSubscription = _serverService.serversStream.listen((servers) {
      _servers = servers;
      notifyListeners();

      // Auto-select server if needed
      _autoSelectServer();
    });

    // Load initial servers
    _loadServers();
  }

  List<models.NasServer> get servers => _servers;
  models.NasServer? get selectedServer => _selectedServer;

  // Stream for authentication state
  Stream<AuthenticationStatus> get authenticationStream =>
      _authController.stream;

  // Current authentication status
  AuthenticationStatus get currentAuthStatus => AuthenticationStatus(
    state: _authState,
    error: _authError,
    server: _selectedServer,
  );

  // Legacy getters for backward compatibility
  AuthenticationState get authState => _authState;
  String? get authError => _authError;
  bool get isAuthenticated =>
      _authState == AuthenticationState.authenticated && _apiClient != null;
  bool get requiresAuthentication => _authState == AuthenticationState.required;
  bool get isAuthenticating => _authState == AuthenticationState.authenticating;

  ServerHealth? get serverHealth => _serverHealth;
  bool get isLoadingHealth => _isLoadingHealth;
  String? get healthError => _healthError;
  UserInfo? get currentUser => _currentUser;
  bool get isLoadingUser => _isLoadingUser;
  String? get userError => _userError;

  Future<void> _loadServers() async {
    try {
      _servers = await _serverService.getAllServers();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('ServerProvider: Failed to load servers: $e');
      }
    }
  }

  Future<void> loadServersAndAutoSelect() async {
    await _loadServers();
    await _autoSelectServer();
  }

  Future<void> _autoSelectServer() async {
    if (_selectedServer != null) {
      return; // Don't auto-select if server already selected
    }

    // First check for default server
    final defaultServer = await _serverService.getDefaultServer();
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

    // If this is the currently selected server, force complete re-authentication
    if (_selectedServer?.id == server.id) {
      if (kDebugMode) {
        print(
          'ServerProvider: Forcing complete client recreation for updated server ${server.id}',
        );
      }

      // Clear current authentication state
      _clearAuthState();

      // Get the fresh server data
      final updatedServer = await _serverService.getServer(server.id);
      if (updatedServer != null) {
        _selectedServer = updatedServer;

        // Force complete client recreation with fresh credentials
        final (serverWithCreds, password) = await _serverService
            .getServerWithPassword(server.id);
        if (serverWithCreds != null && password != null) {
          final serverForClient = serverWithCreds.copyWith(password: password);
          _apiClient = await ApiClientManager.forceRecreateClient(
            serverForClient,
          );
          _authState = AuthenticationState.authenticated;
          _authError = null;

          if (kDebugMode) {
            print(
              'ServerProvider: Successfully recreated client with fresh credentials for server ${server.id}',
            );
          }
        } else {
          _authState = AuthenticationState.required;
          _authError = 'Authentication required to access server credentials';
        }

        _emitAuthStatus();
      }

      notifyListeners();
    } else {
      // For non-selected servers, just close any cached client
      await ApiClientManager.closeClient(server.id);
    }
  }

  Future<void> deleteServer(String id) async {
    final success = await _serverService.deleteServerConfig(id);

    if (!success) {
      throw Exception('Failed to delete server configuration');
    }

    if (_selectedServer?.id == id) {
      _selectedServer = null;
      _clearAuthState();
    }
  }

  Future<void> selectServer(models.NasServer? server) async {
    // Release previous client if any
    if (_selectedServer != null) {
      await ApiClientManager.releaseClient(_selectedServer!.id);
    }

    // Reset state
    _clearAuthState();
    _selectedServer = server;

    if (server != null) {
      await _authenticateAndConnect(server);
    }
    notifyListeners();
  }

  void _clearAuthState() {
    _apiClient = null;
    _authState = AuthenticationState.none;
    _authError = null;
    _serverHealth = null;
    _healthError = null;
    _currentUser = null;
    _userError = null;
  }

  void _emitAuthStatus() {
    final status = AuthenticationStatus(
      state: _authState,
      error: _authError,
      server: _selectedServer,
    );
    _authController.add(status);
  }

  Future<void> _authenticateAndConnect(models.NasServer server) async {
    try {
      _authState = AuthenticationState.authenticating;
      _authError = null;
      _emitAuthStatus();
      notifyListeners();

      // Get credentials from unified server service
      final (serverWithCreds, password) = await _serverService
          .getServerWithPassword(server.id);

      if (serverWithCreds != null && password != null) {
        // Create server with credentials for API client
        final serverForClient = serverWithCreds.copyWith(password: password);

        _apiClient = await ApiClientManager.getClient(serverForClient);
        _authState = AuthenticationState.authenticated;
        _authError = null;

        if (kDebugMode) {
          print(
            'ServerProvider: Successfully authenticated and connected to server ${server.id}',
          );
        }
      } else {
        _authState = AuthenticationState.required;
        _authError = 'Authentication required to access server credentials';
        if (kDebugMode) {
          print(
            'ServerProvider: Authentication required for server ${server.id}',
          );
        }
      }
    } catch (e) {
      _authState = AuthenticationState.failed;
      _authError = 'Authentication failed: ${e.toString()}';
      if (kDebugMode) {
        print(
          'ServerProvider: Authentication failed for server ${server.id}: $e',
        );
      }
    }
    _emitAuthStatus();
  }

  /// Static method to load credentials for any server object
  /// Can be used by other providers without needing a ServerProvider instance
  static Future<models.NasServer?> loadServerCredentials(
    models.NasServer server,
    UnifiedServerService serverService,
  ) async {
    try {
      if (kDebugMode) {
        print(
          'ServerProvider: Loading credentials for ${server.name} - current username: "${server.username}"',
        );
      }

      final password = await serverService.getPassword(server.id);

      if (password != null) {
        final serverWithCreds = server.copyWith(password: password);
        if (kDebugMode) {
          print(
            'ServerProvider: Loaded credentials for ${server.name} - username: "${serverWithCreds.username}", has password: true',
          );
        }
        return serverWithCreds;
      } else {
        if (kDebugMode) {
          print('ServerProvider: No password found for server ${server.id}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ServerProvider: Error loading server credentials: $e');
      }
      return null;
    }
  }

  /// Retry authentication for the currently selected server
  Future<void> retryAuthentication() async {
    if (_selectedServer != null) {
      await _authenticateAndConnect(_selectedServer!);
      notifyListeners();
    }
  }

  Future<void> clearSelectedServer() async {
    if (_selectedServer != null) {
      await ApiClientManager.releaseClient(_selectedServer!.id);
    }

    _selectedServer = null;
    _clearAuthState();
    _emitAuthStatus();
    notifyListeners();
  }

  Future<void> refreshSelectedServer() async {
    if (_selectedServer != null) {
      final updated = await _serverService.getServer(_selectedServer!.id);
      if (updated != null) {
        _selectedServer = updated;
        notifyListeners();
      }
    }
  }

  /// Revives the connection after the app was suspended and refreshes what the
  /// screens display. Safe to call when nothing is connected.
  Future<void> refreshConnection() async {
    final server = _selectedServer;
    if (_apiClient == null || server == null) return;

    // Every pooled client matters, not just the selected server's: other
    // providers hold clients the OS dropped just the same. One round of
    // recovery covers them all and reports per-server failures.
    final failures = await ApiClientManager.ensureAllConnectionsAlive();

    final failure = failures[server.id];
    if (failure == null) {
      _authState = AuthenticationState.authenticated;
      _authError = null;
    } else {
      _authState = AuthenticationState.failed;
      _authError = 'Connection lost: $failure';
      if (kDebugMode) {
        print('ServerProvider: Failed to refresh connection: $failure');
      }
    }

    _emitAuthStatus();
    notifyListeners();

    if (_authState == AuthenticationState.authenticated) {
      await loadServerHealth();
    }
  }

  Future<void> loadServerHealth() async {
    if (_apiClient == null) return;

    _isLoadingHealth = true;
    _healthError = null;
    notifyListeners();

    try {
      _serverHealth = await _apiClient!.getServerHealth();
    } catch (e) {
      _healthError = e.toString();
    } finally {
      _isLoadingHealth = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUser() async {
    if (_apiClient == null) return;

    _isLoadingUser = true;
    _userError = null;
    notifyListeners();

    try {
      _currentUser = await _apiClient!.getCurrentUser();
    } catch (e) {
      _userError = e.toString();
    } finally {
      _isLoadingUser = false;
      notifyListeners();
    }
  }

  Future<bool> testServerConnection(models.NasServer server) async {
    try {
      // For testing, use the credentials passed in the server object
      if (server.username.isEmpty || server.password.isEmpty) {
        if (kDebugMode) {
          print(
            'ServerProvider: Username or password empty for connection test',
          );
        }
        return false;
      }

      final apiClient = TrueNasApiClient(server, null);
      final result = await apiClient.testConnection();
      await apiClient.close();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('ServerProvider: Connection test failed: $e');
      }
      return false;
    }
  }

  Future<bool> validateServerCredentials(models.NasServer server) async {
    try {
      // For validation, use the credentials passed in the server object
      if (server.username.isEmpty || server.password.isEmpty) {
        if (kDebugMode) {
          print(
            'ServerProvider: Username or password empty for credential validation',
          );
        }
        return false;
      }

      final apiClient = TrueNasApiClient(server, null);
      final result = await apiClient
          .validateLogin(server.username, server.password)
          .timeout(const Duration(seconds: 15));
      await apiClient.close();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('ServerProvider: Credential validation failed: $e');
      }
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
    if (_selectedServer != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_selectedServer!.id);
    }
    _serversSubscription.cancel();
    _authController.close();
    super.dispose();
  }
}
