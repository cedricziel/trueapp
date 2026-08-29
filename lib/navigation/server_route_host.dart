import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/navigation/server_route_resolver.dart';
import 'package:truehub/navigation/shell_navigation_leading.dart';
import 'package:truehub/services/unified_server_service.dart';

/// Resolves a `/server/:serverId` route's id to its [NasServer] and hands it
/// to [builder], instead of every page builder in `app_router.dart` trusting
/// `GoRouterState.extra` - which is only populated when navigation
/// originated inside the app, so a cold start or deep link on that location
/// used to throw a `_TypeError` before the screen ever built (ticket #84).
///
/// [cachedServer] is a pure optimisation: when it is supplied and its id
/// matches [serverId], it is shown immediately - no loading state, no
/// waiting on the resolver - exactly reproducing today's in-app navigation
/// experience. It is never required for correctness; id-based resolution
/// backs every route regardless; and it stops mattering the moment the
/// resolver's stream reports a real value, letting a rename or deletion
/// still flow through.
///
/// The route is redirected to `/servers` if the id turns out to be unknown
/// (never registered, or deleted while this screen was open).
class ServerRouteHost extends StatefulWidget {
  const ServerRouteHost({
    super.key,
    required this.serverId,
    required this.builder,
    this.cachedServer,
  });

  /// The `serverId` path parameter of the route being hosted.
  final String serverId;

  /// A server carried in `GoRouterState.extra` by an in-app navigation, used
  /// to render an initial frame with no loading state while resolution
  /// happens. Ignored if its id does not match [serverId].
  final NasServer? cachedServer;

  /// Builds the routed screen once [serverId] has resolved to a server.
  final Widget Function(BuildContext context, NasServer server) builder;

  @override
  State<ServerRouteHost> createState() => _ServerRouteHostState();
}

class _ServerRouteHostState extends State<ServerRouteHost> {
  StreamSubscription<ServerResolution>? _subscription;
  NasServer? _resolved;
  bool _redirected = false;

  @override
  void initState() {
    super.initState();
    _resolved = _matchingCachedServer();
    _listen();
  }

  @override
  void didUpdateWidget(covariant ServerRouteHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.serverId != widget.serverId) {
      _subscription?.cancel();
      _redirected = false;
      setState(() {
        _resolved = _matchingCachedServer();
      });
      _listen();
    }
  }

  NasServer? _matchingCachedServer() {
    final cached = widget.cachedServer;
    return (cached != null && cached.id == widget.serverId) ? cached : null;
  }

  void _listen() {
    final resolver = LookupServerRouteResolver(
      context.read<UnifiedServerService>(),
    );
    _subscription = resolver
        .resolve(widget.serverId, initialServer: _matchingCachedServer())
        .listen((resolution) {
          if (!mounted) return;
          switch (resolution) {
            case ServerResolving():
              break;
            case ServerResolved(:final server):
              setState(() {
                _resolved = server;
              });
            case ServerUnknown():
              setState(() {
                _resolved = null;
              });
              _redirectToServerListOnceSettled();
          }
        });
  }

  void _redirectToServerListOnceSettled() {
    if (_redirected) return;
    _redirected = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GoRouter.of(context).go('/servers');
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final server = _resolved;
    if (server != null) {
      return widget.builder(context, server);
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: ShellNavigationLeading.maybeBuild(context),
        middle: const Text('Loading'),
      ),
      child: const Center(child: CupertinoActivityIndicator()),
    );
  }
}
