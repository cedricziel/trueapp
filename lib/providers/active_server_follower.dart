import 'package:flutter/foundation.dart';
import 'package:truehub/models/nas_server.dart';

/// Switches a provider to whichever server an [ActiveServer]-style
/// listenable reports, so screens never have to hand the server over
/// themselves.
///
/// Only a change of server id triggers a switch: a rename or an edit of the
/// same server keeps the provider's state.
mixin ActiveServerFollower on ChangeNotifier {
  ValueListenable<NasServer?>? _activeServer;
  String? _followedServerId;
  Future<void>? _pendingSwitch;

  /// Points the provider at [server], dropping state from the previous one.
  Future<void> setServer(NasServer server);

  /// The switch to the active server that is still in progress, or `null`
  /// when there is none. Load methods await it before using their client.
  Future<void>? get pendingServerSwitch => _pendingSwitch;

  /// Starts following [source]. A `null` source leaves the provider to be
  /// driven by direct [setServer] calls.
  void followActiveServer(ValueListenable<NasServer?>? source) {
    _activeServer = source;
    source?.addListener(_onActiveServerChanged);
    _onActiveServerChanged();
  }

  void _onActiveServerChanged() {
    final server = _activeServer?.value;
    if (server == null || server.id == _followedServerId) return;
    _followedServerId = server.id;

    // The active server changes while routes build, so the switch, which
    // may notify listeners, runs right after the current build instead.
    late final Future<void> pending;
    pending = Future.microtask(() => setServer(server)).whenComplete(() {
      if (identical(_pendingSwitch, pending)) _pendingSwitch = null;
    });
    _pendingSwitch = pending;
  }

  @override
  void dispose() {
    _activeServer?.removeListener(_onActiveServerChanged);
    super.dispose();
  }
}
