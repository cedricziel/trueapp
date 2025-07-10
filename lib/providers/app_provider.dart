import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/connection_error.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';
import 'package:truenas_manager/services/api_client_manager.dart';

class AppProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  String? _currentServerId;
  List<App> _apps = [];
  List<String> _categories = [];
  bool _isLoading = false;
  ConnectionError? _connectionError;

  List<App> get apps => _apps;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  ConnectionError? get connectionError => _connectionError;
  String? get error => _connectionError?.shortMessage;

  List<App> get installedApps => _apps.where((app) => app.installed).toList();
  List<App> get availableApps => _apps.where((app) => !app.installed).toList();

  void setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _apps = [];
    _categories = [];
    _connectionError = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
      } catch (e) {
        if (kDebugMode) {
          print('AppProvider: Failed to get API client: $e');
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
    _apps = [];
    _categories = [];
    _connectionError = null;

    try {
      _apiClient = await ApiClientManager.getClient(server);
    } catch (e) {
      if (kDebugMode) {
        print('AppProvider: Failed to get API client: $e');
      }
    }
    notifyListeners();
  }

  Future<void> loadApps() async {
    if (_apiClient == null) return;

    _isLoading = true;
    _connectionError = null;
    notifyListeners();

    try {
      // Load apps and categories in parallel
      final results = await Future.wait([
        _apiClient!.getAvailableApps(),
        _apiClient!.getAppCategories(),
      ]);

      _apps = results[0] as List<App>;
      _categories = results[1] as List<String>;

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

  Future<void> refreshApps() async {
    await loadApps();
  }

  List<App> getAppsByCategory(String category) {
    return _apps.where((app) => app.categories.contains(category)).toList();
  }

  @override
  void dispose() async {
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }
    super.dispose();
  }
}
