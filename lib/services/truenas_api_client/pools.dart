part of '../truenas_api_client.dart';

mixin _PoolsOps on _ClientTransport implements PoolsApi {
  Future<List<Map<String, dynamic>>> _queryPools() async {
    try {
      final result = await _sendRequest('pool.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<List<Pool>> getPools() async {
    try {
      return (await _queryPools()).map(Pool.fromJson).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
}
