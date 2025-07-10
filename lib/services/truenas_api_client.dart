import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:truenas_manager/api/truenas_rpc_interface.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/file_item.dart';

class TrueNasApiClient {
  final NasServer _server;
  final Dio _dio;
  late final TrueNasRpcInterfaceClient _client;

  TrueNasApiClient(this._server) : _dio = Dio() {
    _setupClient();
  }

  void _setupClient() {
    final channel = _TrueNasHttpChannel(_dio, _server);
    _client = TrueNasRpcInterfaceClient(channel);
  }

  Future<void> close() async {
    await _client.close();
  }

  Future<ServerHealth> getServerHealth() async {
    try {
      await _client.getSystemInfo();
      final cpuInfo = await _client.getSystemCpuInfo();
      final memoryInfo = await _client.getSystemMemoryInfo();
      final diskInfo = await _client.queryDisks();
      final temperature = await _client.getSystemTemperature();
      final networkInfo = await _client.getNetworkInfo();
      
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
      final response = await _client.listDirectory(path);
      return response.map((item) => FileItem.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPools() async {
    try {
      return await _client.queryPools();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getDatasets() async {
    try {
      return await _client.queryDatasets();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> testConnection() async {
    try {
      await _client.getSystemInfo();
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