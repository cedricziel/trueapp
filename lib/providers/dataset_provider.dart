import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_service.dart';

class DatasetProvider extends ChangeNotifier {
  TrueNasApiService? _apiService;
  List<Map<String, dynamic>> _datasets = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get datasets => _datasets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) {
    _apiService?.close();
    _apiService = server != null ? TrueNasApiService(server) : null;
    _datasets = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadDatasets() async {
    if (_apiService == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _datasets = await _apiService!.getDatasetList();
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
    _apiService?.close();
    super.dispose();
  }
}