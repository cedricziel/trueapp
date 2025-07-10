import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/file_item.dart';
import 'package:truenas_manager/models/user_info.dart';

class TrueNasApiClient {
  final NasServer _server;
  final Dio _dio;
  late final Client _client;

  TrueNasApiClient(this._server) : _dio = Dio() {
    _setupClient();
  }

  void _setupClient() {
    final channel = _TrueNasHttpChannel(_dio, _server);
    _client = Client(channel);
  }

  Future<void> close() async {
    await _client.close();
  }

  // Authentication methods
  Future<bool> validateLogin(String username, String password, [String? otpToken]) async {
    try {
      final result = await _client.sendRequest(
        'auth.login',
        [username, password, if (otpToken != null) otpToken],
      );
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<UserInfo> getCurrentUser() async {
    try {
      final result = await _client.sendRequest('auth.me');
      return UserInfo.fromJson(result as Map<String, dynamic>);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // System information methods
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      final result = await _client.sendRequest('system.info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    try {
      final result = await _client.sendRequest('system.cpu_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    try {
      final result = await _client.sendRequest('system.memory_info');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<double> getSystemTemperature() async {
    try {
      final result = await _client.sendRequest('system.temperature');
      return (result as num).toDouble();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Pool management methods
  Future<List<Map<String, dynamic>>> queryPools() async {
    try {
      final result = await _client.sendRequest('pool.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getPoolById(String id) async {
    try {
      final result = await _client.sendRequest('pool.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Dataset management methods
  Future<List<Map<String, dynamic>>> queryDatasets() async {
    try {
      final result = await _client.sendRequest('pool.dataset.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDatasetById(String id) async {
    try {
      final result = await _client.sendRequest('pool.dataset.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // File system methods
  Future<List<Map<String, dynamic>>> listDirectory(String path) async {
    try {
      final result = await _client.sendRequest('filesystem.listdir', {'path': path});
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getFileInfo(String path) async {
    try {
      final result = await _client.sendRequest('filesystem.stat', {'path': path});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Disk information methods
  Future<List<Map<String, dynamic>>> queryDisks() async {
    try {
      final result = await _client.sendRequest('disk.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDiskById(String id) async {
    try {
      final result = await _client.sendRequest('disk.query', {'id': id});
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Network information methods
  Future<Map<String, dynamic>> getNetworkInfo() async {
    try {
      final result = await _client.sendRequest('network.general.summary');
      return result as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    try {
      final result = await _client.sendRequest('interface.query');
      return (result as List<dynamic>).cast<Map<String, dynamic>>();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Higher-level methods
  Future<ServerHealth> getServerHealth() async {
    try {
      await getSystemInfo();
      final cpuInfo = await getSystemCpuInfo();
      final memoryInfo = await getSystemMemoryInfo();
      final diskInfo = await queryDisks();
      final temperature = await getSystemTemperature();
      final networkInfo = await getNetworkInfo();
      
      return ServerHealth(
        serverId: _server.id,
        timestamp: DateTime.now(),
        cpuUsage: _extractCpuUsage(cpuInfo),
        memoryUsage: _extractMemoryUsage(memoryInfo),
        diskUsage: _extractDiskUsage(diskInfo),
        temperature: temperature.toInt(),
        isOnline: true,
        disks: _extractDisks(diskInfo),
        network: _extractNetwork(networkInfo),
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<FileItem>> getDirectoryListing(String path) async {
    try {
      final response = await listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPools() async {
    try {
      return await queryPools();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await queryDatasets();
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

  double _extractCpuUsage(Map<String, dynamic> cpuInfo) {
    return (cpuInfo['usage'] as num?)?.toDouble() ?? 0.0;
  }

  double _extractMemoryUsage(Map<String, dynamic> memoryInfo) {
    final used = (memoryInfo['used'] as num?)?.toDouble() ?? 0.0;
    final total = (memoryInfo['total'] as num?)?.toDouble() ?? 1.0;
    return total > 0 ? (used / total) * 100 : 0.0;
  }

  double _extractDiskUsage(List<Map<String, dynamic>> diskInfo) {
    if (diskInfo.isEmpty) return 0.0;
    
    double totalUsed = 0.0;
    double totalSize = 0.0;
    
    for (final disk in diskInfo) {
      totalUsed += (disk['used'] as num?)?.toDouble() ?? 0.0;
      totalSize += (disk['size'] as num?)?.toDouble() ?? 0.0;
    }
    
    return totalSize > 0 ? (totalUsed / totalSize) * 100 : 0.0;
  }

  List<DiskInfo> _extractDisks(List<Map<String, dynamic>> diskInfo) {
    return diskInfo.map((disk) => DiskInfo(
      name: disk['name'] as String? ?? 'Unknown',
      model: disk['model'] as String? ?? 'Unknown',
      serial: disk['serial'] as String? ?? 'Unknown',
      size: (disk['size'] as num?)?.toInt() ?? 0,
      used: (disk['used'] as num?)?.toInt() ?? 0,
      temperature: (disk['temperature'] as num?)?.toInt() ?? 0,
      health: disk['health'] as String? ?? 'Unknown',
    )).toList();
  }

  NetworkInfo _extractNetwork(Map<String, dynamic> networkInfo) {
    return NetworkInfo(
      downloadSpeed: (networkInfo['download_speed'] as num?)?.toInt() ?? 0,
      uploadSpeed: (networkInfo['upload_speed'] as num?)?.toInt() ?? 0,
      totalDownload: (networkInfo['total_download'] as num?)?.toInt() ?? 0,
      totalUpload: (networkInfo['total_upload'] as num?)?.toInt() ?? 0,
    );
  }

  Exception _handleError(dynamic error) {
    if (error is RpcException) {
      return Exception('TrueNAS RPC Error: ${error.message}');
    }
    if (error is DioException) {
      return Exception('Network Error: ${error.message}');
    }
    return Exception('API Error: $error');
  }
}

class _TrueNasHttpChannel extends StreamChannelMixin<String> {
  final Dio _dio;
  final NasServer _server;
  late final StreamController<String> _requestController;
  late final StreamController<String> _responseController;

  _TrueNasHttpChannel(this._dio, this._server) {
    _requestController = StreamController<String>();
    _responseController = StreamController<String>();
    _setupDio();
    _setupRequestHandler();
  }

  void _setupDio() {
    _dio.options.baseUrl = '${_server.baseUrl}/api/v2.0';
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.headers['Authorization'] = 'Basic ${_getAuthHeader()}';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
  }

  void _setupRequestHandler() {
    _requestController.stream.listen((request) async {
      try {
        final response = await _dio.post(
          '/call',
          data: request,
        );
        
        if (response.statusCode == 200) {
          _responseController.add(response.data is String 
              ? response.data 
              : jsonEncode(response.data));
        } else {
          _responseController.addError(
            'HTTP ${response.statusCode}: ${response.statusMessage}'
          );
        }
      } catch (e) {
        _responseController.addError(e);
      }
    });
  }

  String _getAuthHeader() {
    final credentials = '${_server.username}:${_server.password}';
    return base64Encode(utf8.encode(credentials));
  }

  @override
  StreamSink<String> get sink => _requestController.sink;

  @override
  Stream<String> get stream => _responseController.stream;
}