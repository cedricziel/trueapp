import 'package:truehub/models/nas_server.dart';

/// Read access to the passwords stored for servers.
abstract interface class ServerCredentialsLookup {
  /// The stored password for [serverId], or `null` if none is stored.
  Future<String?> getPassword(String serverId);
}

/// Loads a server together with its stored password.
abstract interface class ServerCredentialsSource {
  /// The server and its password; either is `null` when it is not stored.
  Future<(NasServer?, String?)> getServerWithPassword(String serverId);
}
