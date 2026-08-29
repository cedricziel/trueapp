import 'package:truehub/models/nas_server.dart';

/// Minimal read interface for resolving a server's current state by id.
///
/// [UnifiedServerService] implements this. Navigation code (see
/// `lib/navigation/server_route_resolver.dart`) depends on this narrower
/// interface rather than the concrete service, per this project's
/// code-against-interfaces convention - it only ever needs to look a server
/// up and watch for changes, never save credentials or manage repositories.
abstract interface class ServerLookup {
  /// Looks up the server with [id], or `null` if none is registered.
  Future<NasServer?> getServer(String id);

  /// Emits the full current server list whenever it changes.
  ///
  /// Implementations are not required to replay the latest value to a late
  /// subscriber - callers that need a server's current state immediately
  /// must call [getServer] first.
  Stream<List<NasServer>> get serversStream;
}
