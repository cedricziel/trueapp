part of '../truenas_api_client.dart';

mixin _FilesOps on _ClientTransport implements FilesApi {
  Future<List<Map<String, dynamic>>> _listDirectory(String path) async {
    try {
      final result = await _sendRequest('filesystem.listdir', {'path': path});
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<FileItem>> getDirectoryListing(String path) async {
    try {
      final response = await _listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
