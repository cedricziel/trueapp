// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NasServersTable extends NasServers
    with TableInfo<$NasServersTable, NasServerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NasServersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hostMeta = const VerificationMeta('host');
  @override
  late final GeneratedColumn<String> host = GeneratedColumn<String>(
    'host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localUrlMeta = const VerificationMeta(
    'localUrl',
  );
  @override
  late final GeneratedColumn<String> localUrl = GeneratedColumn<String>(
    'local_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trustedWifiSsidsMeta = const VerificationMeta(
    'trustedWifiSsids',
  );
  @override
  late final GeneratedColumn<String> trustedWifiSsids = GeneratedColumn<String>(
    'trusted_wifi_ssids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passwordMeta = const VerificationMeta(
    'password',
  );
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
    'password',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useHttpsMeta = const VerificationMeta(
    'useHttps',
  );
  @override
  late final GeneratedColumn<bool> useHttps = GeneratedColumn<bool>(
    'use_https',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_https" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastConnectedMeta = const VerificationMeta(
    'lastConnected',
  );
  @override
  late final GeneratedColumn<DateTime> lastConnected =
      GeneratedColumn<DateTime>(
        'last_connected',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    host,
    localUrl,
    trustedWifiSsids,
    port,
    username,
    password,
    useHttps,
    lastConnected,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nas_servers';
  @override
  VerificationContext validateIntegrity(
    Insertable<NasServerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('host')) {
      context.handle(
        _hostMeta,
        host.isAcceptableOrUnknown(data['host']!, _hostMeta),
      );
    } else if (isInserting) {
      context.missing(_hostMeta);
    }
    if (data.containsKey('local_url')) {
      context.handle(
        _localUrlMeta,
        localUrl.isAcceptableOrUnknown(data['local_url']!, _localUrlMeta),
      );
    }
    if (data.containsKey('trusted_wifi_ssids')) {
      context.handle(
        _trustedWifiSsidsMeta,
        trustedWifiSsids.isAcceptableOrUnknown(
          data['trusted_wifi_ssids']!,
          _trustedWifiSsidsMeta,
        ),
      );
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(
        _passwordMeta,
        password.isAcceptableOrUnknown(data['password']!, _passwordMeta),
      );
    } else if (isInserting) {
      context.missing(_passwordMeta);
    }
    if (data.containsKey('use_https')) {
      context.handle(
        _useHttpsMeta,
        useHttps.isAcceptableOrUnknown(data['use_https']!, _useHttpsMeta),
      );
    }
    if (data.containsKey('last_connected')) {
      context.handle(
        _lastConnectedMeta,
        lastConnected.isAcceptableOrUnknown(
          data['last_connected']!,
          _lastConnectedMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NasServerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NasServerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      host: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}host'],
      )!,
      localUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_url'],
      ),
      trustedWifiSsids: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trusted_wifi_ssids'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      password: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password'],
      )!,
      useHttps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_https'],
      )!,
      lastConnected: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_connected'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $NasServersTable createAlias(String alias) {
    return $NasServersTable(attachedDatabase, alias);
  }
}

class NasServerData extends DataClass implements Insertable<NasServerData> {
  final String id;
  final String name;
  final String host;
  final String? localUrl;
  final String trustedWifiSsids;
  final int? port;
  final String username;
  final String password;
  final bool useHttps;
  final DateTime? lastConnected;
  final bool isActive;
  const NasServerData({
    required this.id,
    required this.name,
    required this.host,
    this.localUrl,
    required this.trustedWifiSsids,
    this.port,
    required this.username,
    required this.password,
    required this.useHttps,
    this.lastConnected,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    if (!nullToAbsent || localUrl != null) {
      map['local_url'] = Variable<String>(localUrl);
    }
    map['trusted_wifi_ssids'] = Variable<String>(trustedWifiSsids);
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    map['username'] = Variable<String>(username);
    map['password'] = Variable<String>(password);
    map['use_https'] = Variable<bool>(useHttps);
    if (!nullToAbsent || lastConnected != null) {
      map['last_connected'] = Variable<DateTime>(lastConnected);
    }
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  NasServersCompanion toCompanion(bool nullToAbsent) {
    return NasServersCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      localUrl: localUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(localUrl),
      trustedWifiSsids: Value(trustedWifiSsids),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      username: Value(username),
      password: Value(password),
      useHttps: Value(useHttps),
      lastConnected: lastConnected == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnected),
      isActive: Value(isActive),
    );
  }

