import 'package:equatable/equatable.dart';

/// TrueNAS has returned datetime fields (`App.last_update`,
/// `AppResourceUsage.last_updated`, ...) in more than one shape across SCALE
/// versions: MongoDB-style extended JSON (`{"$date": <epoch ms>}`), a raw
/// epoch-millisecond number, or an ISO 8601 string. Parsing defensively
/// (rather than indexing straight into `['\$date']` or assuming a `String`)
/// keeps a server on an unexpected shape from throwing a raw type error out
/// of a model's `fromJson` - which previously surfaced to users as a generic
/// "Connection error" with no indication the app list itself parsed fine
/// except for this one field.
DateTime? _parseTrueNasDate(dynamic value) {
  if (value == null) return null;
  try {
    if (value is Map) {
      final epochMs = value['\$date'];
      if (epochMs is num) {
        return DateTime.fromMillisecondsSinceEpoch(epochMs.toInt());
      }
      return null;
    }
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value) ??
          (int.tryParse(value) != null
              ? DateTime.fromMillisecondsSinceEpoch(int.parse(value))
              : null);
    }
  } catch (_) {
    // Fall through to null below - an unparseable date shouldn't break
    // parsing the rest of the app's data.
  }
  return null;
}

class AppMaintainer extends Equatable {
  final String name;
  final String email;
  final String url;

  const AppMaintainer({
    required this.name,
    required this.email,
    required this.url,
  });

  factory AppMaintainer.fromJson(Map<String, dynamic> json) {
    return AppMaintainer(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'url': url};
  }

  @override
  List<Object?> get props => [name, email, url];
}

class AppResourceUsage extends Equatable {
  final double cpuUsage;
  final int memoryUsage;
  final int memoryLimit;
  final double networkRxBytes;
  final double networkTxBytes;
  final DateTime? lastUpdated;

  const AppResourceUsage({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryLimit,
    required this.networkRxBytes,
    required this.networkTxBytes,
    this.lastUpdated,
  });

