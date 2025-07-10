import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class NasServer extends Equatable {
  final String id;
  final String name;
  final String host;
  final String? localUrl;
  final List<String> trustedWifiSsids;
  final int? port;
  final String username;
  final String password;
  final bool useHttps;
  final bool allowUntrustedCertificates;
  final DateTime? lastConnected;
  final bool isActive;
  final bool isDefault;

  const NasServer({
    required this.id,
    required this.name,
    required this.host,
    this.localUrl,
    this.trustedWifiSsids = const [],
    this.port,
    required this.username,
    required this.password,
    this.useHttps = true,
    this.allowUntrustedCertificates = false,
    this.lastConnected,
    this.isActive = true,
    this.isDefault = false,
  });

  factory NasServer.create({
    required String name,
    required String host,
    String? localUrl,
    List<String> trustedWifiSsids = const [],
    int? port,
    required String username,
    required String password,
    bool useHttps = true,
    bool allowUntrustedCertificates = false,
    bool isDefault = false,
  }) {
    return NasServer(
      id: const Uuid().v4(),
      name: name,
      host: host,
      localUrl: localUrl,
      trustedWifiSsids: trustedWifiSsids,
      port: port,
      username: username,
      password: password,
      useHttps: useHttps,
      allowUntrustedCertificates: allowUntrustedCertificates,
      isDefault: isDefault,
    );
  }

  NasServer copyWith({
    String? id,
    String? name,
    String? host,
    String? localUrl,
    List<String>? trustedWifiSsids,
    int? port,
    String? username,
    String? password,
    bool? useHttps,
    bool? allowUntrustedCertificates,
    DateTime? lastConnected,
    bool? isActive,
    bool? isDefault,
    // Special flag to explicitly clear localUrl
    bool clearLocalUrl = false,
    // Special flag to explicitly clear port
    bool clearPort = false,
  }) {
    return NasServer(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      localUrl: clearLocalUrl ? null : (localUrl ?? this.localUrl),
      trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
      port: clearPort ? null : (port ?? this.port),
      username: username ?? this.username,
      password: password ?? this.password,
      useHttps: useHttps ?? this.useHttps,
      allowUntrustedCertificates:
          allowUntrustedCertificates ?? this.allowUntrustedCertificates,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get baseUrl {
    final defaultPort = useHttps ? 443 : 80;
    final actualPort = port ?? defaultPort;

    // Debug logging to help troubleshoot URL composition issues
    if (kDebugMode) {
      print(
        'BaseURL Debug: host=$host, useHttps=$useHttps, port=$port, defaultPort=$defaultPort, actualPort=$actualPort',
      );
    }

    return '${useHttps ? 'https' : 'http'}://$host:$actualPort';
  }

  /// Get the effective port, handling null as default
  int get effectivePort => port ?? (useHttps ? 443 : 80);

  /// Get the appropriate URL to use based on network context
  /// Returns localUrl if available and on trusted network, otherwise returns baseUrl
  String getUrlForNetwork({required bool isOnTrustedNetwork}) {
    if (isOnTrustedNetwork && localUrl != null && localUrl!.isNotEmpty) {
      return localUrl!;
    }
    return baseUrl;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    host,
    localUrl,
    trustedWifiSsids,
    port,
    username,
    password,
    useHttps,
    allowUntrustedCertificates,
    lastConnected,
    isActive,
    isDefault,
  ];
}
