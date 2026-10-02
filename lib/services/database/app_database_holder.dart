import 'package:truehub/services/database.dart';

/// Owns the app-wide [AppDatabase] and hands out the current one, so callers
/// keep working after [dispose] (e.g. "clear database") instead of pinning a
/// closed instance.
class AppDatabaseHolder implements DaoSource {
  AppDatabaseHolder({required AppDatabase Function() open}) : _open = open;

  final AppDatabase Function() _open;
  AppDatabase? _current;

  AppDatabase get current => _current ??= _open();

  @override
  ServersDao get serversDao => current.serversDao;

  @override
  AppConfigsDao get appConfigsDao => current.appConfigsDao;

  Future<void> dispose() async {
    final database = _current;
    _current = null;
    await database?.close();
  }
}