  factory AppResourceUsage.fromJson(Map<String, dynamic> json) {
    return AppResourceUsage(
      cpuUsage: (json['cpu_usage'] as num?)?.toDouble() ?? 0.0,
      memoryUsage: (json['memory_usage'] as num?)?.toInt() ?? 0,
      memoryLimit: (json['memory_limit'] as num?)?.toInt() ?? 0,
      networkRxBytes: (json['network_rx_bytes'] as num?)?.toDouble() ?? 0.0,
      networkTxBytes: (json['network_tx_bytes'] as num?)?.toDouble() ?? 0.0,
      lastUpdated: _parseTrueNasDate(json['last_updated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cpu_usage': cpuUsage,
      'memory_usage': memoryUsage,
      'memory_limit': memoryLimit,
      'network_rx_bytes': networkRxBytes,
      'network_tx_bytes': networkTxBytes,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
    cpuUsage,
    memoryUsage,
    memoryLimit,
    networkRxBytes,
    networkTxBytes,
    lastUpdated,
  ];
}

class AppPortInfo extends Equatable {
  final int containerPort;
  final String protocol;
  final List<AppHostPort> hostPorts;

  const AppPortInfo({
    required this.containerPort,
    required this.protocol,
    required this.hostPorts,
  });

  factory AppPortInfo.fromJson(Map<String, dynamic> json) {
    return AppPortInfo(
      containerPort: json['container_port'] as int? ?? 0,
      protocol: json['protocol'] as String? ?? 'tcp',
      hostPorts:
          (json['host_ports'] as List<dynamic>?)
              ?.map((e) => AppHostPort.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'container_port': containerPort,
      'protocol': protocol,
      'host_ports': hostPorts.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [containerPort, protocol, hostPorts];
}

class AppHostPort extends Equatable {
  final int hostPort;
  final String hostIp;

  const AppHostPort({required this.hostPort, required this.hostIp});

  factory AppHostPort.fromJson(Map<String, dynamic> json) {
    return AppHostPort(
      hostPort: json['host_port'] as int? ?? 0,
      hostIp: json['host_ip'] as String? ?? '0.0.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {'host_port': hostPort, 'host_ip': hostIp};
  }

  @override
  List<Object?> get props => [hostPort, hostIp];
}

class AppUpgradeInfo extends Equatable {
  final bool upgradeAvailable;
  final String? availableVersion;
  final String? currentVersion;
  final String? upgradeNotes;
  final bool canUpgrade;

  const AppUpgradeInfo({
    required this.upgradeAvailable,
    this.availableVersion,
    this.currentVersion,
    this.upgradeNotes,
    required this.canUpgrade,
  });

  factory AppUpgradeInfo.fromJson(Map<String, dynamic> json) {
    return AppUpgradeInfo(
      upgradeAvailable: json['upgrade_available'] as bool? ?? false,
      availableVersion: json['available_version'] as String?,
      currentVersion: json['current_version'] as String?,
      upgradeNotes: json['upgrade_notes'] as String?,
      canUpgrade: json['can_upgrade'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upgrade_available': upgradeAvailable,
      'available_version': availableVersion,
      'current_version': currentVersion,
      'upgrade_notes': upgradeNotes,
      'can_upgrade': canUpgrade,
    };
  }

  @override
  List<Object?> get props => [
    upgradeAvailable,
    availableVersion,
    currentVersion,
    upgradeNotes,
    canUpgrade,
  ];
}

class App extends Equatable {
  final String name;
  final String title;
  final String description;
  final bool installed;
  final bool healthy;
  final String? healthyError;
  final String latestVersion;
  final String latestAppVersion;
  final String latestHumanVersion;
  final String? iconUrl;
  final List<String> categories;
  final String? home;
  final List<String> tags;
  final List<String> screenshots;
  final List<String> sources;
  final String? appReadme;
  final List<AppMaintainer> maintainers;
  final DateTime? lastUpdate;
  final bool recommended;
  final String catalog;
  final String train;
  final AppResourceUsage? resourceUsage;
  final AppUpgradeInfo? upgradeInfo;
  final List<AppPortInfo> usedPorts;
  final Map<String, String> portals;
  final String? customDisplayName;
  final String? customIconUrl;
  final String? primaryCustomUrl;

  const App({
    required this.name,
    required this.title,
    required this.description,
    required this.installed,
    required this.healthy,
    this.healthyError,
    required this.latestVersion,
    required this.latestAppVersion,
    required this.latestHumanVersion,
    this.iconUrl,
    required this.categories,
    this.home,
    required this.tags,
    required this.screenshots,
    required this.sources,
    this.appReadme,
    required this.maintainers,
    this.lastUpdate,
    required this.recommended,
    required this.catalog,
    required this.train,
    this.resourceUsage,
    this.upgradeInfo,
    required this.usedPorts,
    required this.portals,
    this.customDisplayName,
    this.customIconUrl,
    this.primaryCustomUrl,
  });

  String get effectiveDisplayName {
    if (customDisplayName != null) return customDisplayName!;

    // For installed apps, show the instance name from the API
    if (installed) {
      return name;
    }

    return title;
  }

  String? get effectiveIconUrl => customIconUrl ?? iconUrl;
  String? get primaryUrl {
    if (primaryCustomUrl != null) return primaryCustomUrl;
    if (portals.isNotEmpty) return portals.values.first;
    return null;
  }

  factory App.fromJson(Map<String, dynamic> json) {
    return App(
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      installed: json['installed'] as bool? ?? false,
      healthy: json['healthy'] as bool? ?? true,
      healthyError: json['healthy_error'] as String?,
      latestVersion: json['latest_version'] as String? ?? '',
      latestAppVersion: json['latest_app_version'] as String? ?? '',
      latestHumanVersion: json['latest_human_version'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      categories:
          (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      home: json['home'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
          [],
      screenshots:
          (json['screenshots'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sources:
          (json['sources'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      appReadme: json['app_readme'] as String?,
      maintainers:
          (json['maintainers'] as List<dynamic>?)
              ?.map((e) => AppMaintainer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastUpdate: _parseTrueNasDate(json['last_update']),
      recommended: json['recommended'] as bool? ?? false,
      catalog: json['catalog'] as String? ?? '',
      train: json['train'] as String? ?? '',
      resourceUsage: json['resource_usage'] != null
          ? AppResourceUsage.fromJson(
              json['resource_usage'] as Map<String, dynamic>,
            )
          : null,
      upgradeInfo: json['upgrade_info'] != null
          ? AppUpgradeInfo.fromJson(
              json['upgrade_info'] as Map<String, dynamic>,
            )
          : null,
      usedPorts:
          (json['used_ports'] as List<dynamic>?)
              ?.map((e) => AppPortInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      portals:
          (json['portals'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, value.toString()),
          ) ??
          {},
      customDisplayName: json['custom_display_name'] as String?,
      customIconUrl: json['custom_icon_url'] as String?,
      primaryCustomUrl: json['primary_custom_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'description': description,
      'installed': installed,
      'healthy': healthy,
      'healthy_error': healthyError,
      'latest_version': latestVersion,
      'latest_app_version': latestAppVersion,
      'latest_human_version': latestHumanVersion,
      'icon_url': iconUrl,
      'categories': categories,
      'home': home,
      'tags': tags,
      'screenshots': screenshots,
      'sources': sources,
      'app_readme': appReadme,
      'maintainers': maintainers.map((m) => m.toJson()).toList(),
      'last_update': lastUpdate != null
          ? {'\$date': lastUpdate!.millisecondsSinceEpoch}
          : null,
      'recommended': recommended,
      'catalog': catalog,
      'train': train,
      'resource_usage': resourceUsage?.toJson(),
      'upgrade_info': upgradeInfo?.toJson(),
      'used_ports': usedPorts.map((e) => e.toJson()).toList(),
      'portals': portals,
      'custom_display_name': customDisplayName,
      'custom_icon_url': customIconUrl,
      'primary_custom_url': primaryCustomUrl,
    };
  }

  @override
  List<Object?> get props => [
    name,
    title,
    description,
    installed,
    healthy,
    healthyError,
    latestVersion,
    latestAppVersion,
    latestHumanVersion,
    iconUrl,
    categories,
    home,
    tags,
    screenshots,
    sources,
    appReadme,
    maintainers,
    lastUpdate,
    recommended,
    catalog,
    train,
    resourceUsage,
    upgradeInfo,
    usedPorts,
    portals,
    customDisplayName,
    customIconUrl,
    primaryCustomUrl,
  ];
}
