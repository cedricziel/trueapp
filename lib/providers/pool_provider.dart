import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_service.dart';

class PoolProvider extends ChangeNotifier {
  TrueNasApiService? _apiService;
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) {
    _apiService?.close();
    _apiService = server != null ? TrueNasApiService(server) : null;
    _pools = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadPools() async {
    if (_apiService == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pools = await _apiService!.getPoolList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPools() async {
    await loadPools();
  }

  @override
  void dispose() {
    _apiService?.close();
    super.dispose();
  }
}