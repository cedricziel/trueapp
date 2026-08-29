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

void main() {
  final repo = LocalRepoFileReader();

  group('fl_chart is not a dependency', () {
    test('pubspec.yaml declares no fl_chart dependency', () {
      final pubspecYaml = repo.read('pubspec.yaml');
      expect(
        RegExp(r'^\s+fl_chart\s*:', multiLine: true).hasMatch(pubspecYaml),
        isFalse,
      );
    });

    test('pubspec.lock contains no fl_chart entry', () {
      final pubspecLock = repo.read('pubspec.lock');
      expect(
        RegExp(r'^  fl_chart:', multiLine: true).hasMatch(pubspecLock),
        isFalse,
      );
    });

    test('no Dart source imports package:fl_chart', () {
      // Matches an actual import/export directive rather than a bare
      // substring, so this assertion's own source text (which necessarily
      // mentions the package name) does not trip itself up.
      final importDirective = RegExp(r"(?:import|export)\s+'package:fl_chart/");
      final files = _dartFilesUnder(repo, ['lib', 'test', 'packages']);
      expect(files, isNotEmpty);
      for (final file in files) {
        expect(
          importDirective.hasMatch(file.readAsStringSync()),
          isFalse,
          reason: '${file.path} imports package:fl_chart',
        );
      }
    });

    test('README Tech Stack does not advertise chart support', () {
      final readme = repo.read('README.md');
      expect(readme, isNot(contains('fl_chart')));
      expect(readme, isNot(contains('Charts for health monitoring')));
    });
  });
}
