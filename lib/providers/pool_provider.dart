import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

class PoolProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  void setServer(NasServer? server) {
    _apiClient?.close();
    _apiClient = server != null ? TrueNasApiClient(server) : null;
    _pools = [];
    _connectionError = null;
    notifyListeners();
  }

  void setApiClient(NasServer server) {
    _apiClient?.close();
    _apiClient = TrueNasApiClient(server);
    _pools = [];
    _connectionError = null;
    notifyListeners();
  }

  Future<void> loadPools() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      _pools = await _apiClient!.getPools();
      // Clear any previous errors on successful load
      _connectionError = null;
    } on ConnectionException catch (e) {
      _connectionError = e.error;
    } catch (e) {
      // Handle unexpected errors
      _connectionError = ConnectionError.unknown(details: e.toString());
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
