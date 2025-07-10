// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'truenas_rpc_interface.dart';

// **************************************************************************
// JsonRpcGenerator
// **************************************************************************

// ignore_for_file: type=lint, unused_element

mixin TrueNasRpcInterfaceClientMixin on ClientBase {
  Future<bool> login(
    String username,
    String password, [
    String? otpToken,
  ]) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'login',
      <dynamic>[
        username,
        password,
        if (otpToken != null) otpToken,
      ],
    );
    return ($result as bool);
  }

  Future<Map<String, dynamic>> getSystemInfo() async {
    final dynamic $result = await jsonRpcInstance.sendRequest('getSystemInfo');
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<Map<String, dynamic>> getSystemCpuInfo() async {
    final dynamic $result =
        await jsonRpcInstance.sendRequest('getSystemCpuInfo');
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<Map<String, dynamic>> getSystemMemoryInfo() async {
    final dynamic $result =
        await jsonRpcInstance.sendRequest('getSystemMemoryInfo');
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<double> getSystemTemperature() async {
    final dynamic $result =
        await jsonRpcInstance.sendRequest('getSystemTemperature');
    return ($result as double);
  }

  Future<List<Map<String, dynamic>>> queryPools() async {
    final dynamic $result = await jsonRpcInstance.sendRequest('queryPools');
    return ($result as List)
        .map((dynamic $e) => ($e as Map).map((
              dynamic $k,
              dynamic $v,
            ) =>
                MapEntry(
                  ($k as String),
                  $v,
                )))
        .toList();
  }

  Future<Map<String, dynamic>> getPoolById(String id) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'getPoolById',
      <dynamic>[id],
    );
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<List<Map<String, dynamic>>> queryDatasets() async {
    final dynamic $result = await jsonRpcInstance.sendRequest('queryDatasets');
    return ($result as List)
        .map((dynamic $e) => ($e as Map).map((
              dynamic $k,
              dynamic $v,
            ) =>
                MapEntry(
                  ($k as String),
                  $v,
                )))
        .toList();
  }

  Future<Map<String, dynamic>> getDatasetById(String id) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'getDatasetById',
      <dynamic>[id],
    );
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<List<Map<String, dynamic>>> listDirectory(String path) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'listDirectory',
      <dynamic>[path],
    );
    return ($result as List)
        .map((dynamic $e) => ($e as Map).map((
              dynamic $k,
              dynamic $v,
            ) =>
                MapEntry(
                  ($k as String),
                  $v,
                )))
        .toList();
  }

  Future<Map<String, dynamic>> getFileInfo(String path) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'getFileInfo',
      <dynamic>[path],
    );
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<List<Map<String, dynamic>>> queryDisks() async {
    final dynamic $result = await jsonRpcInstance.sendRequest('queryDisks');
    return ($result as List)
        .map((dynamic $e) => ($e as Map).map((
              dynamic $k,
              dynamic $v,
            ) =>
                MapEntry(
                  ($k as String),
                  $v,
                )))
        .toList();
  }

  Future<Map<String, dynamic>> getDiskById(String id) async {
    final dynamic $result = await jsonRpcInstance.sendRequest(
      'getDiskById',
      <dynamic>[id],
    );
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    final dynamic $result = await jsonRpcInstance.sendRequest('getNetworkInfo');
    return ($result as Map).map((
      dynamic $k,
      dynamic $v,
    ) =>
        MapEntry(
          ($k as String),
          $v,
        ));
  }

  Future<List<Map<String, dynamic>>> getNetworkInterfaces() async {
    final dynamic $result =
        await jsonRpcInstance.sendRequest('getNetworkInterfaces');
    return ($result as List)
        .map((dynamic $e) => ($e as Map).map((
              dynamic $k,
              dynamic $v,
            ) =>
                MapEntry(
                  ($k as String),
                  $v,
                )))
        .toList();
  }
}
mixin TrueNasRpcInterfaceServerMixin on ServerBase {
  @protected
  FutureOr<bool> login(
    String username,
    String password,
    String? otpToken,
  );
  @protected
  FutureOr<Map<String, dynamic>> getSystemInfo();
  @protected
  FutureOr<Map<String, dynamic>> getSystemCpuInfo();
  @protected
  FutureOr<Map<String, dynamic>> getSystemMemoryInfo();
  @protected
  FutureOr<double> getSystemTemperature();
  @protected
  FutureOr<List<Map<String, dynamic>>> queryPools();
  @protected
  FutureOr<Map<String, dynamic>> getPoolById(String id);
  @protected
  FutureOr<List<Map<String, dynamic>>> queryDatasets();
  @protected
  FutureOr<Map<String, dynamic>> getDatasetById(String id);
  @protected
  FutureOr<List<Map<String, dynamic>>> listDirectory(String path);
  @protected
  FutureOr<Map<String, dynamic>> getFileInfo(String path);
  @protected
  FutureOr<List<Map<String, dynamic>>> queryDisks();
  @protected
  FutureOr<Map<String, dynamic>> getDiskById(String id);
  @protected
  FutureOr<Map<String, dynamic>> getNetworkInfo();
  @protected
  FutureOr<List<Map<String, dynamic>>> getNetworkInterfaces();
  @override
  @visibleForOverriding
  @mustCallSuper
  void registerMethods() {
    super.registerMethods();
    jsonRpcInstance.registerMethod(
      'login',
      (Parameters $params) async {
        final $$username = $params[0].asString;
        final $$password = $params[1].asString;
        final $$otpToken = $params[2].$maybeNullOr(($v) => $v.asString);
        return (await login(
          $$username,
          $$password,
          $$otpToken,
        ));
      },
    );
    jsonRpcInstance.registerMethod(
      'getSystemInfo',
      () async {
        return (await getSystemInfo());
      },
    );
    jsonRpcInstance.registerMethod(
      'getSystemCpuInfo',
      () async {
        return (await getSystemCpuInfo());
      },
    );
    jsonRpcInstance.registerMethod(
      'getSystemMemoryInfo',
      () async {
        return (await getSystemMemoryInfo());
      },
    );
    jsonRpcInstance.registerMethod(
      'getSystemTemperature',
      () async {
        return (await getSystemTemperature());
      },
    );
    jsonRpcInstance.registerMethod(
      'queryPools',
      () async {
        return (await queryPools());
      },
    );
    jsonRpcInstance.registerMethod(
      'getPoolById',
      (Parameters $params) async {
        final $$id = $params[0].asString;
        return (await getPoolById($$id));
      },
    );
    jsonRpcInstance.registerMethod(
      'queryDatasets',
      () async {
        return (await queryDatasets());
      },
    );
    jsonRpcInstance.registerMethod(
      'getDatasetById',
      (Parameters $params) async {
        final $$id = $params[0].asString;
        return (await getDatasetById($$id));
      },
    );
    jsonRpcInstance.registerMethod(
      'listDirectory',
      (Parameters $params) async {
        final $$path = $params[0].asString;
        return (await listDirectory($$path));
      },
    );
    jsonRpcInstance.registerMethod(
      'getFileInfo',
      (Parameters $params) async {
        final $$path = $params[0].asString;
        return (await getFileInfo($$path));
      },
    );
    jsonRpcInstance.registerMethod(
      'queryDisks',
      () async {
        return (await queryDisks());
      },
    );
    jsonRpcInstance.registerMethod(
      'getDiskById',
      (Parameters $params) async {
        final $$id = $params[0].asString;
        return (await getDiskById($$id));
      },
    );
    jsonRpcInstance.registerMethod(
      'getNetworkInfo',
      () async {
        return (await getNetworkInfo());
      },
    );
    jsonRpcInstance.registerMethod(
      'getNetworkInterfaces',
      () async {
        return (await getNetworkInterfaces());
      },
    );
  }
}

