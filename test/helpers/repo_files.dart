import 'dart:io';

import 'package:path/path.dart' as p;

/// Reads files from the repository working tree.
///
/// Config/documentation hygiene tests (see `test/project/`) need to read
/// files that live outside `lib/`/`test/` — `.claude/settings.local.json`,
/// `ios/Podfile`, `pubspec.yaml`, `README.md`, files under `packages/` — by
/// a path relative to the repository root, regardless of the working
/// directory `flutter test` happens to be invoked from. Coding against this
/// interface (rather than bare `File` calls scattered across tests) keeps
/// that path-resolution logic in one place and swappable in a test double.
abstract class RepoFileReader {
  /// Absolute path to the repository root.
  String get rootPath;

  /// Whether a file exists at [relativePath] (relative to [rootPath]).
  bool exists(String relativePath);

  /// Reads the file at [relativePath] (relative to [rootPath]) as a string.
  String read(String relativePath);

  /// Resolves [relativePath] (relative to [rootPath]) to an absolute path.
  String absolute(String relativePath);
}

/// [RepoFileReader] backed by the real filesystem, rooted at the directory
/// that holds this repository's `pubspec.yaml` (package `truehub`).
class LocalRepoFileReader implements RepoFileReader {
  LocalRepoFileReader({Directory? root}) : _root = root ?? findRepoRoot();

  final Directory _root;

  /// Walks up from [start] (default: the current working directory) until
  /// it finds the directory containing the `truehub` package's
  /// `pubspec.yaml`. This makes path resolution independent of the working
  /// directory a test runner happens to use.
  static Directory findRepoRoot([Directory? start]) {
    var dir = start ?? Directory.current;
    while (true) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync() &&
          pubspec.readAsStringSync().contains('name: truehub')) {
        return dir;
      }
      final parent = dir.parent;
      if (parent.path == dir.path) {
        throw StateError(
          'Could not locate the truehub repository root starting from '
          '${(start ?? Directory.current).path}',
        );
      }
      dir = parent;
    }
  }

  @override
  String get rootPath => _root.path;

  @override
  String absolute(String relativePath) => p.join(_root.path, relativePath);

  @override
  bool exists(String relativePath) => File(absolute(relativePath)).existsSync();

  @override
  String read(String relativePath) =>
      File(absolute(relativePath)).readAsStringSync();
}
