import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/repo_files.dart';

/// Ticket #90 (see issue comment 5461545627): `.claude/settings.local.json`
/// is a per-developer file - Claude Code writes local permission approvals
/// into it as a working-tree change - so committing it means every
/// contributor inherits whoever committed it last, with no prompt. The fix is for the repository to never track it
/// at all, not to police its contents: a hygiene test that pins the
/// allow-list to a literal snapshot (as this file previously did) turns
/// every local permission approval into an unrelated red test suite, and
/// nothing here should couple to what any one contributor has approved.
void main() {
  late RepoFileReader repo;

  setUpAll(() {
    repo = LocalRepoFileReader();
  });

  test('.claude/settings.local.json is not tracked by the repository', () {
    // git rm --cached leaves the file on disk (LocalRepoFileReader reads
    // the working tree, not the git index) but drops it from `git
    // ls-files`; .gitignore is what stops it from being re-added. Asserting
    // the ignore rule, rather than shelling out to `git`, keeps this test
    // fast and independent of a git binary being on PATH.
    final gitignore = repo.read('.gitignore');
    final ignoresIt = gitignore
        .split('\n')
        .map((line) => line.trim())
        .any(
          (line) =>
              line == '.claude/settings.local.json' ||
              line == '.claude/*.local.json' ||
              line == '.claude/',
        );

    expect(
      ignoresIt,
      isTrue,
      reason:
          '.gitignore must exclude .claude/settings.local.json so a '
          "contributor's local Claude Code permission grants are never "
          'committed for everyone else to inherit',
    );
  });

  test('.claude/settings.local.json is absent from the git index', () {
    // The ignore rule above stops the file from being *re-added*, but it
    // says nothing about a copy already staged: `git add -f` or a checkout
    // predating the ignore rule would leave it tracked and that test would
    // still pass. Only the index answers "is it tracked", so ask git.
    if (!Directory('.git').existsSync()) {
      markTestSkipped('not a git checkout - nothing to inspect');
      return;
    }

    final ProcessResult result;
    try {
      result = Process.runSync('git', const [
        'ls-files',
        '--error-unmatch',
        '.claude/settings.local.json',
      ]);
    } on ProcessException {
      markTestSkipped('git is not on PATH');
      return;
    }

    expect(
      result.exitCode,
      isNot(0),
      reason:
          '.claude/settings.local.json is still tracked by git. Run '
          '`git rm --cached .claude/settings.local.json` - the .gitignore '
          'rule alone does not untrack an already-staged file.',
    );
  });
}
