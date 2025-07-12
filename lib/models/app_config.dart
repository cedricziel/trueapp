import 'package:equatable/equatable.dart';
import 'app.dart';

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

  // Basic app metadata for offline access
  final String? title;
  final String? description;
  final bool? installed;
  final bool? healthy;
  final String? healthyError;
  final String? version;
  final String? appVersion;
  final String? humanVersion;
  final List<String>? categories;
  final String? home;
  final List<String>? tags;
  final bool? recommended;
  final String? catalog;
  final String? train;
  final DateTime? lastApiUpdate;

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
    this.title,
    this.description,
    this.installed,
    this.healthy,
    this.healthyError,
    this.version,
    this.appVersion,
    this.humanVersion,
    this.categories,
    this.home,
    this.tags,
    this.recommended,
    this.catalog,
    this.train,
    this.lastApiUpdate,
  });

  String get effectiveDisplayName => displayName ?? title ?? appName;
  AppPortConfig? get primaryPort {
    try {
      return ports.firstWhere((port) => port.isPrimary && port.isEnabled);
    } catch (e) {
      return ports.isNotEmpty ? ports.first : null;
    }
  }

  List<AppPortConfig> get enabledPorts =>
      ports.where((port) => port.isEnabled).toList();

  factory AppConfig.fromApp({
    required String serverId,
    required App app,
    String? customDisplayName,
    String? customIconUrl,
    bool isEnabled = true,
    bool isFavorite = false,
    List<AppPortConfig> ports = const [],
  }) {
    return AppConfig(
      serverId: serverId,
      appName: app.name,
      displayName: customDisplayName,
      iconUrl: customIconUrl ?? app.iconUrl,
      isEnabled: isEnabled,
      isFavorite: isFavorite,
      ports: ports,
      title: app.title,
      description: app.description,
      installed: app.installed,
      healthy: app.healthy,
      healthyError: app.healthyError,
      version: app.latestVersion,
      appVersion: app.latestAppVersion,
      humanVersion: app.latestHumanVersion,
      categories: app.categories,
      home: app.home,
      tags: app.tags,
      recommended: app.recommended,
      catalog: app.catalog,
      train: app.train,
      lastApiUpdate: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  AppConfig updateFromApp(App app) {
    return copyWith(
      title: app.title,
      description: app.description,
      installed: app.installed,
      healthy: app.healthy,
      healthyError: app.healthyError,
      version: app.latestVersion,
      appVersion: app.latestAppVersion,
      humanVersion: app.latestHumanVersion,
      categories: app.categories,
      home: app.home,
      tags: app.tags,
      recommended: app.recommended,
      catalog: app.catalog,
      train: app.train,
      lastApiUpdate: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
    String? title,
    String? description,
    bool? installed,
    bool? healthy,
    String? healthyError,
    String? version,
    String? appVersion,
    String? humanVersion,
    List<String>? categories,
    String? home,
    List<String>? tags,
    bool? recommended,
    String? catalog,
    String? train,
    DateTime? lastApiUpdate,
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
      title: title ?? this.title,
      description: description ?? this.description,
      installed: installed ?? this.installed,
      healthy: healthy ?? this.healthy,
      healthyError: healthyError ?? this.healthyError,
      version: version ?? this.version,
      appVersion: appVersion ?? this.appVersion,
      humanVersion: humanVersion ?? this.humanVersion,
      categories: categories ?? this.categories,
      home: home ?? this.home,
      tags: tags ?? this.tags,
      recommended: recommended ?? this.recommended,
      catalog: catalog ?? this.catalog,
      train: train ?? this.train,
      lastApiUpdate: lastApiUpdate ?? this.lastApiUpdate,
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
    title,
    description,
    installed,
    healthy,
    healthyError,
    version,
    appVersion,
    humanVersion,
    categories,
    home,
    tags,
    recommended,
    catalog,
    train,
    lastApiUpdate,
  ];
}
