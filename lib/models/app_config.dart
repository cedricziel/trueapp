import 'package:equatable/equatable.dart';

class AppPortConfig extends Equatable {
  final int? id;
  final int portNumber;
  final String protocol;
  final String? serviceName;
  final String? customUrl;
  final bool isPrimary;
  final bool isEnabled;

  const AppPortConfig({
    this.id,
    required this.portNumber,
    this.protocol = 'http',
    this.serviceName,
    this.customUrl,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  String get defaultUrl => '$protocol://localhost:$portNumber';
  String get effectiveUrl => customUrl ?? defaultUrl;
  String get displayName => serviceName ?? 'Port $portNumber';

  AppPortConfig copyWith({
    int? id,
    int? portNumber,
    String? protocol,
    String? serviceName,
    String? customUrl,
    bool? isPrimary,
    bool? isEnabled,
  }) {
    return AppPortConfig(
      id: id ?? this.id,
      portNumber: portNumber ?? this.portNumber,
      protocol: protocol ?? this.protocol,
      serviceName: serviceName ?? this.serviceName,
      customUrl: customUrl ?? this.customUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [
    id,
    portNumber,
    protocol,
    serviceName,
    customUrl,
    isPrimary,
    isEnabled,
  ];
}

class AppConfig extends Equatable {
  final int? id;
  final String serverId;
  final String appName;
  final String? displayName;
  final String? iconUrl;
  final bool isEnabled;
  final bool isFavorite;
  final List<AppPortConfig> ports;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppConfig({
    this.id,
    required this.serverId,
    required this.appName,
    this.displayName,
    this.iconUrl,
    this.isEnabled = true,
    this.isFavorite = false,
    this.ports = const [],
    this.createdAt,
    this.updatedAt,
  });

  String get effectiveDisplayName => displayName ?? appName;
  AppPortConfig? get primaryPort {
    try {
      return ports.firstWhere((port) => port.isPrimary && port.isEnabled);
    } catch (e) {
      return ports.isNotEmpty ? ports.first : null;
    }
  }

  List<AppPortConfig> get enabledPorts =>
      ports.where((port) => port.isEnabled).toList();

  AppConfig copyWith({
    int? id,
    String? serverId,
    String? appName,
    String? displayName,
    String? iconUrl,
    bool? isEnabled,
    bool? isFavorite,
    List<AppPortConfig>? ports,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppConfig(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      appName: appName ?? this.appName,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      isFavorite: isFavorite ?? this.isFavorite,
      ports: ports ?? this.ports,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    serverId,
    appName,
    displayName,
    iconUrl,
    isEnabled,
    isFavorite,
    ports,
    createdAt,
    updatedAt,
  ];
}
