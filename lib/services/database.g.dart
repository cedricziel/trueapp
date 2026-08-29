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
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
  static const VerificationMeta _allowUntrustedCertificatesMeta =
      const VerificationMeta('allowUntrustedCertificates');
  @override
  late final GeneratedColumn<bool> allowUntrustedCertificates =
      GeneratedColumn<bool>(
        'allow_untrusted_certificates',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("allow_untrusted_certificates" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
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
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    host,
    username,
    localUrl,
    trustedWifiSsids,
    port,
    useHttps,
    allowUntrustedCertificates,
    lastConnected,
    isActive,
    isDefault,
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
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
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
    if (data.containsKey('use_https')) {
      context.handle(
        _useHttpsMeta,
        useHttps.isAcceptableOrUnknown(data['use_https']!, _useHttpsMeta),
      );
    }
    if (data.containsKey('allow_untrusted_certificates')) {
      context.handle(
        _allowUntrustedCertificatesMeta,
        allowUntrustedCertificates.isAcceptableOrUnknown(
          data['allow_untrusted_certificates']!,
          _allowUntrustedCertificatesMeta,
        ),
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
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
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
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
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
      useHttps: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_https'],
      )!,
      allowUntrustedCertificates: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_untrusted_certificates'],
      )!,
      lastConnected: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_connected'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
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
  final String username;
  final String? localUrl;
  final String trustedWifiSsids;
  final int? port;
  final bool useHttps;
  final bool allowUntrustedCertificates;
  final DateTime? lastConnected;
  final bool isActive;
  final bool isDefault;
  const NasServerData({
    required this.id,
    required this.name,
    required this.host,
    required this.username,
    this.localUrl,
    required this.trustedWifiSsids,
    this.port,
    required this.useHttps,
    required this.allowUntrustedCertificates,
    this.lastConnected,
    required this.isActive,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['host'] = Variable<String>(host);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || localUrl != null) {
      map['local_url'] = Variable<String>(localUrl);
    }
    map['trusted_wifi_ssids'] = Variable<String>(trustedWifiSsids);
    if (!nullToAbsent || port != null) {
      map['port'] = Variable<int>(port);
    }
    map['use_https'] = Variable<bool>(useHttps);
    map['allow_untrusted_certificates'] = Variable<bool>(
      allowUntrustedCertificates,
    );
    if (!nullToAbsent || lastConnected != null) {
      map['last_connected'] = Variable<DateTime>(lastConnected);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  NasServersCompanion toCompanion(bool nullToAbsent) {
    return NasServersCompanion(
      id: Value(id),
      name: Value(name),
      host: Value(host),
      username: Value(username),
      localUrl: localUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(localUrl),
      trustedWifiSsids: Value(trustedWifiSsids),
      port: port == null && nullToAbsent ? const Value.absent() : Value(port),
      useHttps: Value(useHttps),
      allowUntrustedCertificates: Value(allowUntrustedCertificates),
      lastConnected: lastConnected == null && nullToAbsent
          ? const Value.absent()
          : Value(lastConnected),
      isActive: Value(isActive),
      isDefault: Value(isDefault),
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
      username: serializer.fromJson<String>(json['username']),
      localUrl: serializer.fromJson<String?>(json['localUrl']),
      trustedWifiSsids: serializer.fromJson<String>(json['trustedWifiSsids']),
      port: serializer.fromJson<int?>(json['port']),
      useHttps: serializer.fromJson<bool>(json['useHttps']),
      allowUntrustedCertificates: serializer.fromJson<bool>(
        json['allowUntrustedCertificates'],
      ),
      lastConnected: serializer.fromJson<DateTime?>(json['lastConnected']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'host': serializer.toJson<String>(host),
      'username': serializer.toJson<String>(username),
      'localUrl': serializer.toJson<String?>(localUrl),
      'trustedWifiSsids': serializer.toJson<String>(trustedWifiSsids),
      'port': serializer.toJson<int?>(port),
      'useHttps': serializer.toJson<bool>(useHttps),
      'allowUntrustedCertificates': serializer.toJson<bool>(
        allowUntrustedCertificates,
      ),
      'lastConnected': serializer.toJson<DateTime?>(lastConnected),
      'isActive': serializer.toJson<bool>(isActive),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  NasServerData copyWith({
    String? id,
    String? name,
    String? host,
    String? username,
    Value<String?> localUrl = const Value.absent(),
    String? trustedWifiSsids,
    Value<int?> port = const Value.absent(),
    bool? useHttps,
    bool? allowUntrustedCertificates,
    Value<DateTime?> lastConnected = const Value.absent(),
    bool? isActive,
    bool? isDefault,
  }) => NasServerData(
    id: id ?? this.id,
    name: name ?? this.name,
    host: host ?? this.host,
    username: username ?? this.username,
    localUrl: localUrl.present ? localUrl.value : this.localUrl,
    trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
    port: port.present ? port.value : this.port,
    useHttps: useHttps ?? this.useHttps,
    allowUntrustedCertificates:
        allowUntrustedCertificates ?? this.allowUntrustedCertificates,
    lastConnected: lastConnected.present
        ? lastConnected.value
        : this.lastConnected,
    isActive: isActive ?? this.isActive,
    isDefault: isDefault ?? this.isDefault,
  );
  NasServerData copyWithCompanion(NasServersCompanion data) {
    return NasServerData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      host: data.host.present ? data.host.value : this.host,
      username: data.username.present ? data.username.value : this.username,
      localUrl: data.localUrl.present ? data.localUrl.value : this.localUrl,
      trustedWifiSsids: data.trustedWifiSsids.present
          ? data.trustedWifiSsids.value
          : this.trustedWifiSsids,
      port: data.port.present ? data.port.value : this.port,
      useHttps: data.useHttps.present ? data.useHttps.value : this.useHttps,
      allowUntrustedCertificates: data.allowUntrustedCertificates.present
          ? data.allowUntrustedCertificates.value
          : this.allowUntrustedCertificates,
      lastConnected: data.lastConnected.present
          ? data.lastConnected.value
          : this.lastConnected,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NasServerData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('host: $host, ')
          ..write('username: $username, ')
          ..write('localUrl: $localUrl, ')
          ..write('trustedWifiSsids: $trustedWifiSsids, ')
          ..write('port: $port, ')
          ..write('useHttps: $useHttps, ')
          ..write('allowUntrustedCertificates: $allowUntrustedCertificates, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    host,
    username,
    localUrl,
    trustedWifiSsids,
    port,
    useHttps,
    allowUntrustedCertificates,
    lastConnected,
    isActive,
    isDefault,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NasServerData &&
          other.id == this.id &&
          other.name == this.name &&
          other.host == this.host &&
          other.username == this.username &&
          other.localUrl == this.localUrl &&
          other.trustedWifiSsids == this.trustedWifiSsids &&
          other.port == this.port &&
          other.useHttps == this.useHttps &&
          other.allowUntrustedCertificates == this.allowUntrustedCertificates &&
          other.lastConnected == this.lastConnected &&
          other.isActive == this.isActive &&
          other.isDefault == this.isDefault);
}

class NasServersCompanion extends UpdateCompanion<NasServerData> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> host;
  final Value<String> username;
  final Value<String?> localUrl;
  final Value<String> trustedWifiSsids;
  final Value<int?> port;
  final Value<bool> useHttps;
  final Value<bool> allowUntrustedCertificates;
  final Value<DateTime?> lastConnected;
  final Value<bool> isActive;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const NasServersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.host = const Value.absent(),
    this.username = const Value.absent(),
    this.localUrl = const Value.absent(),
    this.trustedWifiSsids = const Value.absent(),
    this.port = const Value.absent(),
    this.useHttps = const Value.absent(),
    this.allowUntrustedCertificates = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NasServersCompanion.insert({
    required String id,
    required String name,
    required String host,
    this.username = const Value.absent(),
    this.localUrl = const Value.absent(),
    this.trustedWifiSsids = const Value.absent(),
    this.port = const Value.absent(),
    this.useHttps = const Value.absent(),
    this.allowUntrustedCertificates = const Value.absent(),
    this.lastConnected = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       host = Value(host);
  static Insertable<NasServerData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? host,
    Expression<String>? username,
    Expression<String>? localUrl,
    Expression<String>? trustedWifiSsids,
    Expression<int>? port,
    Expression<bool>? useHttps,
    Expression<bool>? allowUntrustedCertificates,
    Expression<DateTime>? lastConnected,
    Expression<bool>? isActive,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (host != null) 'host': host,
      if (username != null) 'username': username,
      if (localUrl != null) 'local_url': localUrl,
      if (trustedWifiSsids != null) 'trusted_wifi_ssids': trustedWifiSsids,
      if (port != null) 'port': port,
      if (useHttps != null) 'use_https': useHttps,
      if (allowUntrustedCertificates != null)
        'allow_untrusted_certificates': allowUntrustedCertificates,
      if (lastConnected != null) 'last_connected': lastConnected,
      if (isActive != null) 'is_active': isActive,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NasServersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? host,
    Value<String>? username,
    Value<String?>? localUrl,
    Value<String>? trustedWifiSsids,
    Value<int?>? port,
    Value<bool>? useHttps,
    Value<bool>? allowUntrustedCertificates,
    Value<DateTime?>? lastConnected,
    Value<bool>? isActive,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return NasServersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      username: username ?? this.username,
      localUrl: localUrl ?? this.localUrl,
      trustedWifiSsids: trustedWifiSsids ?? this.trustedWifiSsids,
      port: port ?? this.port,
      useHttps: useHttps ?? this.useHttps,
      allowUntrustedCertificates:
          allowUntrustedCertificates ?? this.allowUntrustedCertificates,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
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
    if (username.present) {
      map['username'] = Variable<String>(username.value);
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
    if (useHttps.present) {
      map['use_https'] = Variable<bool>(useHttps.value);
    }
    if (allowUntrustedCertificates.present) {
      map['allow_untrusted_certificates'] = Variable<bool>(
        allowUntrustedCertificates.value,
      );
    }
    if (lastConnected.present) {
      map['last_connected'] = Variable<DateTime>(lastConnected.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
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
          ..write('username: $username, ')
          ..write('localUrl: $localUrl, ')
          ..write('trustedWifiSsids: $trustedWifiSsids, ')
          ..write('port: $port, ')
          ..write('useHttps: $useHttps, ')
          ..write('allowUntrustedCertificates: $allowUntrustedCertificates, ')
          ..write('lastConnected: $lastConnected, ')
          ..write('isActive: $isActive, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppConfigsTable extends AppConfigs
    with TableInfo<$AppConfigsTable, AppConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nas_servers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _appNameMeta = const VerificationMeta(
    'appName',
  );
  @override
  late final GeneratedColumn<String> appName = GeneratedColumn<String>(
    'app_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconUrlMeta = const VerificationMeta(
    'iconUrl',
  );
  @override
  late final GeneratedColumn<String> iconUrl = GeneratedColumn<String>(
    'icon_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installedMeta = const VerificationMeta(
    'installed',
  );
  @override
  late final GeneratedColumn<bool> installed = GeneratedColumn<bool>(
    'installed',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("installed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _healthyMeta = const VerificationMeta(
    'healthy',
  );
  @override
  late final GeneratedColumn<bool> healthy = GeneratedColumn<bool>(
    'healthy',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("healthy" IN (0, 1))',
    ),
  );
  static const VerificationMeta _healthyErrorMeta = const VerificationMeta(
    'healthyError',
  );
  @override
  late final GeneratedColumn<String> healthyError = GeneratedColumn<String>(
    'healthy_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<String> version = GeneratedColumn<String>(
    'version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _humanVersionMeta = const VerificationMeta(
    'humanVersion',
  );
  @override
  late final GeneratedColumn<String> humanVersion = GeneratedColumn<String>(
    'human_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriesMeta = const VerificationMeta(
    'categories',
  );
  @override
  late final GeneratedColumn<String> categories = GeneratedColumn<String>(
    'categories',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _homeMeta = const VerificationMeta('home');
  @override
  late final GeneratedColumn<String> home = GeneratedColumn<String>(
    'home',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tagsMeta = const VerificationMeta('tags');
  @override
  late final GeneratedColumn<String> tags = GeneratedColumn<String>(
    'tags',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recommendedMeta = const VerificationMeta(
    'recommended',
  );
  @override
  late final GeneratedColumn<bool> recommended = GeneratedColumn<bool>(
    'recommended',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("recommended" IN (0, 1))',
    ),
  );
  static const VerificationMeta _catalogMeta = const VerificationMeta(
    'catalog',
  );
  @override
  late final GeneratedColumn<String> catalog = GeneratedColumn<String>(
    'catalog',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _trainMeta = const VerificationMeta('train');
  @override
  late final GeneratedColumn<String> train = GeneratedColumn<String>(
    'train',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastApiUpdateMeta = const VerificationMeta(
    'lastApiUpdate',
  );
  @override
  late final GeneratedColumn<DateTime> lastApiUpdate =
      GeneratedColumn<DateTime>(
        'last_api_update',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _screenshotsMeta = const VerificationMeta(
    'screenshots',
  );
  @override
  late final GeneratedColumn<String> screenshots = GeneratedColumn<String>(
    'screenshots',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcesMeta = const VerificationMeta(
    'sources',
  );
  @override
  late final GeneratedColumn<String> sources = GeneratedColumn<String>(
    'sources',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appReadmeMeta = const VerificationMeta(
    'appReadme',
  );
  @override
  late final GeneratedColumn<String> appReadme = GeneratedColumn<String>(
    'app_readme',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maintainersJsonMeta = const VerificationMeta(
    'maintainersJson',
  );
  @override
  late final GeneratedColumn<String> maintainersJson = GeneratedColumn<String>(
    'maintainers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _upgradeInfoJsonMeta = const VerificationMeta(
    'upgradeInfoJson',
  );
  @override
  late final GeneratedColumn<String> upgradeInfoJson = GeneratedColumn<String>(
    'upgrade_info_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedPortsJsonMeta = const VerificationMeta(
    'usedPortsJson',
  );
  @override
  late final GeneratedColumn<String> usedPortsJson = GeneratedColumn<String>(
    'used_ports_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    serverId,
    appName,
    displayName,
    iconUrl,
    isEnabled,
    isFavorite,
    createdAt,
    updatedAt,
    title,
    description,
    installed,
    healthy,
    healthyError,
    version,
    appVersion,
    humanVersion,
    categories,
    home,
    tags,
    recommended,
    catalog,
    train,
    lastApiUpdate,
    screenshots,
    sources,
    appReadme,
    maintainersJson,
    upgradeInfoJson,
    usedPortsJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_serverIdMeta);
    }
    if (data.containsKey('app_name')) {
      context.handle(
        _appNameMeta,
        appName.isAcceptableOrUnknown(data['app_name']!, _appNameMeta),
      );
    } else if (isInserting) {
      context.missing(_appNameMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('icon_url')) {
      context.handle(
        _iconUrlMeta,
        iconUrl.isAcceptableOrUnknown(data['icon_url']!, _iconUrlMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('installed')) {
      context.handle(
        _installedMeta,
        installed.isAcceptableOrUnknown(data['installed']!, _installedMeta),
      );
    }
    if (data.containsKey('healthy')) {
      context.handle(
        _healthyMeta,
        healthy.isAcceptableOrUnknown(data['healthy']!, _healthyMeta),
      );
    }
    if (data.containsKey('healthy_error')) {
      context.handle(
        _healthyErrorMeta,
        healthyError.isAcceptableOrUnknown(
          data['healthy_error']!,
          _healthyErrorMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    }
    if (data.containsKey('human_version')) {
      context.handle(
        _humanVersionMeta,
        humanVersion.isAcceptableOrUnknown(
          data['human_version']!,
          _humanVersionMeta,
        ),
      );
    }
    if (data.containsKey('categories')) {
      context.handle(
        _categoriesMeta,
        categories.isAcceptableOrUnknown(data['categories']!, _categoriesMeta),
      );
    }
    if (data.containsKey('home')) {
      context.handle(
        _homeMeta,
        home.isAcceptableOrUnknown(data['home']!, _homeMeta),
      );
    }
    if (data.containsKey('tags')) {
      context.handle(
        _tagsMeta,
        tags.isAcceptableOrUnknown(data['tags']!, _tagsMeta),
      );
    }
    if (data.containsKey('recommended')) {
      context.handle(
        _recommendedMeta,
        recommended.isAcceptableOrUnknown(
          data['recommended']!,
          _recommendedMeta,
        ),
      );
    }
    if (data.containsKey('catalog')) {
      context.handle(
        _catalogMeta,
        catalog.isAcceptableOrUnknown(data['catalog']!, _catalogMeta),
      );
    }
    if (data.containsKey('train')) {
      context.handle(
        _trainMeta,
        train.isAcceptableOrUnknown(data['train']!, _trainMeta),
      );
    }
    if (data.containsKey('last_api_update')) {
      context.handle(
        _lastApiUpdateMeta,
        lastApiUpdate.isAcceptableOrUnknown(
          data['last_api_update']!,
          _lastApiUpdateMeta,
        ),
      );
    }
    if (data.containsKey('screenshots')) {
      context.handle(
        _screenshotsMeta,
        screenshots.isAcceptableOrUnknown(
          data['screenshots']!,
          _screenshotsMeta,
        ),
      );
    }
    if (data.containsKey('sources')) {
      context.handle(
        _sourcesMeta,
        sources.isAcceptableOrUnknown(data['sources']!, _sourcesMeta),
      );
    }
    if (data.containsKey('app_readme')) {
      context.handle(
        _appReadmeMeta,
        appReadme.isAcceptableOrUnknown(data['app_readme']!, _appReadmeMeta),
      );
    }
    if (data.containsKey('maintainers_json')) {
      context.handle(
        _maintainersJsonMeta,
        maintainersJson.isAcceptableOrUnknown(
          data['maintainers_json']!,
          _maintainersJsonMeta,
        ),
      );
    }
    if (data.containsKey('upgrade_info_json')) {
      context.handle(
        _upgradeInfoJsonMeta,
        upgradeInfoJson.isAcceptableOrUnknown(
          data['upgrade_info_json']!,
          _upgradeInfoJsonMeta,
        ),
      );
    }
    if (data.containsKey('used_ports_json')) {
      context.handle(
        _usedPortsJsonMeta,
        usedPortsJson.isAcceptableOrUnknown(
          data['used_ports_json']!,
          _usedPortsJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppConfigData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      )!,
      appName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_name'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      iconUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_url'],
      ),
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      installed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}installed'],
      ),
      healthy: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}healthy'],
      ),
      healthyError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}healthy_error'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      ),
      humanVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}human_version'],
      ),
      categories: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categories'],
      ),
      home: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}home'],
      ),
      tags: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags'],
      ),
      recommended: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}recommended'],
      ),
      catalog: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog'],
      ),
      train: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}train'],
      ),
      lastApiUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_api_update'],
      ),
      screenshots: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}screenshots'],
      ),
      sources: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sources'],
      ),
      appReadme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_readme'],
      ),
      maintainersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}maintainers_json'],
      ),
      upgradeInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}upgrade_info_json'],
      ),
      usedPortsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}used_ports_json'],
      ),
    );
  }

  @override
  $AppConfigsTable createAlias(String alias) {
    return $AppConfigsTable(attachedDatabase, alias);
  }
}

