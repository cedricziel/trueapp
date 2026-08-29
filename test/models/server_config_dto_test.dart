import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_config_dto.dart';
import 'package:truenas_native_plugins/truenas_native_plugins.dart' as plugins;

void main() {
  group('ServerConfigDTO construction', () {
    test('generates an id and timestamps when not provided', () {
      final dto = ServerConfigDTO(
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: true,
        allowUntrustedCertificates: false,
      );

      expect(dto.id, isNotEmpty);
      expect(dto.createdAt, isA<DateTime>());
      expect(dto.updatedAt, isA<DateTime>());
      expect(dto.trustedWifiSsids, isEmpty);
      expect(dto.isActive, isTrue);
      expect(dto.isDefault, isFalse);
      expect(dto.port, isNull);
      expect(dto.localUrl, isNull);
      expect(dto.lastConnected, isNull);
    });

    test('uses provided id and timestamps when given', () {
      final createdAt = DateTime(2023, 1, 1);
      final updatedAt = DateTime(2023, 2, 1);
      final dto = ServerConfigDTO(
        id: 'fixed-id',
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: true,
        allowUntrustedCertificates: false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      expect(dto.id, equals('fixed-id'));
      expect(dto.createdAt, equals(createdAt));
      expect(dto.updatedAt, equals(updatedAt));
    });
  });

  group('ServerConfigDTO JSON', () {
    ServerConfigDTO buildFull() => ServerConfigDTO(
      id: 'id-1',
      displayName: 'My NAS',
      hostName: 'nas.local',
      userName: 'admin',
      useHttps: true,
      allowUntrustedCertificates: true,
      port: 443,
      localUrl: 'https://192.168.1.10',
      trustedWifiSsids: const ['HomeWifi'],
      lastConnected: DateTime(2024, 3, 1, 12, 0, 0),
      isActive: true,
      isDefault: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 2, 1),
    );

    test('toJson emits all fields with ISO8601 dates', () {
      final dto = buildFull();
      final json = dto.toJson();

      expect(json['id'], equals('id-1'));
      expect(json['displayName'], equals('My NAS'));
      expect(json['hostName'], equals('nas.local'));
      expect(json['userName'], equals('admin'));
      expect(json['useHttps'], isTrue);
      expect(json['allowUntrustedCertificates'], isTrue);
      expect(json['port'], equals(443));
      expect(json['localUrl'], equals('https://192.168.1.10'));
      expect(json['trustedWifiSsids'], equals(['HomeWifi']));
      expect(json['lastConnected'], equals('2024-03-01T12:00:00.000'));
      expect(json['isActive'], isTrue);
      expect(json['isDefault'], isTrue);
      expect(json['createdAt'], equals('2024-01-01T00:00:00.000'));
      expect(json['updatedAt'], equals('2024-02-01T00:00:00.000'));
    });

    test('fromJson round-trips a full payload', () {
      final dto = buildFull();
      final roundTripped = ServerConfigDTO.fromJson(dto.toJson());

      expect(roundTripped.id, equals(dto.id));
      expect(roundTripped.displayName, equals(dto.displayName));
      expect(roundTripped.hostName, equals(dto.hostName));
      expect(roundTripped.userName, equals(dto.userName));
      expect(roundTripped.useHttps, equals(dto.useHttps));
      expect(
        roundTripped.allowUntrustedCertificates,
        equals(dto.allowUntrustedCertificates),
      );
      expect(roundTripped.port, equals(dto.port));
      expect(roundTripped.localUrl, equals(dto.localUrl));
      expect(roundTripped.trustedWifiSsids, equals(dto.trustedWifiSsids));
      expect(roundTripped.lastConnected, equals(dto.lastConnected));
      expect(roundTripped.isActive, equals(dto.isActive));
      expect(roundTripped.isDefault, equals(dto.isDefault));
      expect(roundTripped.createdAt, equals(dto.createdAt));
      expect(roundTripped.updatedAt, equals(dto.updatedAt));
    });

    test('fromJson applies defaults for missing/null optional fields', () {
      final dto = ServerConfigDTO.fromJson({});

      expect(dto.id, equals(''));
      expect(dto.displayName, equals('Unknown Server'));
      expect(dto.hostName, equals(''));
      expect(dto.userName, equals(''));
      expect(dto.useHttps, isTrue);
      expect(dto.allowUntrustedCertificates, isFalse);
      expect(dto.port, isNull);
      expect(dto.localUrl, isNull);
      expect(dto.trustedWifiSsids, isEmpty);
      expect(dto.lastConnected, isNull);
      expect(dto.isActive, isTrue);
      expect(dto.isDefault, isFalse);
      expect(dto.createdAt, isA<DateTime>());
      expect(dto.updatedAt, isA<DateTime>());
    });

    test('fromJson falls back to now() for unparsable date strings', () {
      final json = {'createdAt': 'not-a-date', 'updatedAt': 'also-not-a-date'};
      final dto = ServerConfigDTO.fromJson(json);

      expect(dto.createdAt, isA<DateTime>());
      expect(dto.updatedAt, isA<DateTime>());
    });

    test('fromJson rethrows on malformed input', () {
      expect(
        () => ServerConfigDTO.fromJson({'trustedWifiSsids': 'not-a-list'}),
        throwsA(anything),
      );
    });
  });

  group('ServerConfigDTO.copyWith', () {
    test('overrides only provided fields and always refreshes updatedAt', () {
      final original = ServerConfigDTO(
        id: 'id-1',
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: true,
        allowUntrustedCertificates: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(displayName: 'Renamed NAS');

      expect(updated.id, equals(original.id));
      expect(updated.displayName, equals('Renamed NAS'));
      expect(updated.hostName, equals(original.hostName));
      expect(updated.createdAt, equals(original.createdAt));
      expect(updated.updatedAt, isNot(equals(original.updatedAt)));
    });
  });

  group('ServerConfigDTO.fromServer', () {
    test('maps all fields from a NasServer', () {
      final server = NasServer(
        id: 'server-id',
        name: 'My NAS',
        host: 'nas.local',
        localUrl: 'https://192.168.1.10',
        trustedWifiSsids: const ['HomeWifi'],
        port: 443,
        username: 'admin',
        password: 'secret',
        useHttps: true,
        allowUntrustedCertificates: true,
        lastConnected: DateTime(2024, 3, 1),
        isActive: true,
        isDefault: true,
      );

      final dto = ServerConfigDTO.fromServer(server);

      expect(dto.id, equals('server-id'));
      expect(dto.displayName, equals('My NAS'));
      expect(dto.hostName, equals('nas.local'));
      expect(dto.userName, equals('admin'));
      expect(dto.useHttps, isTrue);
      expect(dto.allowUntrustedCertificates, isTrue);
      expect(dto.port, equals(443));
      expect(dto.localUrl, equals('https://192.168.1.10'));
      expect(dto.trustedWifiSsids, equals(['HomeWifi']));
      expect(dto.lastConnected, equals(DateTime(2024, 3, 1)));
      expect(dto.isActive, isTrue);
      expect(dto.isDefault, isTrue);
      // Note: password is intentionally not carried onto the DTO.
    });
  });

  group('ServerConfigDTO plugin conversion', () {
    test('toPlugin maps all fields onto the plugin DTO', () {
      final dto = ServerConfigDTO(
        id: 'id-1',
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: true,
        allowUntrustedCertificates: true,
        port: 443,
        localUrl: 'https://192.168.1.10',
        trustedWifiSsids: const ['HomeWifi'],
        lastConnected: DateTime(2024, 3, 1),
        isActive: true,
        isDefault: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      final plugin = dto.toPlugin();

      expect(plugin.id, equals(dto.id));
      expect(plugin.displayName, equals(dto.displayName));
      expect(plugin.hostName, equals(dto.hostName));
      expect(plugin.userName, equals(dto.userName));
      expect(plugin.useHttps, equals(dto.useHttps));
      expect(
        plugin.allowUntrustedCertificates,
        equals(dto.allowUntrustedCertificates),
      );
      expect(plugin.port, equals(dto.port));
      expect(plugin.localUrl, equals(dto.localUrl));
      expect(plugin.trustedWifiSsids, equals(dto.trustedWifiSsids));
      expect(plugin.lastConnected, equals(dto.lastConnected));
      expect(plugin.isActive, equals(dto.isActive));
      expect(plugin.isDefault, equals(dto.isDefault));
      expect(plugin.createdAt, equals(dto.createdAt));
      expect(plugin.updatedAt, equals(dto.updatedAt));
    });

    test('fromPlugin maps all fields from a plugin DTO', () {
      final plugin = plugins.ServerConfigDTO(
        id: 'id-1',
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: true,
        allowUntrustedCertificates: true,
        port: 443,
        localUrl: 'https://192.168.1.10',
        trustedWifiSsids: const ['HomeWifi'],
        lastConnected: DateTime(2024, 3, 1),
        isActive: true,
        isDefault: true,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 2, 1),
      );

      final dto = ServerConfigDTO.fromPlugin(plugin);

      expect(dto.id, equals(plugin.id));
      expect(dto.displayName, equals(plugin.displayName));
      expect(dto.hostName, equals(plugin.hostName));
      expect(dto.userName, equals(plugin.userName));
      expect(dto.useHttps, equals(plugin.useHttps));
      expect(
        dto.allowUntrustedCertificates,
        equals(plugin.allowUntrustedCertificates),
      );
      expect(dto.port, equals(plugin.port));
      expect(dto.localUrl, equals(plugin.localUrl));
      expect(dto.trustedWifiSsids, equals(plugin.trustedWifiSsids));
      expect(dto.lastConnected, equals(plugin.lastConnected));
      expect(dto.isActive, equals(plugin.isActive));
      expect(dto.isDefault, equals(plugin.isDefault));
      expect(dto.createdAt, equals(plugin.createdAt));
      expect(dto.updatedAt, equals(plugin.updatedAt));
    });

    test('toPlugin -> fromPlugin round-trips', () {
      final original = ServerConfigDTO(
        id: 'id-1',
        displayName: 'My NAS',
        hostName: 'nas.local',
        userName: 'admin',
        useHttps: false,
        allowUntrustedCertificates: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final roundTripped = ServerConfigDTO.fromPlugin(original.toPlugin());

      expect(roundTripped.id, equals(original.id));
      expect(roundTripped.displayName, equals(original.displayName));
      expect(roundTripped.hostName, equals(original.hostName));
      expect(roundTripped.userName, equals(original.userName));
      expect(roundTripped.useHttps, equals(original.useHttps));
    });
  });
}
