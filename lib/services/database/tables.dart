import 'package:drift/drift.dart';

@DataClassName('NasServerData')
class NasServers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get host => text()();
  TextColumn get username => text().withDefault(
    const Constant(''),
  )(); // Username is non-sensitive metadata
  TextColumn get localUrl => text().nullable()();
  TextColumn get trustedWifiSsids => text().withDefault(const Constant('[]'))();
  IntColumn get port => integer().nullable()();
  BoolColumn get useHttps => boolean().withDefault(const Constant(true))();
  BoolColumn get allowUntrustedCertificates =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastConnected => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AppConfigData')
class AppConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId =>
      text().references(NasServers, #id, onDelete: KeyAction.cascade)();
  TextColumn get appName => text()();
  TextColumn get displayName => text().nullable()();
  TextColumn get iconUrl => text().nullable()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  // Basic app metadata for offline access
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  BoolColumn get installed => boolean().nullable()();
  BoolColumn get healthy => boolean().nullable()();
  TextColumn get healthyError => text().nullable()();
  TextColumn get version => text().nullable()();
  TextColumn get appVersion => text().nullable()();
  TextColumn get humanVersion => text().nullable()();
  TextColumn get categories => text().nullable()(); // JSON encoded list
  TextColumn get home => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON encoded list
  BoolColumn get recommended => boolean().nullable()();
  TextColumn get catalog => text().nullable()();
  TextColumn get train => text().nullable()();
  DateTimeColumn get lastApiUpdate => dateTime().nullable()();

  // Complete app metadata for full offline access
  TextColumn get screenshots => text().nullable()(); // JSON encoded list
  TextColumn get sources => text().nullable()(); // JSON encoded list
  TextColumn get appReadme => text().nullable()();
  TextColumn get maintainersJson =>
      text().nullable()(); // JSON encoded maintainers
  TextColumn get upgradeInfoJson =>
      text().nullable()(); // JSON encoded upgrade info
  TextColumn get usedPortsJson =>
      text().nullable()(); // JSON encoded used ports
}

@DataClassName('AppPortConfigData')
class AppPortConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get appConfigId =>
      integer().references(AppConfigs, #id, onDelete: KeyAction.cascade)();
  IntColumn get portNumber => integer()();
  TextColumn get protocol => text().withDefault(const Constant('http'))();
  TextColumn get serviceName => text().nullable()();
  TextColumn get customUrl => text().nullable()();
  TextColumn get apiUrl => text().nullable()(); // URL from TrueNAS API portals
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
