import 'package:flutter_test/flutter_test.dart';

import '../helpers/repo_files.dart';

/// Extracts the value of `IPHONEOS_DEPLOYMENT_TARGET` from every
/// `XCBuildConfiguration` block in [pbxproj] whose `PRODUCT_BUNDLE_IDENTIFIER`
/// equals [bundleIdentifier] — i.e. the app target's own configs, not the
/// six-values-across-two-groups noise a bare `grep` would pick up (the three
/// PBXProject-level configs carry Flutter's untouched template default and
/// must be excluded).
List<String> _appTargetDeploymentTargets(
  String pbxproj,
  String bundleIdentifier,
) {
  final chunks = pbxproj.split('isa = XCBuildConfiguration;');
  final values = <String>[];
  for (final chunk in chunks) {
    final end = chunk.indexOf('\n\t\t};');
    final block = end == -1 ? chunk : chunk.substring(0, end);
    if (!block.contains('PRODUCT_BUNDLE_IDENTIFIER = $bundleIdentifier;')) {
      continue;
    }
    final match = RegExp(
      r'IPHONEOS_DEPLOYMENT_TARGET = (\S+);',
    ).firstMatch(block);
    if (match != null) {
      values.add(match.group(1)!);
    }
  }
  return values;
}

String? _uncommentedIosPlatform(String podfile) {
  final match = RegExp(
    r"^(?!\s*#)\s*platform\s+:ios,\s*'([^']+)'",
    multiLine: true,
  ).firstMatch(podfile);
  return match?.group(1);
}

String? _uncommentedOsxPlatform(String podfile) {
  final match = RegExp(
    r"^(?!\s*#)\s*platform\s+:osx,\s*'([^']+)'",
    multiLine: true,
  ).firstMatch(podfile);
  return match?.group(1);
}

void main() {
  final repo = LocalRepoFileReader();

  group('iOS Podfile platform', () {
    test(
      'declares an explicit iOS platform instead of letting CocoaPods guess',
      () {
        final podfile = repo.read('ios/Podfile');
        expect(_uncommentedIosPlatform(podfile), isNotNull);
      },
    );

    test(
      'the Podfile platform equals the Runner app target IPHONEOS_DEPLOYMENT_TARGET',
      () {
        final pbxproj = repo.read('ios/Runner.xcodeproj/project.pbxproj');
        final appTargetVersions = _appTargetDeploymentTargets(
          pbxproj,
          'com.cedricziel.trueapp',
        );

        // Pin the parse itself: three configs (Debug/Profile/Release) on the
        // Runner app target, all declaring the same value. This documents
        // that the three PBXProject-level defaults are deliberately excluded
        // from this comparison - they carry Flutter's template value, which
        // moves independently of the app's real target (#99 raised it from
        // 12.0 to 15.0 without touching the app target's 16.6).
        expect(appTargetVersions, hasLength(3));
        expect(appTargetVersions.toSet(), equals({'16.6'}));

        final podfile = repo.read('ios/Podfile');
        expect(
          _uncommentedIosPlatform(podfile),
          equals(appTargetVersions.toSet().single),
        );
      },
    );
  });

  group('macOS Podfile platform (parity guard)', () {
    test('matches MACOSX_DEPLOYMENT_TARGET', () {
      final podfile = repo.read('macos/Podfile');
      final pbxproj = repo.read('macos/Runner.xcodeproj/project.pbxproj');
      final versions = RegExp(
        r'MACOSX_DEPLOYMENT_TARGET = (\S+);',
      ).allMatches(pbxproj).map((m) => m.group(1)!).toSet();

      expect(versions, equals({'10.14'}));
      expect(_uncommentedOsxPlatform(podfile), equals(versions.single));
    });
  });
}