  factory NasServerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NasServerData(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      host: serializer.fromJson<String>(json['host']),
      localUrl: serializer.fromJson<String?>(json['localUrl']),
      trustedWifiSsids: serializer.fromJson<String>(json['trustedWifiSsids']),
      port: serializer.fromJson<int?>(json['port']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String>(json['password']),
      useHttps: serializer.fromJson<bool>(json['useHttps']),
      lastConnected: serializer.fromJson<DateTime?>(json['lastConnected']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'localUrl': serializer.toJson<String?>(localUrl),
      'trustedWifiSsids': serializer.toJson<String>(trustedWifiSsids),
      'port': serializer.toJson<int?>(port),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String>(password),
      'useHttps': serializer.toJson<bool>(useHttps),
      'lastConnected': serializer.toJson<DateTime?>(lastConnected),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  NasServerData copyWith({
    String? id,
    String? name,
    String? host,
    Value<String?> localUrl = const Value.absent(),
    String? trustedWifiSsids,
    Value<int?> port = const Value.absent(),
    String? username,
    String? password,
    bool? useHttps,
    Value<DateTime?> lastConnected = const Value.absent(),
    bool? isActive,
  }) => NasServerData(
    id: id ?? this.id,
    name: name ?? this.name,
    host: host ?? this.host,
    localUrl: localUrl.present ? localUrl.value : this.localUrl,
    trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
    port: port.present ? port.value : this.port,
    username: username ?? this.username,
    password: password ?? this.password,
    useHttps: useHttps ?? this.useHttps,
    lastConnected: lastConnected.present
        ? lastConnected.value
        : this.lastConnected,
    isActive: isActive ?? this.isActive,
  );
  NasServerData copyWithCompanion(NasServersCompanion data) {
    return NasServerData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      localUrl: data.localUrl.present ? data.localUrl.value : this.localUrl,
      trustedWifiSsids: data.trustedWifiSsids.present
          ? data.trustedWifiSsids.value
          : this.trustedWifiSsids,
      port: data.port.present ? data.port.value : this.port,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      useHttps: data.useHttps.present ? data.useHttps.value : this.useHttps,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NasServerData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('localUrl: $localUrl, ')
          ..write('trustedWifiSsids: $trustedWifiSsids, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('useHttps: $useHttps, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    host,
    localUrl,
    trustedWifiSsids,
    port,
    username,
    password,
    useHttps,
    lastConnected,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NasServerData &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.localUrl == this.localUrl &&
          other.trustedWifiSsids == this.trustedWifiSsids &&
          other.port == this.port &&
          other.username == this.username &&
          other.password == this.password &&
          other.useHttps == this.useHttps &&
          other.lastConnected == this.lastConnected &&
          other.isActive == this.isActive);
}

class NasServersCompanion extends UpdateCompanion<NasServerData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> host;
  final Value<String?> localUrl;
  final Value<String> trustedWifiSsids;
  final Value<int?> port;
  final Value<String> username;
  final Value<String> password;
  final Value<bool> useHttps;
  final Value<DateTime?> lastConnected;
  final Value<bool> isActive;
  final Value<int> rowid;
  const NasServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.localUrl = const Value.absent(),
    this.trustedWifiSsids = const Value.absent(),
    this.port = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.useHttps = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NasServersCompanion.insert({
    required String id,
    required String name,
    required String host,
    this.localUrl = const Value.absent(),
    this.trustedWifiSsids = const Value.absent(),
    this.port = const Value.absent(),
    required String username,
    required String password,
    this.useHttps = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       host = Value(host),
       username = Value(username),
       password = Value(password);
  static Insertable<NasServerData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<String>? localUrl,
    Expression<String>? trustedWifiSsids,
    Expression<int>? port,
    Expression<String>? username,
    Expression<String>? password,
    Expression<bool>? useHttps,
    Expression<DateTime>? lastConnected,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (localUrl != null) 'local_url': localUrl,
      if (trustedWifiSsids != null) 'trusted_wifi_ssids': trustedWifiSsids,
      if (port != null) 'port': port,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (useHttps != null) 'use_https': useHttps,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NasServersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? host,
    Value<String?>? localUrl,
    Value<String>? trustedWifiSsids,
    Value<int?>? port,
    Value<String>? username,
    Value<String>? password,
    Value<bool>? useHttps,
    Value<DateTime?>? lastConnected,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return NasServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      localUrl: localUrl ?? this.localUrl,
      trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useHttps: useHttps ?? this.useHttps,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (host.present) {
      map['host'] = Variable<String>(host.value);
    }
    if (localUrl.present) {
      map['local_url'] = Variable<String>(localUrl.value);
    }
    if (trustedWifiSsids.present) {
      map['trusted_wifi_ssids'] = Variable<String>(trustedWifiSsids.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (useHttps.present) {
      map['use_https'] = Variable<bool>(useHttps.value);
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<DateTime>(lastConnected.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NasServersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('localUrl: $localUrl, ')
          ..write('trustedWifiSsids: $trustedWifiSsids, ')
          ..write('port: $port, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('useHttps: $useHttps, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NasServersTable nasServers = $NasServersTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [nasServers];
}

typedef $$NasServersTableCreateCompanionBuilder =
    NasServersCompanion Function({
      required String id,
      required String name,
      required String host,
      Value<String?> localUrl,
      Value<String> trustedWifiSsids,
      Value<int?> port,
      required String username,
      required String password,
      Value<bool> useHttps,
      Value<DateTime?> lastConnected,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$NasServersTableUpdateCompanionBuilder =
    NasServersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> host,
      Value<String?> localUrl,
      Value<String> trustedWifiSsids,
      Value<int?> port,
      Value<String> username,
      Value<String> password,
      Value<bool> useHttps,
      Value<DateTime?> lastConnected,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$NasServersTableFilterComposer
    extends Composer<_$AppDatabase, $NasServersTable> {
  $$NasServersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localUrl => $composableBuilder(
    column: $table.localUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trustedWifiSsids => $composableBuilder(
    column: $table.trustedWifiSsids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NasServersTableOrderingComposer
    extends Composer<_$AppDatabase, $NasServersTable> {
  $$NasServersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get host => $composableBuilder(
    column: $table.host,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localUrl => $composableBuilder(
    column: $table.localUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trustedWifiSsids => $composableBuilder(
    column: $table.trustedWifiSsids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get password => $composableBuilder(
    column: $table.password,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NasServersTableAnnotationComposer
    extends Composer<_$AppDatabase, $NasServersTable> {
  $$NasServersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get host =>
      $composableBuilder(column: $table.host, builder: (column) => column);

  GeneratedColumn<String> get localUrl =>
      $composableBuilder(column: $table.localUrl, builder: (column) => column);

  GeneratedColumn<String> get trustedWifiSsids => $composableBuilder(
    column: $table.trustedWifiSsids,
    builder: (column) => column,
  );

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<bool> get useHttps =>
      $composableBuilder(column: $table.useHttps, builder: (column) => column);

  GeneratedColumn<DateTime> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$NasServersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NasServersTable,
          NasServerData,
          $$NasServersTableFilterComposer,
          $$NasServersTableOrderingComposer,
          $$NasServersTableAnnotationComposer,
          $$NasServersTableCreateCompanionBuilder,
          $$NasServersTableUpdateCompanionBuilder,
          (
            NasServerData,
            BaseReferences<_$AppDatabase, $NasServersTable, NasServerData>,
          ),
          NasServerData,
          PrefetchHooks Function()
        > {
  $$NasServersTableTableManager(_$AppDatabase db, $NasServersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NasServersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NasServersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NasServersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> host = const Value.absent(),
                Value<String?> localUrl = const Value.absent(),
                Value<String> trustedWifiSsids = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> password = const Value.absent(),
                Value<bool> useHttps = const Value.absent(),
                Value<DateTime?> lastConnected = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NasServersCompanion(
                id: id,
                name: name,
                host: host,
                localUrl: localUrl,
                trustedWifiSsids: trustedWifiSsids,
                port: port,
                username: username,
                password: password,
                useHttps: useHttps,
                lastConnected: lastConnected,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String host,
                Value<String?> localUrl = const Value.absent(),
                Value<String> trustedWifiSsids = const Value.absent(),
                Value<int?> port = const Value.absent(),
                required String username,
                required String password,
                Value<bool> useHttps = const Value.absent(),
                Value<DateTime?> lastConnected = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NasServersCompanion.insert(
                id: id,
                name: name,
                host: host,
                localUrl: localUrl,
                trustedWifiSsids: trustedWifiSsids,
                port: port,
                username: username,
                password: password,
                useHttps: useHttps,
                lastConnected: lastConnected,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NasServersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NasServersTable,
      NasServerData,
      $$NasServersTableFilterComposer,
      $$NasServersTableOrderingComposer,
      $$NasServersTableAnnotationComposer,
      $$NasServersTableCreateCompanionBuilder,
      $$NasServersTableUpdateCompanionBuilder,
      (
        NasServerData,
        BaseReferences<_$AppDatabase, $NasServersTable, NasServerData>,
      ),
      NasServerData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NasServersTableTableManager get nasServers =>
      $$NasServersTableTableManager(_db, _db.nasServers);
}
