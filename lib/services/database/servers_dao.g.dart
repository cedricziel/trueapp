// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servers_dao.dart';

// ignore_for_file: type=lint
mixin _$ServersDaoMixin on DatabaseAccessor<AppDatabase> {
  $NasServersTable get nasServers => attachedDatabase.nasServers;
  ServersDaoManager get managers => ServersDaoManager(this);
}

class ServersDaoManager {
  final _$ServersDaoMixin _db;
  ServersDaoManager(this._db);
  $$NasServersTableTableManager get nasServers =>
      $$NasServersTableTableManager(_db.attachedDatabase, _db.nasServers);
}
