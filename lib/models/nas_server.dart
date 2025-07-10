import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

class NasServer extends Equatable {
  final String id;
  final String name;
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useHttps;
  final DateTime? lastConnected;
  final bool isActive;

  const NasServer({
    required this.id,
    required this.name,
    required this.host,
    this.port = 80,
    required this.username,
    required this.password,
    this.useHttps = true,
    this.lastConnected,
    this.isActive = true,
  });

  factory NasServer.create({
    required String name,
    required String host,
    int port = 80,
    required String username,
    required String password,
    bool useHttps = true,
  }) {
    return NasServer(
      id: const Uuid().v4(),
      name: name,
      host: host,
      port: port,
      username: username,
      password: password,
      useHttps: useHttps,
    );
  }

  NasServer copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    String? password,
    bool? useHttps,
    DateTime? lastConnected,
    bool? isActive,
  }) {
    return NasServer(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      useHttps: useHttps ?? this.useHttps,
      lastConnected: lastConnected ?? this.lastConnected,
      isActive: isActive ?? this.isActive,
    );
  }

  String get baseUrl => '${useHttps ? 'https' : 'http'}://$host:$port';

  @override
  List<Object?> get props => [
        id,
        name,
        host,
        port,
        username,
        password,
        useHttps,
        lastConnected,
        isActive,
      ];
}