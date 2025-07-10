import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';

class PoolProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  List<Map<String, dynamic>> _pools = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  List<Map<String, dynamic>> get pools => _pools;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _pools = [];
    _connectionError = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
      } catch (e) {
        if (kDebugMode) {
          print('PoolProvider: Failed to get API client: $e');
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
    _pools = [];
    _connectionError = null;

    try {
      _apiClient = await ApiClientManager.getClient(server);
    } catch (e) {
      if (kDebugMode) {
        print('PoolProvider: Failed to get API client: $e');
      }
    }
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
    if (_currentServerId != null) {
      // Note: We can't await in dispose, so we do a fire-and-forget cleanup
      ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
