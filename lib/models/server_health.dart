import 'package:equatable/equatable.dart';

class ServerHealth extends Equatable {
  final String serverId;
  final DateTime timestamp;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final int temperature;
  final bool isOnline;
  final List<DiskInfo> disks;
  final NetworkInfo network;

  const ServerHealth({
    required this.serverId,
    required this.timestamp,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.temperature,
    required this.isOnline,
    required this.disks,
    required this.network,
  });

  @override
  List<Object?> get props => [
        serverId,
        timestamp,
        cpuUsage,
        memoryUsage,
        diskUsage,
        temperature,
        isOnline,
        disks,
        network,
      ];
}

class DiskInfo extends Equatable {
  final String name;
  final String model;
  final String serial;
  final int size;
  final int used;
  final int temperature;
  final String health;

  const DiskInfo({
    required this.name,
    required this.model,
    required this.serial,
    required this.size,
    required this.used,
    required this.temperature,
    required this.health,
  });

  double get usagePercentage => (used / size) * 100;

  @override
  List<Object?> get props => [
        name,
        model,
        serial,
        size,
        used,
        temperature,
        health,
      ];
}

class NetworkInfo extends Equatable {
  final int downloadSpeed;
  final int uploadSpeed;
  final int totalDownload;
  final int totalUpload;

  const NetworkInfo({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.totalDownload,
    required this.totalUpload,
  });

  @override
  List<Object?> get props => [
        downloadSpeed,
        uploadSpeed,
        totalDownload,
        totalUpload,
      ];
}