import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/file_item.dart';

class TrueNasApiService {
  late Client _client;
  final NasServer _server;
  final Dio _dio;

  TrueNasApiService(this._server) : _dio = Dio() {
    _setupClient();
  }

  void _setupClient() {
    final channel = _DioJsonRpcChannel(_dio, _server);
    _client = Client(channel);
  }

  Future<void> close() async {
    await _client.close();
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final response = await _client.sendRequest('system.info');
      return response as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<ServerHealth> getSystemHealth() async {
    try {
      final systemInfo = await getSystemInfo();
      final cpuInfo = await _client.sendRequest('system.cpu_info');
      final memoryInfo = await _client.sendRequest('system.memory_info');
      final diskInfo = await _client.sendRequest('disk.query');
      
      return ServerHealth(
        cpuUsage: _extractCpuUsage(cpuInfo),
        memoryUsage: _extractMemoryUsage(memoryInfo),
        diskUsage: _extractDiskUsage(diskInfo),
        temperature: _extractTemperature(systemInfo),
        networkLoad: _extractNetworkLoad(systemInfo),
        uptime: _extractUptime(systemInfo),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FileItem>> getFileList(String path) async {
    try {
      final response = await _client.sendRequest('filesystem.listdir', {'path': path});
      final List<dynamic> items = response as List<dynamic>;
      
      return items.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPoolList() async {
    try {
      final response = await _client.sendRequest('pool.query');
      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDatasetList() async {
    try {
      final response = await _client.sendRequest('pool.dataset.query');
      return (response as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> testConnection() async {
    try {
      await getSystemInfo();
      return true;
    } catch (e) {
      return false;
    }
  }

  double _extractCpuUsage(dynamic cpuInfo) {
    if (cpuInfo is Map<String, dynamic>) {
      return (cpuInfo['usage'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  double _extractMemoryUsage(dynamic memoryInfo) {
    if (memoryInfo is Map<String, dynamic>) {
      final used = (memoryInfo['used'] as num?)?.toDouble() ?? 0.0;
      final total = (memoryInfo['total'] as num?)?.toDouble() ?? 1.0;
      return (used / total) * 100;
    }
    return 0.0;
  }

  double _extractDiskUsage(dynamic diskInfo) {
    if (diskInfo is List<dynamic> && diskInfo.isNotEmpty) {
      final disk = diskInfo.first as Map<String, dynamic>;
      final used = (disk['used'] as num?)?.toDouble() ?? 0.0;
      final total = (disk['size'] as num?)?.toDouble() ?? 1.0;
      return (used / total) * 100;
    }
    return 0.0;
  }

  double _extractTemperature(dynamic systemInfo) {
    if (systemInfo is Map<String, dynamic>) {
      return (systemInfo['temperature'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  double _extractNetworkLoad(dynamic systemInfo) {
    if (systemInfo is Map<String, dynamic>) {
      return (systemInfo['network_load'] as num?)?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  String _extractUptime(dynamic systemInfo) {
    if (systemInfo is Map<String, dynamic>) {
      final uptime = systemInfo['uptime'] as String?;
      return uptime ?? 'Unknown';
    }
    return 'Unknown';
  }

  Exception _handleError(dynamic error) {
    if (error is RpcException) {
      return Exception('TrueNAS API Error: ${error.message}');
    }
    return Exception('Connection Error: $error');
  }
}

class _DioJsonRpcChannel extends StreamChannel<String> {
  final Dio _dio;
  final NasServer _server;
  late final StreamController<String> _controller;

  _DioJsonRpcChannel(this._dio, this._server) {
    _controller = StreamController<String>();
    _setupDio();
  }

  void _setupDio() {
    _dio.options.baseUrl = '${_server.baseUrl}/api/v2.0';
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Authorization'] = 'Basic ${_getAuthHeader()}';
    _dio.options.timeout = const Duration(seconds: 30);
  }

  String _getAuthHeader() {
    final credentials = '${_server.username}:${_server.password}';
    return base64Encode(utf8.encode(credentials));
  }

  @override
  StreamSink<String> get sink => _StreamSinkWrapper(_sendRequest);

  @override
  Stream<String> get stream => _controller.stream;

  Future<void> _sendRequest(String request) async {
    try {
      final response = await _dio.post(
        '/call',
        data: request,
      );
      
      if (response.statusCode == 200) {
        _controller.add(response.data.toString());
      } else {
        _controller.addError('HTTP ${response.statusCode}: ${response.statusMessage}');
      }
    } catch (e) {
      _controller.addError(e);
    }
  }
}

class _StreamSinkWrapper implements StreamSink<String> {
  final Future<void> Function(String) _sendFunction;

  _StreamSinkWrapper(this._sendFunction);

  @override
  void add(String data) {
    _sendFunction(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    // Handle errors if needed
  }

  @override
  Future<void> addStream(Stream<String> stream) {
    return stream.forEach(add);
  }

  @override
  Future<void> close() async {
    // Close logic if needed
  }

  @override
  Future<void> get done => Future.value();
}