import 'dart:async';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/file_item.dart';
import 'package:truenas_manager/models/user_info.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/models/system_stats.dart';

/// Interface for TrueNAS API clients to enable dependency injection and testing
abstract class ApiClientInterface {
  // Connection management
  Future<void> close();
  Future<bool> testConnection();

  // Keepalive management
  void setKeepaliveInterval(Duration interval);
  void enableKeepalive(bool enabled);
  bool get isKeepaliveActive;

  // Authentication methods
  Future<bool> validateLogin(
    String username,
    String password, [
    String? otpToken,
  ]);
  Future<UserInfo> getCurrentUser();

  // System information methods
  Future<Map<String, dynamic>> getSystemInfo();
  Future<Map<String, dynamic>> getSystemCpuInfo();
  Future<Map<String, dynamic>> getSystemMemoryInfo();
  Future<double> getSystemTemperature();

  // Pool management methods
  Future<List<Map<String, dynamic>>> queryPools();
  Future<Map<String, dynamic>> getPoolById(String id);
  Future<List<Map<String, dynamic>>> getPools();

  // Dataset management methods
  Future<List<Map<String, dynamic>>> queryDatasets();
  Future<Map<String, dynamic>> getDatasetById(String id);
  Future<List<Map<String, dynamic>>> getDatasets();

  // File system methods
  Future<List<Map<String, dynamic>>> listDirectory(String path);
  Future<Map<String, dynamic>> getFileInfo(String path);
  Future<List<FileItem>> getDirectoryListing(String path);

  // Disk information methods
  Future<List<Map<String, dynamic>>> queryDisks();
  Future<Map<String, dynamic>> getDiskById(String id);

  // Network information methods
  Future<Map<String, dynamic>> getNetworkInfo();
  Future<List<Map<String, dynamic>>> getNetworkInterfaces();

  // Higher-level methods
  Future<ServerHealth> getServerHealth();

  // App management methods
  Future<List<App>> getAvailableApps();
  Future<List<String>> getAppCategories();
  Future<Map<String, dynamic>> getDockerStatus();

  // System stats subscription methods
  Stream<SystemStats> get systemStatsStream;
  Future<void> subscribeToSystemStats();
  Future<void> unsubscribeFromSystemStats();

  // Additional system information methods
  Future<Map<String, dynamic>> getSystemGeneralConfig();
  Future<Map<String, dynamic>> getSystemAdvancedConfig();
  Future<String> getSystemProductType();
  Future<bool> isIxHardware();
}

/// Interface for API client management to enable dependency injection
abstract class ApiClientManagerInterface {
  Future<ApiClientInterface?> getClient(NasServer server);
  Future<void> releaseClient(String serverId);
  Future<void> closeClient(String serverId);
  Future<void> closeAllClients();
  ApiClientInterface? getExistingClient(String serverId);
  bool hasClient(String serverId);
  int getClientCount();
  List<String> getActiveServerIds();
  Map<String, int> getRefCounts();
}
