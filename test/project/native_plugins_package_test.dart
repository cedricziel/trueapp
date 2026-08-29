import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/repo_files.dart';

const _podspecs = [
  'packages/truenas_native_plugins/ios/truenas_native_plugins.podspec',
  'packages/truenas_native_plugins/macos/truenas_native_plugins.podspec',
];

/// Every public class the package's main entrypoint exports (verified
/// against `lib/truenas_native_plugins.dart` and the files it re-exports —
/// this is the list the README must document, and no more).
const _exportedClasses = [
  'CloudKitServiceInterface',
  'KeychainServiceInterface',
  'NativeCloudKitService',
  'NativeKeychainService',
  'MockCloudKitService',
  'MockKeychainService',
  'TruenasPluginTestHelpers',
  'ServerConfigDTO',
];

const _requiredHeadings = [
  '## Installation',
  '## Usage',
  '## Testing',
  '## Entitlements',
  '## Migration',
];

void main() {
  final repo = LocalRepoFileReader();

  group('truenas_native_plugins packaging', () {
    test('every podspec license :file resolves to a file that exists', () {
      final licenseFile = RegExp(
        r"s\.license\s*=\s*\{\s*:file\s*=>\s*'([^']+)'",
      );

      for (final podspecPath in _podspecs) {
        final content = repo.read(podspecPath);
        final match = licenseFile.firstMatch(content);
        expect(match, isNotNull, reason: '$podspecPath has no s.license :file');

        final resolved = p.normalize(
          p.join(p.dirname(repo.absolute(podspecPath)), match!.group(1)!),
        );

        expect(
          File(resolved).existsSync(),
          isTrue,
          reason: '$podspecPath points at missing license file $resolved',
        );
      }
    });

    test('the package LICENSE is the repository AGPL-3.0 text', () {
      expect(repo.exists('packages/truenas_native_plugins/LICENSE'), isTrue);

      final packageLicense = repo.read(
        'packages/truenas_native_plugins/LICENSE',
      );
      final rootLicense = repo.read('LICENSE');

      expect(packageLicense, equals(rootLicense));
      expect(
        packageLicense.split('\n').firstWhere((line) => line.trim().isNotEmpty),
        contains('GNU AFFERO GENERAL PUBLIC LICENSE'),
      );
    });

    test('the package ships a README', () {
      expect(repo.exists('packages/truenas_native_plugins/README.md'), isTrue);
      expect(
        repo.read('packages/truenas_native_plugins/README.md').length,
        greaterThan(500),
      );
    });

    test('the README documents every public class the library exports', () {
      final readme = repo.read('packages/truenas_native_plugins/README.md');
      for (final className in _exportedClasses) {
        expect(
          readme,
          contains(className),
          reason: 'README does not mention exported class $className',
        );
      }
    });

    test("the README covers the sections #48 asked for", () {
      final readme = repo.read('packages/truenas_native_plugins/README.md');
      for (final heading in _requiredHeadings) {
        expect(
          readme,
          contains(heading),
          reason: 'README is missing the $heading section',
        );
      }
    });

    test(
      'the README names the platform channels the Dart code actually uses',
      () {
        final readme = repo.read('packages/truenas_native_plugins/README.md');
        const channels = [
          'com.cedricziel.truehub/keychain',
          'com.cedricziel.truehub/cloudkit',
          'com.cedricziel.truehub/cloudkit_events',
          'iCloud.com.cedricziel.truehub',
        ];

        // `keychain_service.dart` / `cloudkit_service.dart` build their
        // channel names dynamically from a default `_channelPrefix`
        // ('com.cedricziel.truehub') plus a suffix, so they never contain
        // the full literal string. `test_helpers.dart` (used by the
        // package's own test suite) and the Swift CloudKit plugin do
        // contain the literals, so cross-check against those instead.
        final testHelpersSource = repo.read(
          'packages/truenas_native_plugins/lib/src/test_utils/test_helpers.dart',
        );
        final cloudKitSwift = repo.read(
          'packages/truenas_native_plugins/ios/Classes/CloudKitPlugin.swift',
        );

        for (final channel in channels) {
          expect(
            readme,
            contains(channel),
            reason: 'README does not name channel/container $channel',
          );
          expect(
            testHelpersSource.contains(channel) ||
                cloudKitSwift.contains(channel),
            isTrue,
            reason: '$channel is documented but not present in the source',
          );
        }
      },
    );
  });
}
