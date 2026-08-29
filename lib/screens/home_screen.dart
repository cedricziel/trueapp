import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:truehub/providers/server_provider.dart';
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
  /// synchronously before `selectServer` is even called.
  ///
  /// `selectServer`'s authentication event reaches the listener below
  /// asynchronously, so without this guard it can react to the very tap
  /// that is about to navigate on its own once `selectServer` resolves,
  /// firing a redundant `go` that replaces the stack the tap is about to
  /// `push` onto. Setting this before the `await` closes that window: by
  /// the time the listener's callback runs, the flag is already in place.
  String? _selectingServerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      serverProvider.loadServersAndAutoSelect();
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
        child: Consumer<ServerProvider>(
          builder: (context, serverProvider, child) {
            if (serverProvider.servers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.desktopcomputer,
                      size: 64,
                      color: CupertinoColors.systemGrey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No servers added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap + to add your first TrueNAS server',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: serverProvider.servers.length,
              itemBuilder: (context, index) {
                final server = serverProvider.servers[index];
                return ServerListTile(
                  server: server,
                  onTap: () async {
                    // Select first, same as before #85 - this is what
                    // guarantees `serverProvider.selectedServer` already
                    // matches by the time `ServerDetailScreen` builds, so
                    // its own `initState` (which only selects when the
                    // selection doesn't already match) skips calling
                    // `selectServer` a second time. That matters here
                    // because Cupertino's page-transition machinery can
                    // transiently build more than one `ServerDetailScreen`
                    // for the same push, and two concurrent `selectServer`
                    // calls race each other.
                    //
                    // `_selectingServerId`, set synchronously first, stops
                    // the authentication-stream listener above from
                    // reacting to this same select with its own `go` (see
                    // its comment).
                    _selectingServerId = server.id;
                    await serverProvider.selectServer(server);
                    if (context.mounted) {
                      // push, not go: the detail screen (and its own
                      // forward navigations) needs a stack to pop back
                      // through, otherwise there is nothing left to return
                      // to the server list with (ticket #85).
                      context.push('/server/${server.id}', extra: server);
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
