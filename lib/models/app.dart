import 'package:equatable/equatable.dart';

class App extends Equatable {
  final String name;
  final String title;
  final String description;
  final bool installed;
  final bool healthy;
  final String? healthyError;
  final String latestVersion;
  final String latestAppVersion;
  final String? iconUrl;
  final List<String> categories;
  final String? home;
  final List<String> tags;

  const App({
    required this.name,
    required this.title,
    required this.description,
    required this.installed,
    required this.healthy,
    this.healthyError,
    required this.latestVersion,
    required this.latestAppVersion,
    this.iconUrl,
    required this.categories,
    this.home,
    required this.tags,
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
      'icon_url': iconUrl,
      'categories': categories,
      'home': home,
      'tags': tags,
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
    iconUrl,
    categories,
    home,
    tags,
  ];
}
