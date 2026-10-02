import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/repo_files.dart';

/// All Dart source under [dirs] (relative to the repo root), recursively.
List<File> _dartFilesUnder(RepoFileReader repo, List<String> dirs) {
  final files = <File>[];
  for (final dir in dirs) {
    final directory = Directory(repo.absolute(dir));
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && p.extension(entity.path) == '.dart') {
        files.add(entity);
      }
    }
  }
  return files;
}

/// Removed packages, each with the README phrases that used to advertise it.
const _removedPackages = {
  'fl_chart': ['fl_chart', 'Charts for health monitoring'],
  'dio': ['**dio**', 'HTTP client for API calls'],
};

void main() {
  final repo = LocalRepoFileReader();

  for (final MapEntry(key: package, value: readmeMentions)
      in _removedPackages.entries) {
    group('$package is not a dependency', () {
      test('pubspec.yaml declares no $package dependency', () {
        final pubspecYaml = repo.read('pubspec.yaml');
        expect(
          RegExp('^\\s+$package\\s*:', multiLine: true).hasMatch(pubspecYaml),
          isFalse,
        );
      });

      test('pubspec.lock contains no $package entry', () {
        final pubspecLock = repo.read('pubspec.lock');
        expect(
          RegExp('^  $package:', multiLine: true).hasMatch(pubspecLock),
          isFalse,
        );
      });

      test('no Dart source imports package:$package', () {
        // Both quote styles are accepted: Dart allows either, so matching
        // only single-quoted URIs would let a double-quoted directive slip
        // past this assertion entirely.
        final importDirective = RegExp(
          '(?:import|export)\\s+[\'"]package:$package/',
        );
        final files = _dartFilesUnder(repo, ['lib', 'test', 'packages']);
        expect(files, isNotEmpty);
        for (final file in files) {
          expect(
            importDirective.hasMatch(file.readAsStringSync()),
            isFalse,
            reason: '${file.path} imports package:$package',
          );
        }
      });

      test('README Tech Stack does not advertise $package', () {
        final readme = repo.read('README.md');
        for (final mention in readmeMentions) {
          expect(readme, isNot(contains(mention)));
        }
      });
    });
  }
}
