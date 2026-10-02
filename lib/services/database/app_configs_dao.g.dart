// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_configs_dao.dart';

// ignore_for_file: type=lint
mixin _$AppConfigsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NasServersTable get nasServers => attachedDatabase.nasServers;
  $AppConfigsTable get appConfigs => attachedDatabase.appConfigs;
  $AppPortConfigsTable get appPortConfigs => attachedDatabase.appPortConfigs;
  AppConfigsDaoManager get managers => AppConfigsDaoManager(this);
}

class AppConfigsDaoManager {
  final _$AppConfigsDaoMixin _db;
  AppConfigsDaoManager(this._db);
  $$NasServersTableTableManager get nasServers =>
      $$NasServersTableTableManager(_db.attachedDatabase, _db.nasServers);
  $$AppConfigsTableTableManager get appConfigs =>
      $$AppConfigsTableTableManager(_db.attachedDatabase, _db.appConfigs);
  $$AppPortConfigsTableTableManager get appPortConfigs =>
      $$AppPortConfigsTableTableManager(
        _db.attachedDatabase,
        _db.appPortConfigs,
      );
}
