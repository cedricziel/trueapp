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
  late int showCalls;
  late int quitCalls;

  setUp(() {
    tray = FakeTraySink();
    serverSource = FakeTrayServerSource();
    appsSource = FakeTrayAppsSource();
    showCalls = 0;
    quitCalls = 0;
  });

  Future<void> pumpBinder(WidgetTester tester, {bool isDesktop = true}) {
    return tester.pumpWidget(
      TrayStatusBinder(
        isDesktop: isDesktop,
        tray: tray,
        serverSource: serverSource,
        appsSource: appsSource,
        onShowWindow: () => showCalls++,
        onQuitApp: () => quitCalls++,
        child: const SizedBox(),
      ),
    );
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

  testWidgets('pushes status when servers or apps change', (tester) async {
    serverSource.servers = [_server('a'), _server('b')];
    serverSource.healthError = 'boom';
    await pumpBinder(tester);

    serverSource.change();
    appsSource.change();

    expect(tray.updates, hasLength(2));
    expect(tray.updates.first.totalServers, 2);
    expect(tray.updates.first.alerts, ['boom']);
  });

  testWidgets('still pushes status when the apps lookup throws', (
    tester,
  ) async {
    appsSource.error = StateError('no apps');
    await pumpBinder(tester);

    serverSource.change();

    expect(tray.updates, hasLength(1));
    expect(tray.updates.single.appsWithPortals, isEmpty);
  });

  testWidgets('stops listening once disposed', (tester) async {
    await pumpBinder(tester);
    await tester.pumpWidget(const SizedBox());

    serverSource.change();
    appsSource.change();

    expect(tray.updates, isEmpty);
  });
}
