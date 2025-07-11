import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/user_info.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';
import 'package:truenas_manager/services/secure_storage_service.dart';
import 'package:truenas_manager/services/credential_migration_service.dart';

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
  final AppDatabase _database;
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

  ServerProvider(this._database) {
    loadServers();
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

  Future<void> loadServers() async {
    _servers = await _database.getAllServers();

    // Debug credential migration status
    if (kDebugMode) {
      await CredentialMigrationService.debugStoredCredentials(_database);
      await SecureStorageService.debugListStoredKeys();
    }

    notifyListeners();
  }

  Future<void> loadServersAndAutoSelect() async {
    await loadServers();
    await _autoSelectServer();
  }

  Future<void> _autoSelectServer() async {
    if (_selectedServer != null) {
      return; // Don't auto-select if server already selected
    }

    // First check for default server
    final defaultServer = await _database.getDefaultServer();
    if (defaultServer != null) {
      selectServer(defaultServer);
      return;
    }

    // If no default server and only one server exists, auto-select it
    if (_servers.length == 1) {
      selectServer(_servers.first);
    }
  }

  Future<void> addServer(models.NasServer server) async {
    await _database.insertServer(server);
    await loadServers();
  }

  Future<void> updateServer(models.NasServer server) async {
    await _database.updateServer(server);
    await loadServers();

    // If this is the currently selected server, refresh it
    if (_selectedServer?.id == server.id) {
      await refreshSelectedServer();
    }
  }

  Future<void> deleteServer(String id) async {
    await _database.deleteServer(id);
    if (_selectedServer?.id == id) {
      _selectedServer = null;
    }
    await loadServers();
  }

  Future<void> selectServer(models.NasServer? server) async {
    // Release previous client if any
    if (_selectedServer != null) {
      await ApiClientManager.releaseClient(_selectedServer!.id);
    }

    // Reset state
    _selectedServer = server;
    _apiClient = null;
    _authState = AuthenticationState.none;
    _authError = null;
    _serverHealth = null;
    _healthError = null;
    _currentUser = null;
    _userError = null;

    if (server != null) {
      await _authenticateAndConnect(server);
    }
    notifyListeners();
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

      // Get credentials from secure storage
      final credentials = await SecureStorageService.getCredentials(
        serverId: server.id,
      );

      if (credentials != null) {
        // Create server with credentials for API client
        final serverWithCredentials = server.copyWith(
          username: credentials.username,
          password: credentials.password,
        );

        _apiClient = await ApiClientManager.getClient(serverWithCredentials);
        _authState = AuthenticationState.authenticated;
        _authError = null;
        _database.updateLastConnected(server.id);

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
    _apiClient = null;
    _authState = AuthenticationState.none;
    _authError = null;
    _serverHealth = null;
    _healthError = null;
    _currentUser = null;
    _userError = null;
    _emitAuthStatus();
    notifyListeners();
  }

  Future<void> refreshSelectedServer() async {
    if (_selectedServer != null) {
      final updated = await _database.getServer(_selectedServer!.id);
      if (updated != null) {
        _selectedServer = updated;
        notifyListeners();
      } else {}
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
      // Get credentials from secure storage
      final credentials = await SecureStorageService.getCredentials(
        serverId: server.id,
        requireAuthentication: false, // Don't require auth for testing
      );

      if (credentials == null) {
        if (kDebugMode) {
          print('ServerProvider: No credentials found for server ${server.id}');
        }
        return false;
      }

      final serverWithCredentials = server.copyWith(
        username: credentials.username,
        password: credentials.password,
      );

      final apiClient = TrueNasApiClient(serverWithCredentials, null);
      final result = await apiClient.testConnection();
      await apiClient.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateServerCredentials(models.NasServer server) async {
    try {
      // Get credentials from secure storage
      final credentials = await SecureStorageService.getCredentials(
        serverId: server.id,
        requireAuthentication: false, // Don't require auth for validation
      );

      if (credentials == null) {
        if (kDebugMode) {
          print('ServerProvider: No credentials found for server ${server.id}');
        }
        return false;
      }

      final serverWithCredentials = server.copyWith(
        username: credentials.username,
        password: credentials.password,
      );

      final apiClient = TrueNasApiClient(serverWithCredentials, null);
      final result = await apiClient
          .validateLogin(credentials.username, credentials.password)
          .timeout(const Duration(seconds: 15));
      await apiClient.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> setDefaultServer(String serverId) async {
    await _database.setDefaultServer(serverId);
    await loadServers();
  }

  Future<void> clearDefaultServer() async {
    await _database.clearDefaultServer();
    await loadServers();
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
    _authController.close();
    super.dispose();
  }
}
