import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

abstract interface class DatabaseFileRemover {
  Future<void> removeDatabaseFiles();
}

class DocumentsDatabaseFileRemover implements DatabaseFileRemover {
  const DocumentsDatabaseFileRemover();

  @override
  Future<void> removeDatabaseFiles() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, 'truenas_manager.sqlite');

    for (final file in [
      File(dbPath),
      File('$dbPath-wal'),
      File('$dbPath-shm'),
    ]) {
      if (await file.exists()) await file.delete();
    }
  }
}
