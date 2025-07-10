import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

class PoolProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) {
    _apiClient?.close();
    _apiClient = server != null ? TrueNasApiClient(server) : null;
    _pools = [];
    _error = null;
    notifyListeners();
  }

  Future<void> loadPools() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pools = await _apiClient!.getPools();
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
    _apiClient?.close();
    super.dispose();
  }
}