class AppConfigData extends DataClass implements Insertable<AppConfigData> {
  final int id;
  final String serverId;
  final String appName;
  final String? displayName;
  final String? iconUrl;
  final bool isEnabled;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;
  final String? description;
  final bool? installed;
  final bool? healthy;
  final String? healthyError;
  final String? version;
  final String? appVersion;
  final String? humanVersion;
  final String? categories;
  final String? home;
  final String? tags;
  final bool? recommended;
  final String? catalog;
  final String? train;
  final DateTime? lastApiUpdate;
  final String? screenshots;
  final String? sources;
  final String? appReadme;
  final String? maintainersJson;
  final String? upgradeInfoJson;
  final String? usedPortsJson;
  const AppConfigData({
    required this.id,
    required this.serverId,
    required this.appName,
    this.displayName,
    this.iconUrl,
    required this.isEnabled,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.title,
    this.description,
    this.installed,
    this.healthy,
    this.healthyError,
    this.version,
    this.appVersion,
    this.humanVersion,
    this.categories,
    this.home,
    this.tags,
    this.recommended,
    this.catalog,
    this.train,
    this.lastApiUpdate,
    this.screenshots,
    this.sources,
    this.appReadme,
    this.maintainersJson,
    this.upgradeInfoJson,
    this.usedPortsJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['server_id'] = Variable<String>(serverId);
    map['app_name'] = Variable<String>(appName);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || iconUrl != null) {
      map['icon_url'] = Variable<String>(iconUrl);
    }
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || installed != null) {
      map['installed'] = Variable<bool>(installed);
    }
    if (!nullToAbsent || healthy != null) {
      map['healthy'] = Variable<bool>(healthy);
    }
    if (!nullToAbsent || healthyError != null) {
      map['healthy_error'] = Variable<String>(healthyError);
    }
    if (!nullToAbsent || version != null) {
      map['version'] = Variable<String>(version);
    }
    if (!nullToAbsent || appVersion != null) {
      map['app_version'] = Variable<String>(appVersion);
    }
    if (!nullToAbsent || humanVersion != null) {
      map['human_version'] = Variable<String>(humanVersion);
    }
    if (!nullToAbsent || categories != null) {
      map['categories'] = Variable<String>(categories);
    }
    if (!nullToAbsent || home != null) {
      map['home'] = Variable<String>(home);
    }
    if (!nullToAbsent || tags != null) {
      map['tags'] = Variable<String>(tags);
    }
    if (!nullToAbsent || recommended != null) {
      map['recommended'] = Variable<bool>(recommended);
    }
    if (!nullToAbsent || catalog != null) {
      map['catalog'] = Variable<String>(catalog);
    }
    if (!nullToAbsent || train != null) {
      map['train'] = Variable<String>(train);
    }
    if (!nullToAbsent || lastApiUpdate != null) {
      map['last_api_update'] = Variable<DateTime>(lastApiUpdate);
    }
    if (!nullToAbsent || screenshots != null) {
      map['screenshots'] = Variable<String>(screenshots);
    }
    if (!nullToAbsent || sources != null) {
      map['sources'] = Variable<String>(sources);
    }
    if (!nullToAbsent || appReadme != null) {
      map['app_readme'] = Variable<String>(appReadme);
    }
    if (!nullToAbsent || maintainersJson != null) {
      map['maintainers_json'] = Variable<String>(maintainersJson);
    }
    if (!nullToAbsent || upgradeInfoJson != null) {
      map['upgrade_info_json'] = Variable<String>(upgradeInfoJson);
    }
    if (!nullToAbsent || usedPortsJson != null) {
      map['used_ports_json'] = Variable<String>(usedPortsJson);
    }
    return map;
  }

  AppConfigsCompanion toCompanion(bool nullToAbsent) {
    return AppConfigsCompanion(
      id: Value(id),
      serverId: Value(serverId),
      appName: Value(appName),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      iconUrl: iconUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(iconUrl),
      isEnabled: Value(isEnabled),
      isFavorite: Value(isFavorite),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      installed: installed == null && nullToAbsent
          ? const Value.absent()
          : Value(installed),
      healthy: healthy == null && nullToAbsent
          ? const Value.absent()
          : Value(healthy),
      healthyError: healthyError == null && nullToAbsent
          ? const Value.absent()
          : Value(healthyError),
      version: version == null && nullToAbsent
          ? const Value.absent()
          : Value(version),
      appVersion: appVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(appVersion),
      humanVersion: humanVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(humanVersion),
      categories: categories == null && nullToAbsent
          ? const Value.absent()
          : Value(categories),
      home: home == null && nullToAbsent ? const Value.absent() : Value(home),
      tags: tags == null && nullToAbsent ? const Value.absent() : Value(tags),
      recommended: recommended == null && nullToAbsent
          ? const Value.absent()
          : Value(recommended),
      catalog: catalog == null && nullToAbsent
          ? const Value.absent()
          : Value(catalog),
      train: train == null && nullToAbsent
          ? const Value.absent()
          : Value(train),
      lastApiUpdate: lastApiUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastApiUpdate),
      screenshots: screenshots == null && nullToAbsent
          ? const Value.absent()
          : Value(screenshots),
      sources: sources == null && nullToAbsent
          ? const Value.absent()
          : Value(sources),
      appReadme: appReadme == null && nullToAbsent
          ? const Value.absent()
          : Value(appReadme),
      maintainersJson: maintainersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(maintainersJson),
      upgradeInfoJson: upgradeInfoJson == null && nullToAbsent
          ? const Value.absent()
          : Value(upgradeInfoJson),
      usedPortsJson: usedPortsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(usedPortsJson),
    );
  }

  factory AppConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppConfigData(
      id: serializer.fromJson<int>(json['id']),
      serverId: serializer.fromJson<String>(json['serverId']),
      appName: serializer.fromJson<String>(json['appName']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      iconUrl: serializer.fromJson<String?>(json['iconUrl']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      title: serializer.fromJson<String?>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      installed: serializer.fromJson<bool?>(json['installed']),
      healthy: serializer.fromJson<bool?>(json['healthy']),
      healthyError: serializer.fromJson<String?>(json['healthyError']),
      version: serializer.fromJson<String?>(json['version']),
      appVersion: serializer.fromJson<String?>(json['appVersion']),
      humanVersion: serializer.fromJson<String?>(json['humanVersion']),
      categories: serializer.fromJson<String?>(json['categories']),
      home: serializer.fromJson<String?>(json['home']),
      tags: serializer.fromJson<String?>(json['tags']),
      recommended: serializer.fromJson<bool?>(json['recommended']),
      catalog: serializer.fromJson<String?>(json['catalog']),
      train: serializer.fromJson<String?>(json['train']),
      lastApiUpdate: serializer.fromJson<DateTime?>(json['lastApiUpdate']),
      screenshots: serializer.fromJson<String?>(json['screenshots']),
      sources: serializer.fromJson<String?>(json['sources']),
      appReadme: serializer.fromJson<String?>(json['appReadme']),
      maintainersJson: serializer.fromJson<String?>(json['maintainersJson']),
      upgradeInfoJson: serializer.fromJson<String?>(json['upgradeInfoJson']),
      usedPortsJson: serializer.fromJson<String?>(json['usedPortsJson']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'serverId': serializer.toJson<String>(serverId),
      'appName': serializer.toJson<String>(appName),
      'displayName': serializer.toJson<String?>(displayName),
      'iconUrl': serializer.toJson<String?>(iconUrl),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'title': serializer.toJson<String?>(title),
      'description': serializer.toJson<String?>(description),
      'installed': serializer.toJson<bool?>(installed),
      'healthy': serializer.toJson<bool?>(healthy),
      'healthyError': serializer.toJson<String?>(healthyError),
      'version': serializer.toJson<String?>(version),
      'appVersion': serializer.toJson<String?>(appVersion),
      'humanVersion': serializer.toJson<String?>(humanVersion),
      'categories': serializer.toJson<String?>(categories),
      'home': serializer.toJson<String?>(home),
      'tags': serializer.toJson<String?>(tags),
      'recommended': serializer.toJson<bool?>(recommended),
      'catalog': serializer.toJson<String?>(catalog),
      'train': serializer.toJson<String?>(train),
      'lastApiUpdate': serializer.toJson<DateTime?>(lastApiUpdate),
      'screenshots': serializer.toJson<String?>(screenshots),
      'sources': serializer.toJson<String?>(sources),
      'appReadme': serializer.toJson<String?>(appReadme),
      'maintainersJson': serializer.toJson<String?>(maintainersJson),
      'upgradeInfoJson': serializer.toJson<String?>(upgradeInfoJson),
      'usedPortsJson': serializer.toJson<String?>(usedPortsJson),
    };
  }

  AppConfigData copyWith({
    int? id,
    String? serverId,
    String? appName,
    Value<String?> displayName = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    bool? isEnabled,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> title = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<bool?> installed = const Value.absent(),
    Value<bool?> healthy = const Value.absent(),
    Value<String?> healthyError = const Value.absent(),
    Value<String?> version = const Value.absent(),
    Value<String?> appVersion = const Value.absent(),
    Value<String?> humanVersion = const Value.absent(),
    Value<String?> categories = const Value.absent(),
    Value<String?> home = const Value.absent(),
    Value<String?> tags = const Value.absent(),
    Value<bool?> recommended = const Value.absent(),
    Value<String?> catalog = const Value.absent(),
    Value<String?> train = const Value.absent(),
    Value<DateTime?> lastApiUpdate = const Value.absent(),
    Value<String?> screenshots = const Value.absent(),
    Value<String?> sources = const Value.absent(),
    Value<String?> appReadme = const Value.absent(),
    Value<String?> maintainersJson = const Value.absent(),
    Value<String?> upgradeInfoJson = const Value.absent(),
    Value<String?> usedPortsJson = const Value.absent(),
  }) => AppConfigData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    appName: appName ?? this.appName,
    displayName: displayName.present ? displayName.value : this.displayName,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    isEnabled: isEnabled ?? this.isEnabled,
    isFavorite: isFavorite ?? this.isFavorite,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    title: title.present ? title.value : this.title,
    description: description.present ? description.value : this.description,
    installed: installed.present ? installed.value : this.installed,
    healthy: healthy.present ? healthy.value : this.healthy,
    healthyError: healthyError.present ? healthyError.value : this.healthyError,
    version: version.present ? version.value : this.version,
    appVersion: appVersion.present ? appVersion.value : this.appVersion,
    humanVersion: humanVersion.present ? humanVersion.value : this.humanVersion,
    categories: categories.present ? categories.value : this.categories,
    home: home.present ? home.value : this.home,
    tags: tags.present ? tags.value : this.tags,
    recommended: recommended.present ? recommended.value : this.recommended,
    catalog: catalog.present ? catalog.value : this.catalog,
    train: train.present ? train.value : this.train,
    lastApiUpdate: lastApiUpdate.present
        ? lastApiUpdate.value
        : this.lastApiUpdate,
    screenshots: screenshots.present ? screenshots.value : this.screenshots,
    sources: sources.present ? sources.value : this.sources,
    appReadme: appReadme.present ? appReadme.value : this.appReadme,
    maintainersJson: maintainersJson.present
        ? maintainersJson.value
        : this.maintainersJson,
    upgradeInfoJson: upgradeInfoJson.present
        ? upgradeInfoJson.value
        : this.upgradeInfoJson,
    usedPortsJson: usedPortsJson.present
        ? usedPortsJson.value
        : this.usedPortsJson,
  );
  AppConfigData copyWithCompanion(AppConfigsCompanion data) {
    return AppConfigData(
      id: data.id.present ? data.id.value : this.id,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      appName: data.appName.present ? data.appName.value : this.appName,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      iconUrl: data.iconUrl.present ? data.iconUrl.value : this.iconUrl,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      installed: data.installed.present ? data.installed.value : this.installed,
      healthy: data.healthy.present ? data.healthy.value : this.healthy,
      healthyError: data.healthyError.present
          ? data.healthyError.value
          : this.healthyError,
      version: data.version.present ? data.version.value : this.version,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
      humanVersion: data.humanVersion.present
          ? data.humanVersion.value
          : this.humanVersion,
      categories: data.categories.present
          ? data.categories.value
          : this.categories,
      home: data.home.present ? data.home.value : this.home,
      tags: data.tags.present ? data.tags.value : this.tags,
      recommended: data.recommended.present
          ? data.recommended.value
          : this.recommended,
      catalog: data.catalog.present ? data.catalog.value : this.catalog,
      train: data.train.present ? data.train.value : this.train,
      lastApiUpdate: data.lastApiUpdate.present
          ? data.lastApiUpdate.value
          : this.lastApiUpdate,
      screenshots: data.screenshots.present
          ? data.screenshots.value
          : this.screenshots,
      sources: data.sources.present ? data.sources.value : this.sources,
      appReadme: data.appReadme.present ? data.appReadme.value : this.appReadme,
      maintainersJson: data.maintainersJson.present
          ? data.maintainersJson.value
          : this.maintainersJson,
      upgradeInfoJson: data.upgradeInfoJson.present
          ? data.upgradeInfoJson.value
          : this.upgradeInfoJson,
      usedPortsJson: data.usedPortsJson.present
          ? data.usedPortsJson.value
          : this.usedPortsJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigData(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('appName: $appName, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('installed: $installed, ')
          ..write('healthy: $healthy, ')
          ..write('healthyError: $healthyError, ')
          ..write('version: $version, ')
          ..write('appVersion: $appVersion, ')
          ..write('humanVersion: $humanVersion, ')
          ..write('categories: $categories, ')
          ..write('home: $home, ')
          ..write('tags: $tags, ')
          ..write('recommended: $recommended, ')
          ..write('catalog: $catalog, ')
          ..write('train: $train, ')
          ..write('lastApiUpdate: $lastApiUpdate, ')
          ..write('screenshots: $screenshots, ')
          ..write('sources: $sources, ')
          ..write('appReadme: $appReadme, ')
          ..write('maintainersJson: $maintainersJson, ')
          ..write('upgradeInfoJson: $upgradeInfoJson, ')
          ..write('usedPortsJson: $usedPortsJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    serverId,
    appName,
    displayName,
    iconUrl,
    isEnabled,
    isFavorite,
    createdAt,
    updatedAt,
    title,
    description,
    installed,
    healthy,
    healthyError,
    version,
    appVersion,
    humanVersion,
    categories,
    home,
    tags,
    recommended,
    catalog,
    train,
    lastApiUpdate,
    screenshots,
    sources,
    appReadme,
    maintainersJson,
    upgradeInfoJson,
    usedPortsJson,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppConfigData &&
          other.id == this.id &&
          other.serverId == this.serverId &&
          other.appName == this.appName &&
          other.displayName == this.displayName &&
          other.iconUrl == this.iconUrl &&
          other.isEnabled == this.isEnabled &&
          other.isFavorite == this.isFavorite &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.title == this.title &&
          other.description == this.description &&
          other.installed == this.installed &&
          other.healthy == this.healthy &&
          other.healthyError == this.healthyError &&
          other.version == this.version &&
          other.appVersion == this.appVersion &&
          other.humanVersion == this.humanVersion &&
          other.categories == this.categories &&
          other.home == this.home &&
          other.tags == this.tags &&
          other.recommended == this.recommended &&
          other.catalog == this.catalog &&
          other.train == this.train &&
          other.lastApiUpdate == this.lastApiUpdate &&
          other.screenshots == this.screenshots &&
          other.sources == this.sources &&
          other.appReadme == this.appReadme &&
          other.maintainersJson == this.maintainersJson &&
          other.upgradeInfoJson == this.upgradeInfoJson &&
          other.usedPortsJson == this.usedPortsJson);
}

class AppConfigsCompanion extends UpdateCompanion<AppConfigData> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> appName;
  final Value<String?> displayName;
  final Value<String?> iconUrl;
  final Value<bool> isEnabled;
  final Value<bool> isFavorite;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> title;
  final Value<String?> description;
  final Value<bool?> installed;
  final Value<bool?> healthy;
  final Value<String?> healthyError;
  final Value<String?> version;
  final Value<String?> appVersion;
  final Value<String?> humanVersion;
  final Value<String?> categories;
  final Value<String?> home;
  final Value<String?> tags;
  final Value<bool?> recommended;
  final Value<String?> catalog;
  final Value<String?> train;
  final Value<DateTime?> lastApiUpdate;
  final Value<String?> screenshots;
  final Value<String?> sources;
  final Value<String?> appReadme;
  final Value<String?> maintainersJson;
  final Value<String?> upgradeInfoJson;
  final Value<String?> usedPortsJson;
  const AppConfigsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.appName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.installed = const Value.absent(),
    this.healthy = const Value.absent(),
    this.healthyError = const Value.absent(),
    this.version = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.humanVersion = const Value.absent(),
    this.categories = const Value.absent(),
    this.home = const Value.absent(),
    this.tags = const Value.absent(),
    this.recommended = const Value.absent(),
    this.catalog = const Value.absent(),
    this.train = const Value.absent(),
    this.lastApiUpdate = const Value.absent(),
    this.screenshots = const Value.absent(),
    this.sources = const Value.absent(),
    this.appReadme = const Value.absent(),
    this.maintainersJson = const Value.absent(),
    this.upgradeInfoJson = const Value.absent(),
    this.usedPortsJson = const Value.absent(),
  });
  AppConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String appName,
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.installed = const Value.absent(),
    this.healthy = const Value.absent(),
    this.healthyError = const Value.absent(),
    this.version = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.humanVersion = const Value.absent(),
    this.categories = const Value.absent(),
    this.home = const Value.absent(),
    this.tags = const Value.absent(),
    this.recommended = const Value.absent(),
    this.catalog = const Value.absent(),
    this.train = const Value.absent(),
    this.lastApiUpdate = const Value.absent(),
    this.screenshots = const Value.absent(),
    this.sources = const Value.absent(),
    this.appReadme = const Value.absent(),
    this.maintainersJson = const Value.absent(),
    this.upgradeInfoJson = const Value.absent(),
    this.usedPortsJson = const Value.absent(),
  }) : serverId = Value(serverId),
       appName = Value(appName);
  static Insertable<AppConfigData> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? appName,
    Expression<String>? displayName,
    Expression<String>? iconUrl,
    Expression<bool>? isEnabled,
    Expression<bool>? isFavorite,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? installed,
    Expression<bool>? healthy,
    Expression<String>? healthyError,
    Expression<String>? version,
    Expression<String>? appVersion,
    Expression<String>? humanVersion,
    Expression<String>? categories,
    Expression<String>? home,
    Expression<String>? tags,
    Expression<bool>? recommended,
    Expression<String>? catalog,
    Expression<String>? train,
    Expression<DateTime>? lastApiUpdate,
    Expression<String>? screenshots,
    Expression<String>? sources,
    Expression<String>? appReadme,
    Expression<String>? maintainersJson,
    Expression<String>? upgradeInfoJson,
    Expression<String>? usedPortsJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (appName != null) 'app_name': appName,
      if (displayName != null) 'display_name': displayName,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (installed != null) 'installed': installed,
      if (healthy != null) 'healthy': healthy,
      if (healthyError != null) 'healthy_error': healthyError,
      if (version != null) 'version': version,
      if (appVersion != null) 'app_version': appVersion,
      if (humanVersion != null) 'human_version': humanVersion,
      if (categories != null) 'categories': categories,
      if (home != null) 'home': home,
      if (tags != null) 'tags': tags,
      if (recommended != null) 'recommended': recommended,
      if (catalog != null) 'catalog': catalog,
      if (train != null) 'train': train,
      if (lastApiUpdate != null) 'last_api_update': lastApiUpdate,
      if (screenshots != null) 'screenshots': screenshots,
      if (sources != null) 'sources': sources,
      if (appReadme != null) 'app_readme': appReadme,
      if (maintainersJson != null) 'maintainers_json': maintainersJson,
      if (upgradeInfoJson != null) 'upgrade_info_json': upgradeInfoJson,
      if (usedPortsJson != null) 'used_ports_json': usedPortsJson,
    });
  }

  AppConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? appName,
    Value<String?>? displayName,
    Value<String?>? iconUrl,
    Value<bool>? isEnabled,
    Value<bool>? isFavorite,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? title,
    Value<String?>? description,
    Value<bool?>? installed,
    Value<bool?>? healthy,
    Value<String?>? healthyError,
    Value<String?>? version,
    Value<String?>? appVersion,
    Value<String?>? humanVersion,
    Value<String?>? categories,
    Value<String?>? home,
    Value<String?>? tags,
    Value<bool?>? recommended,
    Value<String?>? catalog,
    Value<String?>? train,
    Value<DateTime?>? lastApiUpdate,
    Value<String?>? screenshots,
    Value<String?>? sources,
    Value<String?>? appReadme,
    Value<String?>? maintainersJson,
    Value<String?>? upgradeInfoJson,
    Value<String?>? usedPortsJson,
  }) {
    return AppConfigsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      appName: appName ?? this.appName,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
      isEnabled: isEnabled ?? this.isEnabled,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      installed: installed ?? this.installed,
      healthy: healthy ?? this.healthy,
      healthyError: healthyError ?? this.healthyError,
      version: version ?? this.version,
      appVersion: appVersion ?? this.appVersion,
      humanVersion: humanVersion ?? this.humanVersion,
      categories: categories ?? this.categories,
      home: home ?? this.home,
      tags: tags ?? this.tags,
      recommended: recommended ?? this.recommended,
      catalog: catalog ?? this.catalog,
      train: train ?? this.train,
      lastApiUpdate: lastApiUpdate ?? this.lastApiUpdate,
      screenshots: screenshots ?? this.screenshots,
      sources: sources ?? this.sources,
      appReadme: appReadme ?? this.appReadme,
      maintainersJson: maintainersJson ?? this.maintainersJson,
      upgradeInfoJson: upgradeInfoJson ?? this.upgradeInfoJson,
      usedPortsJson: usedPortsJson ?? this.usedPortsJson,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (appName.present) {
      map['app_name'] = Variable<String>(appName.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (iconUrl.present) {
      map['icon_url'] = Variable<String>(iconUrl.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (installed.present) {
      map['installed'] = Variable<bool>(installed.value);
    }
    if (healthy.present) {
      map['healthy'] = Variable<bool>(healthy.value);
    }
    if (healthyError.present) {
      map['healthy_error'] = Variable<String>(healthyError.value);
    }
    if (version.present) {
      map['version'] = Variable<String>(version.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (humanVersion.present) {
      map['human_version'] = Variable<String>(humanVersion.value);
    }
    if (categories.present) {
      map['categories'] = Variable<String>(categories.value);
    }
    if (home.present) {
      map['home'] = Variable<String>(home.value);
    }
    if (tags.present) {
      map['tags'] = Variable<String>(tags.value);
    }
    if (recommended.present) {
      map['recommended'] = Variable<bool>(recommended.value);
    }
    if (catalog.present) {
      map['catalog'] = Variable<String>(catalog.value);
    }
    if (train.present) {
      map['train'] = Variable<String>(train.value);
    }
    if (lastApiUpdate.present) {
      map['last_api_update'] = Variable<DateTime>(lastApiUpdate.value);
    }
    if (screenshots.present) {
      map['screenshots'] = Variable<String>(screenshots.value);
    }
    if (sources.present) {
      map['sources'] = Variable<String>(sources.value);
    }
    if (appReadme.present) {
      map['app_readme'] = Variable<String>(appReadme.value);
    }
    if (maintainersJson.present) {
      map['maintainers_json'] = Variable<String>(maintainersJson.value);
    }
    if (upgradeInfoJson.present) {
      map['upgrade_info_json'] = Variable<String>(upgradeInfoJson.value);
    }
    if (usedPortsJson.present) {
      map['used_ports_json'] = Variable<String>(usedPortsJson.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppConfigsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('appName: $appName, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('installed: $installed, ')
          ..write('healthy: $healthy, ')
          ..write('healthyError: $healthyError, ')
          ..write('version: $version, ')
          ..write('appVersion: $appVersion, ')
          ..write('humanVersion: $humanVersion, ')
          ..write('categories: $categories, ')
          ..write('home: $home, ')
          ..write('tags: $tags, ')
          ..write('recommended: $recommended, ')
          ..write('catalog: $catalog, ')
          ..write('train: $train, ')
          ..write('lastApiUpdate: $lastApiUpdate, ')
          ..write('screenshots: $screenshots, ')
          ..write('sources: $sources, ')
          ..write('appReadme: $appReadme, ')
          ..write('maintainersJson: $maintainersJson, ')
          ..write('upgradeInfoJson: $upgradeInfoJson, ')
          ..write('usedPortsJson: $usedPortsJson')
          ..write(')'))
        .toString();
  }
}

class $AppPortConfigsTable extends AppPortConfigs
    with TableInfo<$AppPortConfigsTable, AppPortConfigData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppPortConfigsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _appConfigIdMeta = const VerificationMeta(
    'appConfigId',
  );
  @override
  late final GeneratedColumn<int> appConfigId = GeneratedColumn<int>(
    'app_config_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES app_configs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _portNumberMeta = const VerificationMeta(
    'portNumber',
  );
  @override
  late final GeneratedColumn<int> portNumber = GeneratedColumn<int>(
    'port_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta(
    'protocol',
  );
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('http'),
  );
  static const VerificationMeta _serviceNameMeta = const VerificationMeta(
    'serviceName',
  );
  @override
  late final GeneratedColumn<String> serviceName = GeneratedColumn<String>(
    'service_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customUrlMeta = const VerificationMeta(
    'customUrl',
  );
  @override
  late final GeneratedColumn<String> customUrl = GeneratedColumn<String>(
    'custom_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _apiUrlMeta = const VerificationMeta('apiUrl');
  @override
  late final GeneratedColumn<String> apiUrl = GeneratedColumn<String>(
    'api_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    appConfigId,
    portNumber,
    protocol,
    serviceName,
    customUrl,
    apiUrl,
    isPrimary,
    isEnabled,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_port_configs';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPortConfigData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('app_config_id')) {
      context.handle(
        _appConfigIdMeta,
        appConfigId.isAcceptableOrUnknown(
          data['app_config_id']!,
          _appConfigIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_appConfigIdMeta);
    }
    if (data.containsKey('port_number')) {
      context.handle(
        _portNumberMeta,
        portNumber.isAcceptableOrUnknown(data['port_number']!, _portNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_portNumberMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    }
    if (data.containsKey('service_name')) {
      context.handle(
        _serviceNameMeta,
        serviceName.isAcceptableOrUnknown(
          data['service_name']!,
          _serviceNameMeta,
        ),
      );
    }
    if (data.containsKey('custom_url')) {
      context.handle(
        _customUrlMeta,
        customUrl.isAcceptableOrUnknown(data['custom_url']!, _customUrlMeta),
      );
    }
    if (data.containsKey('api_url')) {
      context.handle(
        _apiUrlMeta,
        apiUrl.isAcceptableOrUnknown(data['api_url']!, _apiUrlMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppPortConfigData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPortConfigData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      appConfigId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}app_config_id'],
      )!,
      portNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port_number'],
      )!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      )!,
      serviceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}service_name'],
      ),
      customUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_url'],
      ),
      apiUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}api_url'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AppPortConfigsTable createAlias(String alias) {
    return $AppPortConfigsTable(attachedDatabase, alias);
  }
}

class AppPortConfigData extends DataClass
    implements Insertable<AppPortConfigData> {
  final int id;
  final int appConfigId;
  final int portNumber;
  final String protocol;
  final String? serviceName;
  final String? customUrl;
  final String? apiUrl;
  final bool isPrimary;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppPortConfigData({
    required this.id,
    required this.appConfigId,
    required this.portNumber,
    required this.protocol,
    this.serviceName,
    this.customUrl,
    this.apiUrl,
    required this.isPrimary,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['app_config_id'] = Variable<int>(appConfigId);
    map['port_number'] = Variable<int>(portNumber);
    map['protocol'] = Variable<String>(protocol);
    if (!nullToAbsent || serviceName != null) {
      map['service_name'] = Variable<String>(serviceName);
    }
    if (!nullToAbsent || customUrl != null) {
      map['custom_url'] = Variable<String>(customUrl);
    }
    if (!nullToAbsent || apiUrl != null) {
      map['api_url'] = Variable<String>(apiUrl);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['is_enabled'] = Variable<bool>(isEnabled);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AppPortConfigsCompanion toCompanion(bool nullToAbsent) {
    return AppPortConfigsCompanion(
      id: Value(id),
      appConfigId: Value(appConfigId),
      portNumber: Value(portNumber),
      protocol: Value(protocol),
      serviceName: serviceName == null && nullToAbsent
          ? const Value.absent()
          : Value(serviceName),
      customUrl: customUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(customUrl),
      apiUrl: apiUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(apiUrl),
      isPrimary: Value(isPrimary),
      isEnabled: Value(isEnabled),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppPortConfigData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPortConfigData(
      id: serializer.fromJson<int>(json['id']),
      appConfigId: serializer.fromJson<int>(json['appConfigId']),
      portNumber: serializer.fromJson<int>(json['portNumber']),
      protocol: serializer.fromJson<String>(json['protocol']),
      serviceName: serializer.fromJson<String?>(json['serviceName']),
      customUrl: serializer.fromJson<String?>(json['customUrl']),
      apiUrl: serializer.fromJson<String?>(json['apiUrl']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'appConfigId': serializer.toJson<int>(appConfigId),
      'portNumber': serializer.toJson<int>(portNumber),
      'protocol': serializer.toJson<String>(protocol),
      'serviceName': serializer.toJson<String?>(serviceName),
      'customUrl': serializer.toJson<String?>(customUrl),
      'apiUrl': serializer.toJson<String?>(apiUrl),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppPortConfigData copyWith({
    int? id,
    int? appConfigId,
    int? portNumber,
    String? protocol,
    Value<String?> serviceName = const Value.absent(),
    Value<String?> customUrl = const Value.absent(),
    Value<String?> apiUrl = const Value.absent(),
    bool? isPrimary,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppPortConfigData(
    id: id ?? this.id,
    appConfigId: appConfigId ?? this.appConfigId,
    portNumber: portNumber ?? this.portNumber,
    protocol: protocol ?? this.protocol,
    serviceName: serviceName.present ? serviceName.value : this.serviceName,
    customUrl: customUrl.present ? customUrl.value : this.customUrl,
    apiUrl: apiUrl.present ? apiUrl.value : this.apiUrl,
    isPrimary: isPrimary ?? this.isPrimary,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppPortConfigData copyWithCompanion(AppPortConfigsCompanion data) {
    return AppPortConfigData(
      id: data.id.present ? data.id.value : this.id,
      appConfigId: data.appConfigId.present
          ? data.appConfigId.value
          : this.appConfigId,
      portNumber: data.portNumber.present
          ? data.portNumber.value
          : this.portNumber,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      serviceName: data.serviceName.present
          ? data.serviceName.value
          : this.serviceName,
      customUrl: data.customUrl.present ? data.customUrl.value : this.customUrl,
      apiUrl: data.apiUrl.present ? data.apiUrl.value : this.apiUrl,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPortConfigData(')
          ..write('id: $id, ')
          ..write('appConfigId: $appConfigId, ')
          ..write('portNumber: $portNumber, ')
          ..write('protocol: $protocol, ')
          ..write('serviceName: $serviceName, ')
          ..write('customUrl: $customUrl, ')
          ..write('apiUrl: $apiUrl, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    appConfigId,
    portNumber,
    protocol,
    serviceName,
    customUrl,
    apiUrl,
    isPrimary,
    isEnabled,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPortConfigData &&
          other.id == this.id &&
          other.appConfigId == this.appConfigId &&
          other.portNumber == this.portNumber &&
          other.protocol == this.protocol &&
          other.serviceName == this.serviceName &&
          other.customUrl == this.customUrl &&
          other.apiUrl == this.apiUrl &&
          other.isPrimary == this.isPrimary &&
          other.isEnabled == this.isEnabled &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppPortConfigsCompanion extends UpdateCompanion<AppPortConfigData> {
  final Value<int> id;
  final Value<int> appConfigId;
  final Value<int> portNumber;
  final Value<String> protocol;
  final Value<String?> serviceName;
  final Value<String?> customUrl;
  final Value<String?> apiUrl;
  final Value<bool> isPrimary;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppPortConfigsCompanion({
    this.id = const Value.absent(),
    this.appConfigId = const Value.absent(),
    this.portNumber = const Value.absent(),
    this.protocol = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.customUrl = const Value.absent(),
    this.apiUrl = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppPortConfigsCompanion.insert({
    this.id = const Value.absent(),
    required int appConfigId,
    required int portNumber,
    this.protocol = const Value.absent(),
    this.serviceName = const Value.absent(),
    this.customUrl = const Value.absent(),
    this.apiUrl = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : appConfigId = Value(appConfigId),
       portNumber = Value(portNumber);
  static Insertable<AppPortConfigData> custom({
    Expression<int>? id,
    Expression<int>? appConfigId,
    Expression<int>? portNumber,
    Expression<String>? protocol,
    Expression<String>? serviceName,
    Expression<String>? customUrl,
    Expression<String>? apiUrl,
    Expression<bool>? isPrimary,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (appConfigId != null) 'app_config_id': appConfigId,
      if (portNumber != null) 'port_number': portNumber,
      if (protocol != null) 'protocol': protocol,
      if (serviceName != null) 'service_name': serviceName,
      if (customUrl != null) 'custom_url': customUrl,
      if (apiUrl != null) 'api_url': apiUrl,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppPortConfigsCompanion copyWith({
    Value<int>? id,
    Value<int>? appConfigId,
    Value<int>? portNumber,
    Value<String>? protocol,
    Value<String?>? serviceName,
    Value<String?>? customUrl,
    Value<String?>? apiUrl,
    Value<bool>? isPrimary,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppPortConfigsCompanion(
      id: id ?? this.id,
      appConfigId: appConfigId ?? this.appConfigId,
      portNumber: portNumber ?? this.portNumber,
      protocol: protocol ?? this.protocol,
      serviceName: serviceName ?? this.serviceName,
      customUrl: customUrl ?? this.customUrl,
      apiUrl: apiUrl ?? this.apiUrl,
      isPrimary: isPrimary ?? this.isPrimary,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (appConfigId.present) {
      map['app_config_id'] = Variable<int>(appConfigId.value);
    }
    if (portNumber.present) {
      map['port_number'] = Variable<int>(portNumber.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (serviceName.present) {
      map['service_name'] = Variable<String>(serviceName.value);
    }
    if (customUrl.present) {
      map['custom_url'] = Variable<String>(customUrl.value);
    }
    if (apiUrl.present) {
      map['api_url'] = Variable<String>(apiUrl.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPortConfigsCompanion(')
          ..write('id: $id, ')
          ..write('appConfigId: $appConfigId, ')
          ..write('portNumber: $portNumber, ')
          ..write('protocol: $protocol, ')
          ..write('serviceName: $serviceName, ')
          ..write('customUrl: $customUrl, ')
          ..write('apiUrl: $apiUrl, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $NasServersTable nasServers = $NasServersTable(this);
  late final $AppConfigsTable appConfigs = $AppConfigsTable(this);
  late final $AppPortConfigsTable appPortConfigs = $AppPortConfigsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nasServers,
    appConfigs,
    appPortConfigs,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nas_servers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_configs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'app_configs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('app_port_configs', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$NasServersTableCreateCompanionBuilder =
    NasServersCompanion Function({
      required String id,
      required String name,
      required String host,
      Value<String> username,
      Value<String?> localUrl,
      Value<String> trustedWifiSsids,
      Value<int?> port,
      Value<bool> useHttps,
      Value<bool> allowUntrustedCertificates,
      Value<DateTime?> lastConnected,
      Value<bool> isActive,
      Value<bool> isDefault,
      Value<int> rowid,
    });
typedef $$NasServersTableUpdateCompanionBuilder =
    NasServersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> host,
      Value<String> username,
      Value<String?> localUrl,
      Value<String> trustedWifiSsids,
      Value<int?> port,
      Value<bool> useHttps,
      Value<bool> allowUntrustedCertificates,
      Value<DateTime?> lastConnected,
      Value<bool> isActive,
      Value<bool> isDefault,
      Value<int> rowid,
    });

final class $$NasServersTableReferences
    extends BaseReferences<_$AppDatabase, $NasServersTable, NasServerData> {
  $$NasServersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AppConfigsTable, List<AppConfigData>>
  _appConfigsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appConfigs,
    aliasName: 'nas_servers__id__app_configs__server_id',
  );

  $$AppConfigsTableProcessedTableManager get appConfigsRefs {
    final manager = $$AppConfigsTableTableManager(
      $_db,
      $_db.appConfigs,
    ).filter((f) => f.serverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_appConfigsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
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

  ColumnFilters<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowUntrustedCertificates => $composableBuilder(
    column: $table.allowUntrustedCertificates,
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

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> appConfigsRefs(
    Expression<bool> Function($$AppConfigsTableFilterComposer f) f,
  ) {
    final $$AppConfigsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appConfigs,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppConfigsTableFilterComposer(
            $db: $db,
            $table: $db.appConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
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

  ColumnOrderings<bool> get useHttps => $composableBuilder(
    column: $table.useHttps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowUntrustedCertificates => $composableBuilder(
    column: $table.allowUntrustedCertificates,
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

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
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

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get localUrl =>
      $composableBuilder(column: $table.localUrl, builder: (column) => column);

  GeneratedColumn<String> get trustedWifiSsids => $composableBuilder(
    column: $table.trustedWifiSsids,
    builder: (column) => column,
  );

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<bool> get useHttps =>
      $composableBuilder(column: $table.useHttps, builder: (column) => column);

  GeneratedColumn<bool> get allowUntrustedCertificates => $composableBuilder(
    column: $table.allowUntrustedCertificates,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastConnected => $composableBuilder(
    column: $table.lastConnected,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  Expression<T> appConfigsRefs<T extends Object>(
    Expression<T> Function($$AppConfigsTableAnnotationComposer a) f,
  ) {
    final $$AppConfigsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appConfigs,
      getReferencedColumn: (t) => t.serverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppConfigsTableAnnotationComposer(
            $db: $db,
            $table: $db.appConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (NasServerData, $$NasServersTableReferences),
          NasServerData,
          PrefetchHooks Function({bool appConfigsRefs})
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
                Value<String> username = const Value.absent(),
                Value<String?> localUrl = const Value.absent(),
                Value<String> trustedWifiSsids = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<bool> useHttps = const Value.absent(),
                Value<bool> allowUntrustedCertificates = const Value.absent(),
                Value<DateTime?> lastConnected = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NasServersCompanion(
                id: id,
                name: name,
                host: host,
                username: username,
                localUrl: localUrl,
                trustedWifiSsids: trustedWifiSsids,
                port: port,
                useHttps: useHttps,
                allowUntrustedCertificates: allowUntrustedCertificates,
                lastConnected: lastConnected,
                isActive: isActive,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String host,
                Value<String> username = const Value.absent(),
                Value<String?> localUrl = const Value.absent(),
                Value<String> trustedWifiSsids = const Value.absent(),
                Value<int?> port = const Value.absent(),
                Value<bool> useHttps = const Value.absent(),
                Value<bool> allowUntrustedCertificates = const Value.absent(),
                Value<DateTime?> lastConnected = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NasServersCompanion.insert(
                id: id,
                name: name,
                host: host,
                username: username,
                localUrl: localUrl,
                trustedWifiSsids: trustedWifiSsids,
                port: port,
                useHttps: useHttps,
                allowUntrustedCertificates: allowUntrustedCertificates,
                lastConnected: lastConnected,
                isActive: isActive,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$NasServersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({appConfigsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (appConfigsRefs) db.appConfigs],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (appConfigsRefs)
                    await $_getPrefetchedData<
                      NasServerData,
                      $NasServersTable,
                      AppConfigData
                    >(
                      currentTable: table,
                      referencedTable: $$NasServersTableReferences
                          ._appConfigsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$NasServersTableReferences(
                            db,
                            table,
                            p0,
                          ).appConfigsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.serverId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (NasServerData, $$NasServersTableReferences),
      NasServerData,
      PrefetchHooks Function({bool appConfigsRefs})
    >;
typedef $$AppConfigsTableCreateCompanionBuilder =
    AppConfigsCompanion Function({
      Value<int> id,
      required String serverId,
      required String appName,
      Value<String?> displayName,
      Value<String?> iconUrl,
      Value<bool> isEnabled,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> title,
      Value<String?> description,
      Value<bool?> installed,
      Value<bool?> healthy,
      Value<String?> healthyError,
      Value<String?> version,
      Value<String?> appVersion,
      Value<String?> humanVersion,
      Value<String?> categories,
      Value<String?> home,
      Value<String?> tags,
      Value<bool?> recommended,
      Value<String?> catalog,
      Value<String?> train,
      Value<DateTime?> lastApiUpdate,
      Value<String?> screenshots,
      Value<String?> sources,
      Value<String?> appReadme,
      Value<String?> maintainersJson,
      Value<String?> upgradeInfoJson,
      Value<String?> usedPortsJson,
    });
typedef $$AppConfigsTableUpdateCompanionBuilder =
    AppConfigsCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> appName,
      Value<String?> displayName,
      Value<String?> iconUrl,
      Value<bool> isEnabled,
      Value<bool> isFavorite,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> title,
      Value<String?> description,
      Value<bool?> installed,
      Value<bool?> healthy,
      Value<String?> healthyError,
      Value<String?> version,
      Value<String?> appVersion,
      Value<String?> humanVersion,
      Value<String?> categories,
      Value<String?> home,
      Value<String?> tags,
      Value<bool?> recommended,
      Value<String?> catalog,
      Value<String?> train,
      Value<DateTime?> lastApiUpdate,
      Value<String?> screenshots,
      Value<String?> sources,
      Value<String?> appReadme,
      Value<String?> maintainersJson,
      Value<String?> upgradeInfoJson,
      Value<String?> usedPortsJson,
    });

final class $$AppConfigsTableReferences
    extends BaseReferences<_$AppDatabase, $AppConfigsTable, AppConfigData> {
  $$AppConfigsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NasServersTable _serverIdTable(_$AppDatabase db) =>
      db.nasServers.createAlias('app_configs__server_id__nas_servers__id');

  $$NasServersTableProcessedTableManager get serverId {
    final $_column = $_itemColumn<String>('server_id')!;

    final manager = $$NasServersTableTableManager(
      $_db,
      $_db.nasServers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_serverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AppPortConfigsTable, List<AppPortConfigData>>
  _appPortConfigsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.appPortConfigs,
    aliasName: 'app_configs__id__app_port_configs__app_config_id',
  );

  $$AppPortConfigsTableProcessedTableManager get appPortConfigsRefs {
    final manager = $$AppPortConfigsTableTableManager(
      $_db,
      $_db.appPortConfigs,
    ).filter((f) => f.appConfigId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_appPortConfigsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AppConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $AppConfigsTable> {
  $$AppConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get healthy => $composableBuilder(
    column: $table.healthy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get healthyError => $composableBuilder(
    column: $table.healthyError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get humanVersion => $composableBuilder(
    column: $table.humanVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get home => $composableBuilder(
    column: $table.home,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get recommended => $composableBuilder(
    column: $table.recommended,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalog => $composableBuilder(
    column: $table.catalog,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get train => $composableBuilder(
    column: $table.train,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastApiUpdate => $composableBuilder(
    column: $table.lastApiUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get screenshots => $composableBuilder(
    column: $table.screenshots,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appReadme => $composableBuilder(
    column: $table.appReadme,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get maintainersJson => $composableBuilder(
    column: $table.maintainersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get upgradeInfoJson => $composableBuilder(
    column: $table.upgradeInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usedPortsJson => $composableBuilder(
    column: $table.usedPortsJson,
    builder: (column) => ColumnFilters(column),
  );

  $$NasServersTableFilterComposer get serverId {
    final $$NasServersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.nasServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NasServersTableFilterComposer(
            $db: $db,
            $table: $db.nasServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> appPortConfigsRefs(
    Expression<bool> Function($$AppPortConfigsTableFilterComposer f) f,
  ) {
    final $$AppPortConfigsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appPortConfigs,
      getReferencedColumn: (t) => t.appConfigId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppPortConfigsTableFilterComposer(
            $db: $db,
            $table: $db.appPortConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AppConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppConfigsTable> {
  $$AppConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appName => $composableBuilder(
    column: $table.appName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconUrl => $composableBuilder(
    column: $table.iconUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get installed => $composableBuilder(
    column: $table.installed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get healthy => $composableBuilder(
    column: $table.healthy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get healthyError => $composableBuilder(
    column: $table.healthyError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get humanVersion => $composableBuilder(
    column: $table.humanVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get home => $composableBuilder(
    column: $table.home,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tags => $composableBuilder(
    column: $table.tags,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get recommended => $composableBuilder(
    column: $table.recommended,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalog => $composableBuilder(
    column: $table.catalog,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get train => $composableBuilder(
    column: $table.train,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastApiUpdate => $composableBuilder(
    column: $table.lastApiUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get screenshots => $composableBuilder(
    column: $table.screenshots,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sources => $composableBuilder(
    column: $table.sources,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appReadme => $composableBuilder(
    column: $table.appReadme,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get maintainersJson => $composableBuilder(
    column: $table.maintainersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get upgradeInfoJson => $composableBuilder(
    column: $table.upgradeInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usedPortsJson => $composableBuilder(
    column: $table.usedPortsJson,
    builder: (column) => ColumnOrderings(column),
  );

  $$NasServersTableOrderingComposer get serverId {
    final $$NasServersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.nasServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NasServersTableOrderingComposer(
            $db: $db,
            $table: $db.nasServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppConfigsTable> {
  $$AppConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get appName =>
      $composableBuilder(column: $table.appName, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconUrl =>
      $composableBuilder(column: $table.iconUrl, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get installed =>
      $composableBuilder(column: $table.installed, builder: (column) => column);

  GeneratedColumn<bool> get healthy =>
      $composableBuilder(column: $table.healthy, builder: (column) => column);

  GeneratedColumn<String> get healthyError => $composableBuilder(
    column: $table.healthyError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get humanVersion => $composableBuilder(
    column: $table.humanVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categories => $composableBuilder(
    column: $table.categories,
    builder: (column) => column,
  );

  GeneratedColumn<String> get home =>
      $composableBuilder(column: $table.home, builder: (column) => column);

  GeneratedColumn<String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumn<bool> get recommended => $composableBuilder(
    column: $table.recommended,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalog =>
      $composableBuilder(column: $table.catalog, builder: (column) => column);

  GeneratedColumn<String> get train =>
      $composableBuilder(column: $table.train, builder: (column) => column);

  GeneratedColumn<DateTime> get lastApiUpdate => $composableBuilder(
    column: $table.lastApiUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get screenshots => $composableBuilder(
    column: $table.screenshots,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sources =>
      $composableBuilder(column: $table.sources, builder: (column) => column);

  GeneratedColumn<String> get appReadme =>
      $composableBuilder(column: $table.appReadme, builder: (column) => column);

  GeneratedColumn<String> get maintainersJson => $composableBuilder(
    column: $table.maintainersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get upgradeInfoJson => $composableBuilder(
    column: $table.upgradeInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usedPortsJson => $composableBuilder(
    column: $table.usedPortsJson,
    builder: (column) => column,
  );

  $$NasServersTableAnnotationComposer get serverId {
    final $$NasServersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.serverId,
      referencedTable: $db.nasServers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NasServersTableAnnotationComposer(
            $db: $db,
            $table: $db.nasServers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> appPortConfigsRefs<T extends Object>(
    Expression<T> Function($$AppPortConfigsTableAnnotationComposer a) f,
  ) {
    final $$AppPortConfigsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.appPortConfigs,
      getReferencedColumn: (t) => t.appConfigId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppPortConfigsTableAnnotationComposer(
            $db: $db,
            $table: $db.appPortConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AppConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppConfigsTable,
          AppConfigData,
          $$AppConfigsTableFilterComposer,
          $$AppConfigsTableOrderingComposer,
          $$AppConfigsTableAnnotationComposer,
          $$AppConfigsTableCreateCompanionBuilder,
          $$AppConfigsTableUpdateCompanionBuilder,
          (AppConfigData, $$AppConfigsTableReferences),
          AppConfigData,
          PrefetchHooks Function({bool serverId, bool appPortConfigsRefs})
        > {
  $$AppConfigsTableTableManager(_$AppDatabase db, $AppConfigsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> serverId = const Value.absent(),
                Value<String> appName = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool?> installed = const Value.absent(),
                Value<bool?> healthy = const Value.absent(),
                Value<String?> healthyError = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                Value<String?> humanVersion = const Value.absent(),
                Value<String?> categories = const Value.absent(),
                Value<String?> home = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool?> recommended = const Value.absent(),
                Value<String?> catalog = const Value.absent(),
                Value<String?> train = const Value.absent(),
                Value<DateTime?> lastApiUpdate = const Value.absent(),
                Value<String?> screenshots = const Value.absent(),
                Value<String?> sources = const Value.absent(),
                Value<String?> appReadme = const Value.absent(),
                Value<String?> maintainersJson = const Value.absent(),
                Value<String?> upgradeInfoJson = const Value.absent(),
                Value<String?> usedPortsJson = const Value.absent(),
              }) => AppConfigsCompanion(
                id: id,
                serverId: serverId,
                appName: appName,
                displayName: displayName,
                iconUrl: iconUrl,
                isEnabled: isEnabled,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                description: description,
                installed: installed,
                healthy: healthy,
                healthyError: healthyError,
                version: version,
                appVersion: appVersion,
                humanVersion: humanVersion,
                categories: categories,
                home: home,
                tags: tags,
                recommended: recommended,
                catalog: catalog,
                train: train,
                lastApiUpdate: lastApiUpdate,
                screenshots: screenshots,
                sources: sources,
                appReadme: appReadme,
                maintainersJson: maintainersJson,
                upgradeInfoJson: upgradeInfoJson,
                usedPortsJson: usedPortsJson,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String appName,
                Value<String?> displayName = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool?> installed = const Value.absent(),
                Value<bool?> healthy = const Value.absent(),
                Value<String?> healthyError = const Value.absent(),
                Value<String?> version = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                Value<String?> humanVersion = const Value.absent(),
                Value<String?> categories = const Value.absent(),
                Value<String?> home = const Value.absent(),
                Value<String?> tags = const Value.absent(),
                Value<bool?> recommended = const Value.absent(),
                Value<String?> catalog = const Value.absent(),
                Value<String?> train = const Value.absent(),
                Value<DateTime?> lastApiUpdate = const Value.absent(),
                Value<String?> screenshots = const Value.absent(),
                Value<String?> sources = const Value.absent(),
                Value<String?> appReadme = const Value.absent(),
                Value<String?> maintainersJson = const Value.absent(),
                Value<String?> upgradeInfoJson = const Value.absent(),
                Value<String?> usedPortsJson = const Value.absent(),
              }) => AppConfigsCompanion.insert(
                id: id,
                serverId: serverId,
                appName: appName,
                displayName: displayName,
                iconUrl: iconUrl,
                isEnabled: isEnabled,
                isFavorite: isFavorite,
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                description: description,
                installed: installed,
                healthy: healthy,
                healthyError: healthyError,
                version: version,
                appVersion: appVersion,
                humanVersion: humanVersion,
                categories: categories,
                home: home,
                tags: tags,
                recommended: recommended,
                catalog: catalog,
                train: train,
                lastApiUpdate: lastApiUpdate,
                screenshots: screenshots,
                sources: sources,
                appReadme: appReadme,
                maintainersJson: maintainersJson,
                upgradeInfoJson: upgradeInfoJson,
                usedPortsJson: usedPortsJson,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppConfigsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({serverId = false, appPortConfigsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (appPortConfigsRefs) db.appPortConfigs,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (serverId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.serverId,
                                    referencedTable: $$AppConfigsTableReferences
                                        ._serverIdTable(db),
                                    referencedColumn:
                                        $$AppConfigsTableReferences
                                            ._serverIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (appPortConfigsRefs)
                        await $_getPrefetchedData<
                          AppConfigData,
                          $AppConfigsTable,
                          AppPortConfigData
                        >(
                          currentTable: table,
                          referencedTable: $$AppConfigsTableReferences
                              ._appPortConfigsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AppConfigsTableReferences(
                                db,
                                table,
                                p0,
                              ).appPortConfigsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.appConfigId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AppConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppConfigsTable,
      AppConfigData,
      $$AppConfigsTableFilterComposer,
      $$AppConfigsTableOrderingComposer,
      $$AppConfigsTableAnnotationComposer,
      $$AppConfigsTableCreateCompanionBuilder,
      $$AppConfigsTableUpdateCompanionBuilder,
      (AppConfigData, $$AppConfigsTableReferences),
      AppConfigData,
      PrefetchHooks Function({bool serverId, bool appPortConfigsRefs})
    >;
typedef $$AppPortConfigsTableCreateCompanionBuilder =
    AppPortConfigsCompanion Function({
      Value<int> id,
      required int appConfigId,
      required int portNumber,
      Value<String> protocol,
      Value<String?> serviceName,
      Value<String?> customUrl,
      Value<String?> apiUrl,
      Value<bool> isPrimary,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AppPortConfigsTableUpdateCompanionBuilder =
    AppPortConfigsCompanion Function({
      Value<int> id,
      Value<int> appConfigId,
      Value<int> portNumber,
      Value<String> protocol,
      Value<String?> serviceName,
      Value<String?> customUrl,
      Value<String?> apiUrl,
      Value<bool> isPrimary,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AppPortConfigsTableReferences
    extends
        BaseReferences<_$AppDatabase, $AppPortConfigsTable, AppPortConfigData> {
  $$AppPortConfigsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $AppConfigsTable _appConfigIdTable(_$AppDatabase db) => db.appConfigs
      .createAlias('app_port_configs__app_config_id__app_configs__id');

  $$AppConfigsTableProcessedTableManager get appConfigId {
    final $_column = $_itemColumn<int>('app_config_id')!;

    final manager = $$AppConfigsTableTableManager(
      $_db,
      $_db.appConfigs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_appConfigIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AppPortConfigsTableFilterComposer
    extends Composer<_$AppDatabase, $AppPortConfigsTable> {
  $$AppPortConfigsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get portNumber => $composableBuilder(
    column: $table.portNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customUrl => $composableBuilder(
    column: $table.customUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get apiUrl => $composableBuilder(
    column: $table.apiUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AppConfigsTableFilterComposer get appConfigId {
    final $$AppConfigsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appConfigId,
      referencedTable: $db.appConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppConfigsTableFilterComposer(
            $db: $db,
            $table: $db.appConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppPortConfigsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppPortConfigsTable> {
  $$AppPortConfigsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get portNumber => $composableBuilder(
    column: $table.portNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customUrl => $composableBuilder(
    column: $table.customUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get apiUrl => $composableBuilder(
    column: $table.apiUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AppConfigsTableOrderingComposer get appConfigId {
    final $$AppConfigsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appConfigId,
      referencedTable: $db.appConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppConfigsTableOrderingComposer(
            $db: $db,
            $table: $db.appConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppPortConfigsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppPortConfigsTable> {
  $$AppPortConfigsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get portNumber => $composableBuilder(
    column: $table.portNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get serviceName => $composableBuilder(
    column: $table.serviceName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customUrl =>
      $composableBuilder(column: $table.customUrl, builder: (column) => column);

  GeneratedColumn<String> get apiUrl =>
      $composableBuilder(column: $table.apiUrl, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AppConfigsTableAnnotationComposer get appConfigId {
    final $$AppConfigsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.appConfigId,
      referencedTable: $db.appConfigs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AppConfigsTableAnnotationComposer(
            $db: $db,
            $table: $db.appConfigs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AppPortConfigsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppPortConfigsTable,
          AppPortConfigData,
          $$AppPortConfigsTableFilterComposer,
          $$AppPortConfigsTableOrderingComposer,
          $$AppPortConfigsTableAnnotationComposer,
          $$AppPortConfigsTableCreateCompanionBuilder,
          $$AppPortConfigsTableUpdateCompanionBuilder,
          (AppPortConfigData, $$AppPortConfigsTableReferences),
          AppPortConfigData,
          PrefetchHooks Function({bool appConfigId})
        > {
  $$AppPortConfigsTableTableManager(
    _$AppDatabase db,
    $AppPortConfigsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppPortConfigsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppPortConfigsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppPortConfigsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> appConfigId = const Value.absent(),
                Value<int> portNumber = const Value.absent(),
                Value<String> protocol = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<String?> customUrl = const Value.absent(),
                Value<String?> apiUrl = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppPortConfigsCompanion(
                id: id,
                appConfigId: appConfigId,
                portNumber: portNumber,
                protocol: protocol,
                serviceName: serviceName,
                customUrl: customUrl,
                apiUrl: apiUrl,
                isPrimary: isPrimary,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int appConfigId,
                required int portNumber,
                Value<String> protocol = const Value.absent(),
                Value<String?> serviceName = const Value.absent(),
                Value<String?> customUrl = const Value.absent(),
                Value<String?> apiUrl = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppPortConfigsCompanion.insert(
                id: id,
                appConfigId: appConfigId,
                portNumber: portNumber,
                protocol: protocol,
                serviceName: serviceName,
                customUrl: customUrl,
                apiUrl: apiUrl,
                isPrimary: isPrimary,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AppPortConfigsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({appConfigId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (appConfigId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.appConfigId,
                                referencedTable: $$AppPortConfigsTableReferences
                                    ._appConfigIdTable(db),
                                referencedColumn:
                                    $$AppPortConfigsTableReferences
                                        ._appConfigIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AppPortConfigsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppPortConfigsTable,
      AppPortConfigData,
      $$AppPortConfigsTableFilterComposer,
      $$AppPortConfigsTableOrderingComposer,
      $$AppPortConfigsTableAnnotationComposer,
      $$AppPortConfigsTableCreateCompanionBuilder,
      $$AppPortConfigsTableUpdateCompanionBuilder,
      (AppPortConfigData, $$AppPortConfigsTableReferences),
      AppPortConfigData,
      PrefetchHooks Function({bool appConfigId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$NasServersTableTableManager get nasServers =>
      $$NasServersTableTableManager(_db, _db.nasServers);
  $$AppConfigsTableTableManager get appConfigs =>
      $$AppConfigsTableTableManager(_db, _db.appConfigs);
  $$AppPortConfigsTableTableManager get appPortConfigs =>
      $$AppPortConfigsTableTableManager(_db, _db.appPortConfigs);
}
