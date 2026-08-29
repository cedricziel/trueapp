import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/database.dart';

void main() {
  group('drift multiple-databases warning suppression', () {
    test(
      "opts out of drift's multiple-databases warning for the whole suite",
      () {
        // Pinned by test/flutter_test_config.dart's testExecutable hook,
        // which runs once per suite isolate before any test body.
        expect(driftRuntimeOptions.dontWarnAboutMultipleDatabases, isTrue);
      },
    );

    test(
      'does not print a warning when two test databases are open at once',
      () async {
        final originalDebugPrint = driftRuntimeOptions.debugPrint;
        final printed = <String>[];
        driftRuntimeOptions.debugPrint = printed.add;
        addTearDown(() => driftRuntimeOptions.debugPrint = originalDebugPrint);

        final first = AppDatabase.forTesting(NativeDatabase.memory());
        final second = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(() async {
          await first.close();
          await second.close();
        });

        // Both instances are alive simultaneously here - this is exactly the
        // situation that would normally trigger drift's warning.
        expect(printed, isEmpty);
      },
    );
  });
}
