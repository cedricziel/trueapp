import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/file_item.dart';
import 'package:truenas_manager/services/truenas_api_client.dart';

class FileProvider extends ChangeNotifier {
  TrueNasApiClient? _apiClient;
  List<FileItem> _files = [];
  String _currentPath = '/';
  bool _isLoading = false;
  String? _error;

  List<FileItem> get files => _files;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setServer(NasServer? server) {
    _apiClient?.close();
    _apiClient = server != null ? TrueNasApiClient(server) : null;
    _files = [];
    _currentPath = '/';
    _error = null;
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
    _apiClient?.close();
    super.dispose();
  }
}
