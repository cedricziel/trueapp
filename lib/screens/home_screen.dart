import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/fleet_status_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/loading_state_widget.dart';
import 'package:truehub/widgets/server_list_tile.dart';
import 'package:truehub/widgets/session_indicator_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription? _authSubscription;

  /// The id of a server a list tap has just started selecting, set
  /// synchronously before `selectServer` is even called and cleared once
  /// that tap's own `push` has run.
  ///
  /// `selectServer`'s authentication event reaches the listener below
  /// asynchronously, so without this guard it can react to the very tap
  /// that is about to navigate on its own once `selectServer` resolves,
  /// firing a redundant `go` that replaces the stack the tap is about to
  /// `push` onto. Setting this before the `await` closes that window: by
  /// the time the listener's callback runs, the flag is already in place.
  ///
  /// It must be cleared once the tap's push has happened - it only needs to
  /// cover that one microtask-sized race, not the rest of the screen's
  /// lifetime. Left set, it would permanently and silently suppress
  /// single-server auto-navigation for that server id on every later
  /// reconnect, for as long as `HomeScreen` stays mounted underneath the
  /// pushed detail page.
  String? _selectingServerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final serverProvider = Provider.of<ServerProvider>(
        context,
        listen: false,
      );

      // Listen to authentication state changes
      _authSubscription = serverProvider.authenticationStream.listen((
        authStatus,
      ) {
        // Only auto-navigate to server detail if there's only one server
        // This maintains the expected behavior for single-server setups
        // while allowing multiple servers to be shown in the list
        // ModalRoute.isCurrent guards against clobbering a detail page the
        // user already pushed on top of this screen: HomeScreen stays
        // mounted (and subscribed) underneath it, so an auth stream event
        // firing while it is buried - e.g. a reconnect - must not `go` and
        // wipe out that pushed stack from below.
        if (mounted &&
            authStatus.isAuthenticated &&
            authStatus.server != null &&
            authStatus.server!.id != _selectingServerId &&
            serverProvider.servers.length == 1 &&
            (ModalRoute.of(context)?.isCurrent ?? false)) {
          context.go(
            '/server/${authStatus.server!.id}',
            extra: authStatus.server,
          );
        }
      });

      // Load servers but don't auto-select for multi-server scenarios
      await serverProvider.loadServersAndAutoSelect();

      // One-shot fleet health snapshot so servers needing attention sort
      // to the top - fire-and-forget, since a slow or unreachable server
      // must never hold up rendering the list itself.
      if (mounted) {
        unawaited(
          Provider.of<FleetStatusProvider>(
            context,
            listen: false,
          ).refreshAll(serverProvider.servers),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Servers'),
            const SizedBox(width: 8),
            const SessionIndicatorWidget(),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add),
          onPressed: () {
            // push, not go: AddServerScreen closes itself with Navigator.pop,
            // and `go` would replace the stack so there is nothing left to pop.
            context.push('/add-server');
          },
        ),
      ),
      child: SafeArea(
        child: Consumer2<ServerProvider, FleetStatusProvider>(
          builder: (context, serverProvider, fleetStatusProvider, child) {
            if (serverProvider.isLoadingServers) {
              return const LoadingStateWidget(message: 'Loading servers...');
            }

            if (serverProvider.servers.isEmpty) {
              return const EmptyStateWidget(
                icon: CupertinoIcons.desktopcomputer,
                title: 'No servers added yet',
                message: 'Tap + to add your first TrueNAS server',
              );
            }

            // Servers needing attention (offline, or with active alerts)
            // sort to the top - the relative order within each group is
            // otherwise left exactly as loaded/added.
            final needsAttention = <NasServer>[];
            final rest = <NasServer>[];
            for (final server in serverProvider.servers) {
              if (fleetStatusProvider.statusFor(server.id).needsAttention) {
                needsAttention.add(server);
              } else {
                rest.add(server);
              }
            }
            final sortedServers = [...needsAttention, ...rest];

            return Column(
              children: [
                _buildFleetBanner(needsAttention),
                Expanded(
                  child: ListView.builder(
                    itemCount: sortedServers.length,
                    itemBuilder: (context, index) {
                      final server = sortedServers[index];
                      return ServerListTile(
                        server: server,
                        status: fleetStatusProvider.statusFor(server.id),
                        onTap: () async {
                          // Select first, same as before #85 - this is what
                          // guarantees `serverProvider.selectedServer`
                          // already matches by the time `ServerDetailScreen`
                          // builds, so its own `initState` (which only
                          // selects when the selection doesn't already
                          // match) skips calling `selectServer` a second
                          // time. That matters here because Cupertino's
                          // page-transition machinery can transiently build
                          // more than one `ServerDetailScreen` for the same
                          // push, and two concurrent `selectServer` calls
                          // race each other.
                          //
                          // `_selectingServerId`, set synchronously first,
                          // stops the authentication-stream listener above
                          // from reacting to this same select with its own
                          // `go` (see its comment).
                          // A selection already in flight owns the
                          // navigation. `selectServer` is a real round trip,
                          // so a second tap lands long before the first
                          // resolves; letting it through would run two
                          // continuations that each `push`, stacking two
                          // identical detail routes the user has to pop
                          // twice for one tap.
                          if (_selectingServerId != null) {
                            return;
                          }
                          _selectingServerId = server.id;
                          var pushed = false;
                          try {
                            await serverProvider.selectServer(server);
                            if (context.mounted) {
                              // push, not go: the detail screen (and its
                              // own forward navigations) needs a stack to
                              // pop back through, otherwise there is
                              // nothing left to return to the server list
                              // with (ticket #85).
                              context.push(
                                '/server/${server.id}',
                                extra: server,
                              );
                              pushed = true;
                            }
                          } finally {
                            if (pushed) {
                              // One-shot: only the window up to and
                              // including this tap's own push needs
                              // guarding (see the field's doc comment) -
                              // clearing it synchronously right after
                              // `push` would reopen exactly the race it
                              // exists to close, since `push` inserts the
                              // new route before the widget tree (and
                              // therefore `ModalRoute.isCurrent`) reflects
                              // that; deferring the clear to a post-frame
                              // callback gives the pushed route a frame to
                              // actually land, so the `isCurrent` guard is
                              // reliably in place by the time the flag
                              // stops covering the race.
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _selectingServerId = null;
                              });
                            } else {
                              // No push happened - `selectServer` threw, or
                              // the tile left the tree mid-await. Clear
                              // immediately: there is no pushed route for
                              // the deferred clear to wait on, and a stuck
                              // flag would silently suppress single-server
                              // auto-navigation for this id for as long as
                              // HomeScreen stays mounted, as well as
                              // blocking every later tap by the guard
                              // above.
                              _selectingServerId = null;
                            }
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFleetBanner(List<NasServer> needsAttention) {
    if (needsAttention.isEmpty) return const SizedBox.shrink();

    final isSingle = needsAttention.length == 1;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle_fill,
            color: CupertinoColors.systemRed,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSingle
                  ? '${needsAttention.first.name} needs attention'
                  : '${needsAttention.length} servers need attention',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.systemRed,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
