import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';

class DatasetProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _datasets = [];
    _error = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
      } catch (e) {
        if (kDebugMode) {
          print('DatasetProvider: Failed to get API client: $e');
        }
      }
    }
    notifyListeners();
  }

  void setApiClient(NasServer server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server.id;
    _datasets = [];
    _error = null;

    try {
      _apiClient = await ApiClientManager.getClient(server);
    } catch (e) {
      if (kDebugMode) {
        print('DatasetProvider: Failed to get API client: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadDatasets() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _datasets = await _apiClient!.getDatasets();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshDatasets() async {
    await loadDatasets();
  }

  @override
  void dispose() async {
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
