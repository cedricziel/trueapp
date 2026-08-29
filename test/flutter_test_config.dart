import 'dart:async';

import 'package:drift/drift.dart';

/// Drift warns whenever a second instance of a database class is alive at
/// the same time as another, because two instances sharing one
/// QueryExecutor race each other and can corrupt the database. That does
/// not happen in this suite: every test builds its own [AppDatabase] over
/// its own `NativeDatabase.memory()` (see test/helpers/test_database.dart),
/// so no executor is ever shared, and the production singleton
/// (`AppDatabase.instance`) is never constructed under test. The warning is
/// therefore pure noise here - a multi-line stack trace ahead of nearly
/// every test - so it is opted out of once, for the whole suite, rather
/// than file by file.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
