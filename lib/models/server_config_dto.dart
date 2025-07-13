import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;

/// Server configuration data transfer object for CloudKit storage
/// This contains only non-sensitive server metadata
class ServerConfigDTO {
  final String id; // UUID that matches Keychain account attribute
  final String displayName;
  final String hostName;
  final String userName;
  final bool useHttps;
  final bool allowUntrustedCertificates;
  final int? port;
  final String? localUrl;
  final List<String> trustedWifiSsids;
  final DateTime? lastConnected;
  final bool isActive;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServerConfigDTO({
    String? id,
    required this.displayName,
    required this.hostName,
    required this.userName,
    required this.useHttps,
    required this.allowUntrustedCertificates,
    this.port,
    this.localUrl,
    this.trustedWifiSsids = const [],
    this.lastConnected,
    this.isActive = true,
    this.isDefault = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'hostName': hostName,
    'userName': userName,
    'useHttps': useHttps,
    'allowUntrustedCertificates': allowUntrustedCertificates,
    'port': port,
    'localUrl': localUrl,
    'trustedWifiSsids': trustedWifiSsids,
    'lastConnected': lastConnected?.toIso8601String(),
    'isActive': isActive,
    'isDefault': isDefault,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ServerConfigDTO.fromJson(Map<String, dynamic> json) {
    try {
      return ServerConfigDTO(
        id: json['id'] as String? ?? '',
        displayName: json['displayName'] as String? ?? 'Unknown Server',
        hostName: json['hostName'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
        useHttps: json['useHttps'] as bool? ?? true,
        allowUntrustedCertificates:
            json['allowUntrustedCertificates'] as bool? ?? false,
        port: json['port'] as int?,
        localUrl: json['localUrl'] as String?,
        trustedWifiSsids:
            (json['trustedWifiSsids'] as List<dynamic>?)?.cast<String>() ??
            const [],
        lastConnected: json['lastConnected'] != null
            ? DateTime.tryParse(json['lastConnected'] as String? ?? '')
            : null,
        isActive: json['isActive'] as bool? ?? true,
        isDefault: json['isDefault'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                  DateTime.now()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
                  DateTime.now()
            : DateTime.now(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('ServerConfigDTO.fromJson error: $e');
        print('JSON data: $json');
      }
      rethrow;
    }
  }

  ServerConfigDTO copyWith({
    String? id,
    String? displayName,
    String? hostName,
    String? userName,
    bool? useHttps,
    bool? allowUntrustedCertificates,
    int? port,
    String? localUrl,
    List<String>? trustedWifiSsids,
    DateTime? lastConnected,
    bool? isActive,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServerConfigDTO(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      hostName: hostName ?? this.hostName,
      userName: userName ?? this.userName,
      useHttps: useHttps ?? this.useHttps,
      allowUntrustedCertificates:
          allowUntrustedCertificates ?? this.allowUntrustedCertificates,
      port: port ?? this.port,
      localUrl: localUrl ?? this.localUrl,
      trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Create a ServerConfigDTO from a NasServer
  factory ServerConfigDTO.fromServer(NasServer server) {
    return ServerConfigDTO(
      id: server.id,
      displayName: server.name,
      hostName: server.host,
      userName: server.username,
      useHttps: server.useHttps,
      allowUntrustedCertificates: server.allowUntrustedCertificates,
      port: server.port,
      localUrl: server.localUrl,
      trustedWifiSsids: server.trustedWifiSsids,
      lastConnected: server.lastConnected,
      isActive: server.isActive,
      isDefault: server.isDefault,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Convert to plugin ServerConfigDTO
  plugins.ServerConfigDTO toPlugin() {
    return plugins.ServerConfigDTO(
      id: id,
      displayName: displayName,
      hostName: hostName,
      userName: userName,
      useHttps: useHttps,
      allowUntrustedCertificates: allowUntrustedCertificates,
      port: port,
      localUrl: localUrl,
      trustedWifiSsids: trustedWifiSsids,
      lastConnected: lastConnected,
      isActive: isActive,
      isDefault: isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Create from plugin ServerConfigDTO
  factory ServerConfigDTO.fromPlugin(plugins.ServerConfigDTO plugin) {
    return ServerConfigDTO(
      id: plugin.id,
      displayName: plugin.displayName,
      hostName: plugin.hostName,
      userName: plugin.userName,
      useHttps: plugin.useHttps,
      allowUntrustedCertificates: plugin.allowUntrustedCertificates,
      port: plugin.port,
      localUrl: plugin.localUrl,
      trustedWifiSsids: plugin.trustedWifiSsids,
      lastConnected: plugin.lastConnected,
      isActive: plugin.isActive,
      isDefault: plugin.isDefault,
      createdAt: plugin.createdAt,
      updatedAt: plugin.updatedAt,
    );
  }
}
