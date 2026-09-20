import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../helpers/repo_files.dart';

/// Neutral, brightness-dependent `CupertinoColors`. `Container`,
/// `BoxDecoration`, `Icon` and `TextStyle` don't resolve a
/// `CupertinoDynamicColor` themselves, so an unresolved one always paints its
/// light-mode variant. `white`/`black` are excluded: they are often
/// deliberately static (text on a tinted fill, shadows).
final RegExp _unresolvedNeutralColor = RegExp(
  r'(?<!CupertinoDynamicColor\.resolve\(\s*)'
  r'CupertinoColors\.'
  r'(?:systemGrey[2-6]?|separator|label|secondaryLabel|tertiaryLabel|'
  r'systemBackground|systemGroupedBackground)\b'
  r'(?!\s*\.resolveFrom)',
);

List<String> _unresolvedUsages(RepoFileReader repo) {
  final offenders = <String>[];
  final libDir = Directory(repo.absolute('lib'));
  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is! File || p.extension(entity.path) != '.dart') continue;
    final source = entity.readAsStringSync();
    for (final match in _unresolvedNeutralColor.allMatches(source)) {
      final line = '\n'.allMatches(source.substring(0, match.start)).length + 1;
      offenders.add(
        '${p.relative(entity.path, from: repo.rootPath)}:$line '
        '${match.group(0)}',
      );
    }
  }
  return offenders;
}

void main() {
  test('lib/ resolves neutral CupertinoColors against the BuildContext', () {
    final offenders = _unresolvedUsages(LocalRepoFileReader());
    if (offenders.isEmpty) return;
    fail(
      'Unresolved neutral CupertinoColors paint their light variant in dark '
      'mode. Use `CupertinoColors.x.resolveFrom(context)` (or '
      '`CupertinoDynamicColor.resolve(color, context)`):\n'
      '${offenders.join('\n')}',
    );
  });
}
