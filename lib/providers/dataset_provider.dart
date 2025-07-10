import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

class DatasetProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) {
    _apiClient?.close();
    _apiClient = server != null ? TrueNasApiClient(server) : null;
    _datasets = [];
    _error = null;
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
    _apiClient?.close();
    super.dispose();
  }
}