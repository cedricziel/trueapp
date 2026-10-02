part of '../truenas_api_client.dart';

mixin _DatasetsOps on _ClientTransport implements DatasetsApi {
  Future<List<Map<String, dynamic>>> _queryDatasets() async {
    try {
      final result = await _sendRequest('pool.dataset.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await _queryDatasets();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
