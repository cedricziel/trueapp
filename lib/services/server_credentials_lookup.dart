/// Read access to the passwords stored for servers.
abstract interface class ServerCredentialsLookup {
  /// The stored password for [serverId], or `null` if none is stored.
  Future<String?> getPassword(String serverId);
}
