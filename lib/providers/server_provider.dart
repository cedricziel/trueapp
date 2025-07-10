import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart' as models;
import 'package:truenas_manager/services/database.dart';

class ServerProvider extends ChangeNotifier {
  final AppDatabase _database;
  List<models.NasServer> _servers = [];
  models.NasServer? _selectedServer;

  ServerProvider(this._database) {
    loadServers();
  }

  List<models.NasServer> get servers => _servers;
  models.NasServer? get selectedServer => _selectedServer;

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
}