class TrueNasRpcInterfaceClient extends ClientBase
    with TrueNasRpcInterfaceClientMixin {
  TrueNasRpcInterfaceClient(super.channel) : super();

  TrueNasRpcInterfaceClient.withoutJson(super.channel) : super.withoutJson();

  TrueNasRpcInterfaceClient.fromClient(super.jsonRpcInstance)
      : super.fromClient();
}

abstract class TrueNasRpcInterfaceServer extends ServerBase
    with TrueNasRpcInterfaceServerMixin {
  TrueNasRpcInterfaceServer(
    super.channel, {
    super.onUnhandledError,
    super.strictProtocolChecks,
  }) : super();

  TrueNasRpcInterfaceServer.withoutJson(
    super.channel, {
    super.onUnhandledError,
    super.strictProtocolChecks,
  }) : super.withoutJson();

  TrueNasRpcInterfaceServer.fromServer(super.jsonRpcInstance)
      : super.fromServer();
}

@pragma('vm:prefer-inline')
TConverted _$map<TConverted extends Object, TJson extends Object>(
  TJson $value,
  TConverted Function(TJson) $convert,
) =>
    $convert($value);
@pragma('vm:prefer-inline')
TConverted? _$maybeMap<TConverted extends Object, TJson extends Object>(
  TJson? $value,
  TConverted Function(TJson) $convert,
) =>
    $value == null ? null : $convert($value);

extension _$JsonRpc2ParameterExtensions on Parameter {
  @pragma('vm:prefer-inline')
  T $maybeOr<T>(
    T Function(Parameter) getter,
    T defaultValue,
  ) =>
      exists ? getter(this) : defaultValue;
  @pragma('vm:prefer-inline')
  T? $nullOr<T>(T Function(Parameter) getter) =>
      value != null ? getter(this) : null;
  @pragma('vm:prefer-inline')
  T? $maybeNullOr<T>(T Function(Parameter) getter) =>
      exists && value != null ? getter(this) : null;
}
