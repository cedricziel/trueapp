import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/services/server_lookup.dart';

/// The state of resolving a server id to a [NasServer], as reported by
/// [ServerRouteResolver.resolve].
sealed class ServerResolution {
  const ServerResolution();
}

/// Lookup is still in flight - nothing to show yet but a loading state.
class ServerResolving extends ServerResolution {
  const ServerResolving();
}

/// The server was found. Reported again whenever [server] changes (e.g. a
/// rename made on the edit screen), so a listener stays live without
/// re-subscribing.
class ServerResolved extends ServerResolution {
  const ServerResolved(this.server);

  final NasServer server;
}

/// No server with the requested id exists - either it was never
/// registered, or it has since been deleted.
class ServerUnknown extends ServerResolution {
  const ServerUnknown();
}

/// Resolves a `/server/:serverId` route's id to its current [NasServer],
/// reactively.
///
/// This exists so `app_router.dart`'s page builders never need to trust
/// `GoRouterState.extra` - which is only populated when navigation
/// originated inside the app - and so a cold start or deep link can resolve
/// the same way an in-app navigation does (see ticket #84).
abstract interface class ServerRouteResolver {
  /// A stream of resolution states for [serverId]: an initial
  /// [ServerResolving], then a [ServerResolved] or [ServerUnknown], updating
  /// live as the underlying server changes or is deleted.
  ///
  /// Pass [initialServer] when the caller already has a trustworthy, current
  /// copy of the server (e.g. carried in a route's `extra`) - resolution
  /// then seeds from it directly, skipping both the [ServerResolving] state
  /// and the lookup's own async fetch, and goes straight to watching
  /// [ServerLookup.serversStream] for live updates.
  Stream<ServerResolution> resolve(String serverId, {NasServer? initialServer});
}

/// A [ServerRouteResolver] backed by a [ServerLookup].
class LookupServerRouteResolver implements ServerRouteResolver {
  const LookupServerRouteResolver(this._lookup);

  final ServerLookup _lookup;

  @override
  Stream<ServerResolution> resolve(
    String serverId, {
    NasServer? initialServer,
  }) async* {
    NasServer? current;

    if (initialServer != null) {
      // Trust the caller's copy - skip the async fetch entirely. Beyond
      // being a redundant round trip, an unawaited real query left pending
      // when nothing drives it home (a widget test's `FakeAsync` zone will
      // never do so on its own) can stall every later query queued behind
      // it on the same connection - never leave one dangling when a valid
      // answer is already in hand.
      current = initialServer;
    } else {
      yield const ServerResolving();
      try {
        current = await _lookup.getServer(serverId);
      } catch (e) {
        if (kDebugMode) {
          // ignore: avoid_print
          print('LookupServerRouteResolver: getServer($serverId) failed: $e');
        }
        current = null;
      }
    }
    yield current == null ? const ServerUnknown() : ServerResolved(current);

    await for (final servers in _lookup.serversStream) {
      NasServer? match;
      for (final server in servers) {
        if (server.id == serverId) {
          match = server;
          break;
        }
      }
      yield match == null ? const ServerUnknown() : ServerResolved(match);
    }
  }
}
