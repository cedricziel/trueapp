import 'package:equatable/equatable.dart';

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
  });

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
      lastUpdate: json['last_update'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['last_update']['\$date'] as int? ?? 0,
            )
          : null,
      recommended: json['recommended'] as bool? ?? false,
      catalog: json['catalog'] as String? ?? '',
      train: json['train'] as String? ?? '',
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
  ];
}
