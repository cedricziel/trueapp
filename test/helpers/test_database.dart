import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/database.dart';

/// An [AppDatabase] over a private in-memory SQLite database, closed
/// automatically when the active test ends.
///
/// Every caller gets its own executor, which is what makes
/// `dontWarnAboutMultipleDatabases` (see test/flutter_test_config.dart) safe
/// to set: the flag hides a warning that could never be correct here.
///
/// `close()` is guarded, for the same reason
/// `TestProviders.disposeTestStack` guards it: a test that fails mid-flight
/// can leave drift queries pending that will never complete, and an
/// unguarded close() would then hang the rest of the file.
AppDatabase createTestDatabase({
  Duration closeTimeout = const Duration(seconds: 5),
}) {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(() async {
    try {
      await database.close().timeout(closeTimeout);
    } catch (_) {
      // Teardown is best effort and must never mask the real test failure.
    }
  });
  return database;
}
