import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/services/api_client_interface.dart';
import 'package:truehub/services/api_client_manager.dart';

class FileProvider extends ChangeNotifier {
  ApiClientInterface? _apiClient;
  String? _currentServerId;
  List<FileItem> _files = [];
  String _currentPath = '/';
  bool _isLoading = false;
  String? _error;

  List<FileItem> get files => _files;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> setServer(NasServer? server) async {
    // Release previous client if any
    if (_currentServerId != null) {
      await ApiClientManager.releaseClient(_currentServerId!);
    }

    _currentServerId = server?.id;
    _apiClient = null;
    _files = [];
    _currentPath = '/';
    _error = null;

    if (server != null) {
      try {
        _apiClient = await ApiClientManager.getClient(server);
      } catch (e) {
        if (kDebugMode) {
          print('FileProvider: Failed to get API client: $e');
        }
      }
    }
    notifyListeners();
  }

  Future<void> loadFiles(String path) async {
    if (_apiClient == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _files = await _apiClient!.getDirectoryListing(path);
      _currentPath = path;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> navigateToPath(String path) async {
    await loadFiles(path);
  }

  Future<void> navigateUp() async {
    if (_currentPath != '/') {
      final parentPath = _currentPath
          .split('/')
          .sublist(0, _currentPath.split('/').length - 1)
          .join('/');
      await loadFiles(parentPath.isEmpty ? '/' : parentPath);
    }
  }

  Future<void> refreshFiles() async {
    await loadFiles(_currentPath);
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
