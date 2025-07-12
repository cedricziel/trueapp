import 'dart:convert';

/// Minimal server configuration for keychain storage
/// This contains just enough info to connect to a server
class KeychainServerConfig {
  final String id;
  final String name;
  final String host;
  final int? port;
  final bool useHttps;
  final bool allowUntrustedCertificates;
  final String username;
  final String password;

  const KeychainServerConfig({
    required this.id,
    required this.name,
    required this.host,
    this.port,
    required this.useHttps,
    required this.allowUntrustedCertificates,
    required this.username,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'host': host,
    'port': port,
    'useHttps': useHttps,
    'allowUntrustedCertificates': allowUntrustedCertificates,
    'username': username,
    'password': password,
  };

  factory KeychainServerConfig.fromJson(Map<String, dynamic> json) {
    return KeychainServerConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      host: json['host'] as String,
      port: json['port'] as int?,
      useHttps: json['useHttps'] as bool,
      allowUntrustedCertificates: json['allowUntrustedCertificates'] as bool,
      username: json['username'] as String,
      password: json['password'] as String,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory KeychainServerConfig.fromJsonString(String jsonString) {
    return KeychainServerConfig.fromJson(jsonDecode(jsonString));
  }
}
