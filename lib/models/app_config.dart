import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'app.dart';

class AppPortConfig extends Equatable {
  final int? id;
  final int portNumber;
  final String protocol;
  final String? serviceName;
  final String? customUrl;
  final String? apiUrl; // URL from TrueNAS API portals
  final bool isPrimary;
  final bool isEnabled;

  const AppPortConfig({
    this.id,
    required this.portNumber,
    this.protocol = 'http',
    this.serviceName,
    this.customUrl,
    this.apiUrl,
    this.isPrimary = false,
    this.isEnabled = true,
  });

  String get defaultUrl => '$protocol://localhost:$portNumber';
  String get effectiveUrl => customUrl ?? apiUrl ?? defaultUrl;
  String get displayName => serviceName ?? 'Port $portNumber';

  AppPortConfig copyWith({
    int? id,
    int? portNumber,
    String? protocol,
    String? serviceName,
    // Special flag to explicitly clear serviceName
    bool clearServiceName = false,
    String? customUrl,
    // Special flag to explicitly clear customUrl
    bool clearCustomUrl = false,
    String? apiUrl,
    // Special flag to explicitly clear apiUrl
    bool clearApiUrl = false,
    bool? isPrimary,
    bool? isEnabled,
  }) {
    return AppPortConfig(
      id: id ?? this.id,
      portNumber: portNumber ?? this.portNumber,
      protocol: protocol ?? this.protocol,
      serviceName: clearServiceName ? null : (serviceName ?? this.serviceName),
      customUrl: clearCustomUrl ? null : (customUrl ?? this.customUrl),
      apiUrl: clearApiUrl ? null : (apiUrl ?? this.apiUrl),
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
    apiUrl,
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

  // Complete app metadata for full offline access
  final List<String>? screenshots;
  final List<String>? sources;
  final String? appReadme;
  final String? maintainersJson; // JSON encoded maintainers
  final String? upgradeInfoJson; // JSON encoded upgrade info
  final String? usedPortsJson; // JSON encoded used ports

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
    this.screenshots,
    this.sources,
    this.appReadme,
    this.maintainersJson,
    this.upgradeInfoJson,
    this.usedPortsJson,
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

  // Helper getters to decode JSON fields
  List<AppMaintainer> get maintainers {
    if (maintainersJson == null) return [];
    try {
      final List<dynamic> list = jsonDecode(maintainersJson!);
      return list.map((json) => AppMaintainer.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  AppUpgradeInfo? get upgradeInfo {
    if (upgradeInfoJson == null) return null;
    try {
      return AppUpgradeInfo.fromJson(jsonDecode(upgradeInfoJson!));
    } catch (e) {
      return null;
    }
  }

  List<AppPortInfo> get usedPorts {
    if (usedPortsJson == null) return [];
    try {
      final List<dynamic> list = jsonDecode(usedPortsJson!);
      return list.map((json) => AppPortInfo.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

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
      screenshots: app.screenshots,
      sources: app.sources,
      appReadme: app.appReadme,
      maintainersJson: app.maintainers.isNotEmpty
          ? jsonEncode(app.maintainers.map((m) => m.toJson()).toList())
          : null,
      upgradeInfoJson: app.upgradeInfo != null
          ? jsonEncode(app.upgradeInfo!.toJson())
          : null,
      usedPortsJson: app.usedPorts.isNotEmpty
          ? jsonEncode(app.usedPorts.map((p) => p.toJson()).toList())
          : null,
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
      screenshots: app.screenshots,
      sources: app.sources,
      appReadme: app.appReadme,
      maintainersJson: app.maintainers.isNotEmpty
          ? jsonEncode(app.maintainers.map((m) => m.toJson()).toList())
          : null,
      upgradeInfoJson: app.upgradeInfo != null
          ? jsonEncode(app.upgradeInfo!.toJson())
          : null,
      usedPortsJson: app.usedPorts.isNotEmpty
          ? jsonEncode(app.usedPorts.map((p) => p.toJson()).toList())
          : null,
      updatedAt: DateTime.now(),
    );
  }

  AppConfig copyWith({
    int? id,
    String? serverId,
    String? appName,
    String? displayName,
    // Special flag to explicitly clear displayName
    bool clearDisplayName = false,
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
    List<String>? screenshots,
    List<String>? sources,
    String? appReadme,
    String? maintainersJson,
    String? upgradeInfoJson,
    String? usedPortsJson,
  }) {
    return AppConfig(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      appName: appName ?? this.appName,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
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
      screenshots: screenshots ?? this.screenshots,
      sources: sources ?? this.sources,
      appReadme: appReadme ?? this.appReadme,
      maintainersJson: maintainersJson ?? this.maintainersJson,
      upgradeInfoJson: upgradeInfoJson ?? this.upgradeInfoJson,
      usedPortsJson: usedPortsJson ?? this.usedPortsJson,
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
    screenshots,
    sources,
    appReadme,
    maintainersJson,
    upgradeInfoJson,
    usedPortsJson,
  ];
}
