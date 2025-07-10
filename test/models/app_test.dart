import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/models/app.dart';

void main() {
  group('App Model Tests', () {
    test('should create App from JSON correctly', () {
      final json = {
        'name': 'test-app',
        'title': 'Test App',
        'description': 'A test application',
        'installed': true,
        'healthy': true,
        'latest_version': '1.0.0',
        'latest_app_version': '1.0.0',
        'icon_url': 'https://example.com/icon.png',
        'categories': ['test', 'demo'],
        'home': 'https://example.com',
        'tags': ['test', 'demo', 'sample'],
      };

      final app = App.fromJson(json);

      expect(app.name, equals('test-app'));
      expect(app.title, equals('Test App'));
      expect(app.description, equals('A test application'));
      expect(app.installed, equals(true));
      expect(app.healthy, equals(true));
      expect(app.latestVersion, equals('1.0.0'));
      expect(app.latestAppVersion, equals('1.0.0'));
      expect(app.iconUrl, equals('https://example.com/icon.png'));
      expect(app.categories, equals(['test', 'demo']));
      expect(app.home, equals('https://example.com'));
      expect(app.tags, equals(['test', 'demo', 'sample']));
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'name': 'minimal-app',
        'title': 'Minimal App',
        'description': 'A minimal app',
        'latest_version': '1.0.0',
        'latest_app_version': '1.0.0',
      };

      final app = App.fromJson(json);

      expect(app.name, equals('minimal-app'));
      expect(app.title, equals('Minimal App'));
      expect(app.installed, equals(false));
      expect(app.healthy, equals(true));
      expect(app.healthyError, isNull);
      expect(app.iconUrl, isNull);
      expect(app.categories, isEmpty);
      expect(app.home, isNull);
      expect(app.tags, isEmpty);
    });

    test('should convert App to JSON correctly', () {
      const app = App(
        name: 'test-app',
        title: 'Test App',
        description: 'A test application',
        installed: true,
        healthy: false,
        healthyError: 'Service unavailable',
        latestVersion: '1.0.0',
        latestAppVersion: '1.0.0',
        iconUrl: 'https://example.com/icon.png',
        categories: ['test', 'demo'],
        home: 'https://example.com',
        tags: ['test', 'demo', 'sample'],
      );

      final json = app.toJson();

      expect(json['name'], equals('test-app'));
      expect(json['title'], equals('Test App'));
      expect(json['description'], equals('A test application'));
      expect(json['installed'], equals(true));
      expect(json['healthy'], equals(false));
      expect(json['healthy_error'], equals('Service unavailable'));
      expect(json['latest_version'], equals('1.0.0'));
      expect(json['latest_app_version'], equals('1.0.0'));
      expect(json['icon_url'], equals('https://example.com/icon.png'));
      expect(json['categories'], equals(['test', 'demo']));
      expect(json['home'], equals('https://example.com'));
      expect(json['tags'], equals(['test', 'demo', 'sample']));
    });
  });
}
