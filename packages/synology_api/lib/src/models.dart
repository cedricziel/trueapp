import 'dsm_version.dart';

/// A logged-in DSM session.
final class SynologySession {
  const SynologySession({required this.sid, this.synoToken, this.deviceId});

  factory SynologySession.fromJson(Map<String, dynamic> json) =>
      SynologySession(
        sid: json['sid'] as String,
        synoToken: json['synotoken'] as String?,
        deviceId: json['did'] as String?,
      );

  final String sid;
  final String? synoToken;

  /// Trusted-device token; passing it to the next login skips the OTP step.
  final String? deviceId;
}

/// Hardware and firmware summary from `SYNO.DSM.Info`.
final class DsmInfo {
  const DsmInfo({
    required this.model,
    required this.versionString,
    this.serial,
    this.ramMegabytes,
    this.temperatureCelsius,
    this.uptime,
  });

  factory DsmInfo.fromJson(Map<String, dynamic> json) => DsmInfo(
    model: json['model'] as String? ?? '',
    versionString: json['version_string'] as String? ?? '',
    serial: json['serial'] as String?,
    ramMegabytes: json['ram'] as int?,
    temperatureCelsius: json['temperature'] as int?,
    uptime: switch (json['uptime']) {
      final int seconds => Duration(seconds: seconds),
      _ => null,
    },
  );

  final String model;

  /// As DSM reports it, e.g. `DSM 7.2.1-69057 Update 5`.
  final String versionString;
  final String? serial;
  final int? ramMegabytes;
  final int? temperatureCelsius;
  final Duration? uptime;

  DsmVersion? get version => DsmVersion.tryParse(versionString);
}
