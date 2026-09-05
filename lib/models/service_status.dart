import 'package:equatable/equatable.dart';

/// Maps a TrueNAS internal service id (`service.query`'s `service` field)
/// to the name shown in the UI. Falls back to the upper-cased id for any
/// service not listed here rather than failing to render.
const Map<String, String> _serviceDisplayNames = {
  'cifs': 'SMB',
  'nfs': 'NFS',
  'ssh': 'SSH',
  'rsync': 'Rsync',
  'ftp': 'FTP',
  'snmp': 'SNMP',
  'smartd': 'S.M.A.R.T.',
  'ups': 'UPS',
  'iscsitarget': 'iSCSI',
  'webdav': 'WebDAV',
  'docker': 'Apps',
};

/// The running/enabled state of one TrueNAS service, as returned by
/// `service.query`.
class ServiceStatus extends Equatable {
  final String id;
  final bool isRunning;
  final bool isEnabled;

  const ServiceStatus({
    required this.id,
    required this.isRunning,
    required this.isEnabled,
  });

  String get displayName => _serviceDisplayNames[id] ?? id.toUpperCase();

  factory ServiceStatus.fromJson(Map<String, dynamic> json) {
    final rawState = json['state'] as String?;
    return ServiceStatus(
      id: json['service'] as String? ?? 'unknown',
      isRunning: rawState?.toUpperCase() == 'RUNNING',
      isEnabled: json['enable'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, isRunning, isEnabled];
}
