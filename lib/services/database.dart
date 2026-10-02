import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:truehub/services/database/app_configs_dao.dart';
import 'package:truehub/services/database/dao_source.dart';
import 'package:truehub/services/database/migrations.dart';
import 'package:truehub/services/database/servers_dao.dart';
import 'package:truehub/services/database/tables.dart';

export 'package:truehub/services/database/app_configs_dao.dart';
export 'package:truehub/services/database/app_database_holder.dart';
export 'package:truehub/services/database/dao_source.dart';
export 'package:truehub/services/database/servers_dao.dart';
export 'package:truehub/services/database/tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [NasServers, AppConfigs, AppPortConfigs],
  daos: [ServersDao, AppConfigsDao],
)
class AppDatabase extends _$AppDatabase implements DaoSource {
  AppDatabase.production() : super(driftDatabase(name: 'truenas_manager'));

  // Constructor for testing that accepts a custom QueryExecutor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => buildMigrationStrategy(this);
}
