import 'package:equatable/equatable.dart';

class UserInfo extends Equatable {
  final String username;
  final String fullName;
  final String homeDirectory;
  final String shell;
  final int uid;
  final int gid;
  final String source;
  final bool isLocal;
  final List<int> groupList;
  final Map<String, dynamic> attributes;
  final bool hasTwoFactor;
  final Map<String, dynamic> privilege;

  const UserInfo({
    required this.username,
    required this.fullName,
    required this.homeDirectory,
    required this.shell,
    required this.uid,
    required this.gid,
    required this.source,
    required this.isLocal,
    required this.groupList,
    required this.attributes,
    required this.hasTwoFactor,
    required this.privilege,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      username: json['pw_name'] as String? ?? '',
      fullName: json['pw_gecos'] as String? ?? '',
      homeDirectory: json['pw_dir'] as String? ?? '',
      shell: json['pw_shell'] as String? ?? '',
      uid: json['pw_uid'] as int? ?? 0,
      gid: json['pw_gid'] as int? ?? 0,
      source: json['source'] as String? ?? 'LOCAL',
      isLocal: json['local'] as bool? ?? true,
      groupList: (json['grouplist'] as List<dynamic>?)?.cast<int>() ?? [],
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
      hasTwoFactor: json['two_factor_config'] != null,
      privilege: json['privilege'] as Map<String, dynamic>? ?? {},
    );
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;

  bool get isAdministrator {
    // Check if user has administrative privileges
    return privilege['allowlist']?.contains('ADMIN') == true ||
        privilege['web_shell'] == true ||
        uid == 0; // root user
  }

  String get sourceDisplayName {
    switch (source.toUpperCase()) {
      case 'LOCAL':
        return 'Local Account';
      case 'ACTIVEDIRECTORY':
        return 'Active Directory';
      case 'LDAP':
        return 'LDAP';
      default:
        return source;
    }
  }

  @override
  List<Object?> get props => [
    username,
    fullName,
    homeDirectory,
    shell,
    uid,
    gid,
    source,
    isLocal,
    groupList,
    attributes,
    hasTwoFactor,
    privilege,
  ];
}
