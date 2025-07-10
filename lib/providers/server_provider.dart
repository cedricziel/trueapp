import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/user_info.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

class ServerProvider extends ChangeNotifier {
  final AppDatabase _database;
  List<models.NasServer> _servers = [];
  models.NasServer? _selectedServer;
  TrueNasApiClient? _apiClient;
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
  ServerHealth? get serverHealth => _serverHealth;
  bool get isLoadingHealth => _isLoadingHealth;
  String? get healthError => _healthError;
  UserInfo? get currentUser => _currentUser;
  bool get isLoadingUser => _isLoadingUser;
  String? get userError => _userError;

  Future<void> loadServers() async {
    _servers = await _database.getAllServers();
    notifyListeners();
  }

  Future<void> addServer(models.NasServer server) async {
    await _database.insertServer(server);
    await loadServers();
  }

  Future<void> updateServer(models.NasServer server) async {
    print(
      'ServerProvider.updateServer: Starting update for server ${server.id}',
    );
    print('  Current selected server: ${_selectedServer?.id}');

    await _database.updateServer(server);
    await loadServers();

    // If this is the currently selected server, refresh it
    if (_selectedServer?.id == server.id) {
      print('  Server is currently selected, refreshing...');
      await refreshSelectedServer();
    }

    print('  Update complete');
  }

  Future<void> deleteServer(String id) async {
    await _database.deleteServer(id);
    if (_selectedServer?.id == id) {
      _selectedServer = null;
    }
    await loadServers();
  }

  void selectServer(models.NasServer? server) {
    _selectedServer = server;
    _apiClient?.close();
    _apiClient = server != null ? TrueNasApiClient(server) : null;
    _serverHealth = null;
    _healthError = null;
    _currentUser = null;
    _userError = null;

    if (server != null) {
      _database.updateLastConnected(server.id);
    }
    notifyListeners();
  }

  void clearSelectedServer() {
    _selectedServer = null;
    _apiClient?.close();
    _apiClient = null;
    _serverHealth = null;
    _healthError = null;
    _currentUser = null;
    _userError = null;
    notifyListeners();
  }

  Future<void> refreshSelectedServer() async {
    if (_selectedServer != null) {
      print(
        'ServerProvider.refreshSelectedServer: Refreshing server ${_selectedServer!.id}',
      );
      final updated = await _database.getServer(_selectedServer!.id);
      if (updated != null) {
        print('  Updated server loaded from database');
        print('  localUrl: ${updated.localUrl}');
        _selectedServer = updated;
        notifyListeners();
      } else {
        print('  Server not found in database!');
      }
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
      final apiClient = TrueNasApiClient(server);
      final result = await apiClient.testConnection();
      await apiClient.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<bool> validateServerCredentials(models.NasServer server) async {
    try {
      final apiClient = TrueNasApiClient(server);
      final result = await apiClient
          .validateLogin(server.username, server.password)
          .timeout(const Duration(seconds: 15));
      await apiClient.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _apiClient?.close();
    super.dispose();
  }
}
