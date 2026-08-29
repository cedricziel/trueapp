import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/repo_files.dart';

void main() {
  late RepoFileReader repo;
  late List<String> allow;

  setUpAll(() {
    repo = LocalRepoFileReader();
    final decoded =
        jsonDecode(repo.read('.claude/settings.local.json'))
            as Map<String, dynamic>;
    allow = List<String>.from(
      (decoded['permissions'] as Map<String, dynamic>)['allow'] as List,
    );
  });

  group('Claude Code permission allowlist', () {
    test(
      'does not pre-approve shell wrappers that can run arbitrary programs',
      () {
        // `Bash(gtimeout:*)` is deliberately NOT checked here: CLAUDE.md
        // names gtimeout as this project's timeout tool, and ticket #90
        // scopes this change to exactly the two wildcard entries below —
        // widening it to gtimeout is tracked as a separate follow-up.
        const arbitraryCommandWrappers = [
          'timeout',
          'curl',
          'sh',
          'bash',
          'zsh',
          'env',
          'eval',
          'xargs',
          'nohup',
        ];

        for (final wrapper in arbitraryCommandWrappers) {
          expect(allow, isNot(contains('Bash($wrapper:*)')));
        }
      },
    );

    test('keeps every other entry, in order, exactly as written', () {
      expect(allow, [
        'Bash(mkdir:*)',
        'Bash(flutter pub:*)',
        'Bash(git add:*)',
        'Bash(gh issue list:*)',
        'WebFetch(domain:github.com)',
        'WebFetch(domain:pub.dev)',
        'WebFetch(domain:www.gnu.org)',
        'Bash(flutter analyze:*)',
        'Bash(dart run build_runner:*)',
        'Bash(flutter test:*)',
        'Bash(git push:*)',
        'WebFetch(domain:api.truenas.com)',
        'WebFetch(domain:raw.githubusercontent.com)',
        'Bash(grep:*)',
        'Bash(dart format:*)',
        'Bash(gh repo view:*)',
        'Bash(gh label:*)',
        'Bash(gh issue view:*)',
        'Bash(gh issue create:*)',
        'Bash(dart analyze:*)',
        'Bash(find:*)',
        'Bash(flutter build:*)',
        'Bash(git commit:*)',
        'Bash(gtimeout:*)',
        'Bash(timeout 30s flutter test:*)',
      ]);
    });
  });
}
