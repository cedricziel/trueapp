import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/truenas_api_client.dart';
import 'package:truehub/services/api_client_manager.dart';

class DatasetProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setServer(NasServer? server) async {
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

  Future<void> setApiClient(NasServer server) async {
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
  void dispose() {
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
