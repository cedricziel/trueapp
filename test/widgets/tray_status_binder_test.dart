import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/widgets/tray_status_binder.dart';

import '../helpers/fake_tray_status.dart';

NasServer _server(String id) => NasServer(
  id: id,
  name: id,
  host: '$id.local',
  username: 'root',
  password: '',
);

void main() {
  late FakeTraySink tray;
  late FakeTrayServerSource serverSource;
  late FakeTrayAppsSource appsSource;
  late FakeTrayConnectionSource connectionSource;
  late int showCalls;
  late int quitCalls;

  setUp(() {
    tray = FakeTraySink();
    serverSource = FakeTrayServerSource();
    appsSource = FakeTrayAppsSource();
    connectionSource = FakeTrayConnectionSource();
    showCalls = 0;
    quitCalls = 0;
  });

  Future<void> pumpBinder(WidgetTester tester, {bool isDesktop = true}) async {
    await tester.pumpWidget(
      TrayStatusBinder(
        isDesktop: isDesktop,
        tray: tray,
        serverSource: serverSource,
        appsSource: appsSource,
        connectionSource: connectionSource,
        onShowWindow: () => showCalls++,
        onQuitApp: () => quitCalls++,
        child: const SizedBox(),
      ),
    );
    await tester.pump();
  }

  testWidgets('wires callbacks and initializes the tray on desktop', (
    tester,
  ) async {
    await pumpBinder(tester);

    expect(tray.initializeCalls, 1);
    tray.onShowWindow!();
    tray.onQuitApp!();
    tray.onRefresh!();
    expect(showCalls, 1);
    expect(quitCalls, 1);
    expect(serverSource.refreshCalls, 1);
  });

  testWidgets('does nothing off desktop', (tester) async {
    await pumpBinder(tester, isDesktop: false);
    serverSource.change();
    appsSource.change();

    expect(tray.initializeCalls, 0);
    expect(tray.onShowWindow, isNull);
    expect(tray.updates, isEmpty);
  });

  testWidgets('pushes the current status once the tray is ready', (
    tester,
  ) async {
    serverSource.servers = [_server('a'), _server('b')];
    serverSource.healthError = 'boom';
    await pumpBinder(tester);

    expect(tray.updates.single.totalServers, 2);
    expect(tray.updates.single.alerts, ['boom']);
  });

  testWidgets('pushes status when servers change', (tester) async {
    serverSource.servers = [_server('a')];
    await pumpBinder(tester);

    serverSource.servers = [_server('a'), _server('b')];
    serverSource.change();

    expect(tray.updates, hasLength(2));
    expect(tray.updates.last.totalServers, 2);
  });

  testWidgets('skips the push when nothing shown in the tray changed', (
    tester,
  ) async {
    serverSource.servers = [_server('a')];
    connectionSource.connectedServers = ['a'];
    await pumpBinder(tester);

    connectionSource.change();
    serverSource.change();
    appsSource.change();

    expect(tray.updates, hasLength(1));
  });

  testWidgets('counts only servers with a live connection as connected', (
    tester,
  ) async {
    serverSource.servers = [_server('a'), _server('b'), _server('c')];
    connectionSource.connectedServers = ['b', 'removed'];
    await pumpBinder(tester);

    expect(tray.updates.single.totalServers, 3);
    expect(tray.updates.single.connectedServers, 1);
  });

  testWidgets('updates the count when a connection state changes', (
    tester,
  ) async {
    serverSource.servers = [_server('a'), _server('b')];
    await pumpBinder(tester);

    connectionSource.connectedServers = ['a', 'b'];
    connectionSource.change();

    expect(tray.updates.last.connectedServers, 2);
  });

  testWidgets('still pushes status when the apps lookup throws', (
    tester,
  ) async {
    appsSource.error = StateError('no apps');
    await pumpBinder(tester);

    expect(tray.updates.single.appsWithPortals, isEmpty);
  });

  testWidgets('stops listening once disposed', (tester) async {
    await pumpBinder(tester);
    await tester.pumpWidget(const SizedBox());

    serverSource.servers = [_server('a')];
    serverSource.change();
    appsSource.change();

    expect(tray.updates, hasLength(1));
  });
}
