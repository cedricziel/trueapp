import 'package:json_rpc_codegen/json_rpc_codegen.dart';

part 'truenas_rpc_interface.g.dart';

@jsonRpc
abstract class _TrueNasRpcInterface {
  // Authentication methods
  bool login(String username, String password, [String? otpToken]);

  // System information methods
  Map<String, dynamic> getSystemInfo();

  // System health methods
  Map<String, dynamic> getSystemCpuInfo();
  Map<String, dynamic> getSystemMemoryInfo();
  double getSystemTemperature();

  // Pool management methods
  List<Map<String, dynamic>> queryPools();
  Map<String, dynamic> getPoolById(String id);

  // Dataset management methods
  List<Map<String, dynamic>> queryDatasets();
  Map<String, dynamic> getDatasetById(String id);

  // File system methods
  List<Map<String, dynamic>> listDirectory(String path);
  Map<String, dynamic> getFileInfo(String path);

  // Disk information methods
  List<Map<String, dynamic>> queryDisks();
  Map<String, dynamic> getDiskById(String id);

  // Network information methods
  Map<String, dynamic> getNetworkInfo();
  List<Map<String, dynamic>> getNetworkInterfaces();
}
