import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/services/truenas_api_service.dart';

class ServerProvider extends ChangeNotifier {
  final AppDatabase _database;
  List<models.NasServer> _servers = [];
  models.NasServer? _selectedServer;
  TrueNasApiService? _apiService;
  ServerHealth? _serverHealth;
  bool _isLoadingHealth = false;
  String? _healthError;

  ServerProvider(this._database) {
    loadServers();
  }

  List<models.NasServer> get servers => _servers;
  models.NasServer? get selectedServer => _selectedServer;
  ServerHealth? get serverHealth => _serverHealth;
  bool get isLoadingHealth => _isLoadingHealth;
  String? get healthError => _healthError;

  Future<void> loadServers() async {
    _servers = await _database.getAllServers();
    notifyListeners();
  }

  Future<void> addServer(models.NasServer server) async {
    await _database.insertServer(server);
    await loadServers();
  }

  Future<void> updateServer(models.NasServer server) async {
    await _database.updateServer(server);
    await loadServers();
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
    _apiService?.close();
    _apiService = server != null ? TrueNasApiService(server) : null;
    _serverHealth = null;
    _healthError = null;
    
    if (server != null) {
      _database.updateLastConnected(server.id);
    }
    notifyListeners();
  }

  Future<void> refreshSelectedServer() async {
    if (_selectedServer != null) {
      final updated = await _database.getServer(_selectedServer!.id);
      if (updated != null) {
        _selectedServer = updated;
        notifyListeners();
      }
    }
  }

  Future<void> loadServerHealth() async {
    if (_apiService == null) return;

    _isLoadingHealth = true;
    _healthError = null;
    notifyListeners();

    try {
      _serverHealth = await _apiService!.getSystemHealth();
    } catch (e) {
      _healthError = e.toString();
    } finally {
      _isLoadingHealth = false;
      notifyListeners();
    }
  }

  Future<bool> testServerConnection(models.NasServer server) async {
    try {
      final apiService = TrueNasApiService(server);
      final result = await apiService.testConnection();
      await apiService.close();
      return result;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _apiService?.close();
    super.dispose();
  }
}