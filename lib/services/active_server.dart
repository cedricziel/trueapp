import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';

/// The server whose screens are currently open.
///
/// `ServerRouteHost` sets it; per-server providers follow [listenable]
/// through `ActiveServerFollower`. It is deliberately not a [Listenable]
/// itself, so registering it with `Provider` never makes widgets rebuild
/// when a route changes it mid-build.
class ActiveServer {
  ActiveServer([NasServer? initial]) : _server = ValueNotifier(initial);

  final ValueNotifier<NasServer?> _server;

  /// The active server, or `null` before any server screen resolved one.
  NasServer? get value => _server.value;

  set value(NasServer? server) => _server.value = server;

  ValueListenable<NasServer?> get listenable => _server;

  void dispose() => _server.dispose();
}
