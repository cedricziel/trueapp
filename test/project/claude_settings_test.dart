import 'package:flutter_test/flutter_test.dart';

import '../helpers/repo_files.dart';

/// Ticket #90 (see issue comment 5461545627): `.claude/settings.local.json`
/// is a per-developer file - Claude Code writes local permission approvals
/// into it as a working-tree change - so committing it means every
/// contributor inherits whoever committed it last inherits their personal
/// grants with no prompt. The fix is for the repository to never track it
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
}
