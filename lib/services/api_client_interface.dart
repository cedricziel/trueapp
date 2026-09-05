import 'dart:async';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/user_info.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/models/job.dart';
import 'package:truehub/models/system_stats.dart';

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

  // Health center methods
  Future<List<Map<String, dynamic>>> getAlerts();
  Future<List<Map<String, dynamic>>> getServices();

  // App management methods
  Future<List<App>> getAvailableApps();
  Future<List<App>> getInstalledApps();
  Future<List<String>> getAppCategories();
  Future<Map<String, dynamic>> getDockerStatus();
  Future<Map<String, dynamic>> getAppResourceUsage(String appName);
  Future<Map<String, dynamic>> getAppUpgradeInfo(String appName);
  Future<bool> upgradeApp(String appName, {String? version});
  Future<bool> startApp(String appName);
  Future<bool> stopApp(String appName);
  Future<bool> restartApp(String appName);

  // System stats subscription methods
  Stream<SystemStats> get systemStatsStream;

  /// Verify the connection is still usable and recover it if it is not.
  /// Called when the app returns to the foreground.
  Future<void> ensureConnectionAlive();

  Future<void> subscribeToSystemStats();
  Future<void> unsubscribeFromSystemStats();

  // App stats subscription methods
  Stream<Map<String, AppResourceUsage>> get appStatsStream;
  Future<void> subscribeToAppStats();
  Future<void> unsubscribeFromAppStats();

  // Additional system information methods
  Future<Map<String, dynamic>> getSystemGeneralConfig();
  Future<Map<String, dynamic>> getSystemAdvancedConfig();
  Future<String> getSystemProductType();
  Future<bool> isIxHardware();

  // Job management methods
  Stream<List<Job>> get jobsStream;
  Future<List<Job>> getJobs();
  Future<void> subscribeToJobs();
  Future<void> unsubscribeFromJobs();
  Future<void> abortJob(int jobId);

  /// Re-submits a finished job's original call, e.g. to retry a failed one.
  /// Returns the new job's id.
  Future<int> rerunJob(Job job);
}
