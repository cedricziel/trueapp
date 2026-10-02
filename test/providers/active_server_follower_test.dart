import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/active_server_follower.dart';
import 'package:truehub/services/active_server.dart';

class _RecordingProvider extends ChangeNotifier with ActiveServerFollower {
  final List<String> switchedTo = [];
  Completer<void>? gate;

  @override
  Future<void> setServer(NasServer server) async {
    switchedTo.add(server.id);
    await gate?.future;
  }
}

NasServer _server(String id, {String name = 'Server'}) => NasServer(
  id: id,
  name: name,
  host: '$id.example.com',
  username: 'admin',
  password: '',
  isDefault: false,
  trustedWifiSsids: const [],
);

void main() {
  test('switches to the server that is already active', () async {
    final provider = _RecordingProvider()
      ..followActiveServer(ActiveServer(_server('a')).listenable);
    await provider.pendingServerSwitch;

    expect(provider.switchedTo, ['a']);
  });

  test('switches when the active server id changes', () async {
    final active = ActiveServer();
    final provider = _RecordingProvider()
      ..followActiveServer(active.listenable);

    active.value = _server('a');
    active.value = _server('b');
    await provider.pendingServerSwitch;

    expect(provider.switchedTo, ['a', 'b']);
  });

  test('ignores edits that keep the same server id', () async {
    final active = ActiveServer(_server('a'));
    final provider = _RecordingProvider()
      ..followActiveServer(active.listenable);

    active.value = _server('a', name: 'Renamed');
    await provider.pendingServerSwitch;

    expect(provider.switchedTo, ['a']);
  });

  test('exposes the in-flight switch until it completes', () async {
    final provider = _RecordingProvider()..gate = Completer<void>();
    provider.followActiveServer(ActiveServer(_server('a')).listenable);

    final pending = provider.pendingServerSwitch;
    expect(pending, isNotNull);
    expect(
      provider.switchedTo,
      isEmpty,
      reason: 'the switch must wait until the current build is over',
    );

    await Future<void>.delayed(Duration.zero);
    expect(provider.switchedTo, ['a']);
    provider.gate!.complete();
    await pending;

    expect(provider.pendingServerSwitch, isNull);
  });

  test('stops following after dispose', () async {
    final active = ActiveServer();
    final provider = _RecordingProvider()
      ..followActiveServer(active.listenable);

    provider.dispose();
    active.value = _server('a');
    await Future<void>.delayed(Duration.zero);

    expect(provider.switchedTo, isEmpty);
  });

  test('a null source leaves the provider alone', () {
    final provider = _RecordingProvider()..followActiveServer(null);

    expect(provider.switchedTo, isEmpty);
    expect(provider.pendingServerSwitch, isNull);
  });
}
