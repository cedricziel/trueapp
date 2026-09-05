import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/fleet_server_status.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/widgets/server_list_tile.dart';
import '../helpers/test_database.dart';
import '../helpers/test_providers.dart';

void main() {
  late NasServer server;

  setUp(() {
    server = NasServer.create(
      name: 'vault.local',
      host: 'vault.local',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  });

  Future<Widget> wrap(Widget child) async {
    final database = createTestDatabase();
    final service = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    addTearDown(database.close);
    return ChangeNotifierProvider<ServerProvider>(
      create: (_) => ServerProvider(service),
      child: CupertinoApp(home: Center(child: child)),
    );
  }

  testWidgets('with no status, shows just the name and host', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await wrap(ServerListTile(server: server, onTap: () {})),
    );

    expect(find.text('vault.local'), findsWidgets);
    expect(find.text('Checking…'), findsNothing);
    expect(find.text('Offline'), findsNothing);
  });

  testWidgets('shows "Checking…" while connectivity is unknown or loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await wrap(
        ServerListTile(
          server: server,
          onTap: () {},
          status: const FleetServerStatus(
            serverId: 'x',
            connectivity: FleetServerConnectivity.loading,
          ),
        ),
      ),
    );

    expect(find.text('Checking…'), findsOneWidget);
  });

  testWidgets('shows "Offline" when the fleet check failed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await wrap(
        ServerListTile(
          server: server,
          onTap: () {},
          status: const FleetServerStatus(
            serverId: 'x',
            connectivity: FleetServerConnectivity.offline,
          ),
        ),
      ),
    );

    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('shows CPU/storage readouts and an alert icon when online', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await wrap(
        ServerListTile(
          server: server,
          onTap: () {},
          status: const FleetServerStatus(
            serverId: 'x',
            connectivity: FleetServerConnectivity.online,
            cpuUsage: 34,
            storageUsage: 78,
            activeAlertCount: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('CPU'), findsOneWidget);
    expect(find.textContaining('Storage'), findsOneWidget);
    expect(find.text('34%'), findsOneWidget);
    expect(find.text('78%'), findsOneWidget);
    expect(
      find.byIcon(CupertinoIcons.exclamationmark_triangle_fill),
      findsOneWidget,
    );
  });

  testWidgets('shows a dash instead of 0% for an unreported metric', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      await wrap(
        ServerListTile(
          server: server,
          onTap: () {},
          status: const FleetServerStatus(
            serverId: 'x',
            connectivity: FleetServerConnectivity.online,
            cpuUsage: null,
            storageUsage: 50,
          ),
        ),
      ),
    );

    expect(find.text('–'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('0%'), findsNothing);
  });
}
