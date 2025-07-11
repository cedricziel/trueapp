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
    serverId,
    appName,
    displayName,
    iconUrl,
    isEnabled,
    createdAt,
    updatedAt,
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
  final DateTime createdAt;
  final DateTime updatedAt;
  const AppConfigData({
    required this.id,
    required this.serverId,
    required this.appName,
    this.displayName,
    this.iconUrl,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
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
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
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
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
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
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppConfigData copyWith({
    int? id,
    String? serverId,
    String? appName,
    Value<String?> displayName = const Value.absent(),
    Value<String?> iconUrl = const Value.absent(),
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AppConfigData(
    id: id ?? this.id,
    serverId: serverId ?? this.serverId,
    appName: appName ?? this.appName,
    displayName: displayName.present ? displayName.value : this.displayName,
    iconUrl: iconUrl.present ? iconUrl.value : this.iconUrl,
    isEnabled: isEnabled ?? this.isEnabled,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
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
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
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
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    serverId,
    appName,
    displayName,
    iconUrl,
    isEnabled,
    createdAt,
    updatedAt,
  );
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
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AppConfigsCompanion extends UpdateCompanion<AppConfigData> {
  final Value<int> id;
  final Value<String> serverId;
  final Value<String> appName;
  final Value<String?> displayName;
  final Value<String?> iconUrl;
  final Value<bool> isEnabled;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  const AppConfigsCompanion({
    this.id = const Value.absent(),
    this.serverId = const Value.absent(),
    this.appName = const Value.absent(),
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AppConfigsCompanion.insert({
    this.id = const Value.absent(),
    required String serverId,
    required String appName,
    this.displayName = const Value.absent(),
    this.iconUrl = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : serverId = Value(serverId),
       appName = Value(appName);
  static Insertable<AppConfigData> custom({
    Expression<int>? id,
    Expression<String>? serverId,
    Expression<String>? appName,
    Expression<String>? displayName,
    Expression<String>? iconUrl,
    Expression<bool>? isEnabled,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (serverId != null) 'server_id': serverId,
      if (appName != null) 'app_name': appName,
      if (displayName != null) 'display_name': displayName,
      if (iconUrl != null) 'icon_url': iconUrl,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AppConfigsCompanion copyWith({
    Value<int>? id,
    Value<String>? serverId,
    Value<String>? appName,
    Value<String?>? displayName,
    Value<String?>? iconUrl,
    Value<bool>? isEnabled,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
  }) {
    return AppConfigsCompanion(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      appName: appName ?? this.appName,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
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
    return (StringBuffer('AppConfigsCompanion(')
          ..write('id: $id, ')
          ..write('serverId: $serverId, ')
          ..write('appName: $appName, ')
          ..write('displayName: $displayName, ')
          ..write('iconUrl: $iconUrl, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
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
    aliasName: $_aliasNameGenerator(db.nasServers.id, db.appConfigs.serverId),
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
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });
typedef $$AppConfigsTableUpdateCompanionBuilder =
    AppConfigsCompanion Function({
      Value<int> id,
      Value<String> serverId,
      Value<String> appName,
      Value<String?> displayName,
      Value<String?> iconUrl,
      Value<bool> isEnabled,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
    });

final class $$AppConfigsTableReferences
    extends BaseReferences<_$AppDatabase, $AppConfigsTable, AppConfigData> {
  $$AppConfigsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NasServersTable _serverIdTable(_$AppDatabase db) =>
      db.nasServers.createAlias(
        $_aliasNameGenerator(db.appConfigs.serverId, db.nasServers.id),
      );

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
    aliasName: $_aliasNameGenerator(
      db.appConfigs.id,
      db.appPortConfigs.appConfigId,
    ),
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

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
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

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

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
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppConfigsCompanion(
                id: id,
                serverId: serverId,
                appName: appName,
                displayName: displayName,
                iconUrl: iconUrl,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String serverId,
                required String appName,
                Value<String?> displayName = const Value.absent(),
                Value<String?> iconUrl = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AppConfigsCompanion.insert(
                id: id,
                serverId: serverId,
                appName: appName,
                displayName: displayName,
                iconUrl: iconUrl,
                isEnabled: isEnabled,
                createdAt: createdAt,
                updatedAt: updatedAt,
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

  static $AppConfigsTable _appConfigIdTable(_$AppDatabase db) =>
      db.appConfigs.createAlias(
        $_aliasNameGenerator(db.appPortConfigs.appConfigId, db.appConfigs.id),
      );

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
