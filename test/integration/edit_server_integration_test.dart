import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/edit_server_screen.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);

    testServer = NasServer.create(
      name: 'Integration Test Server',
      host: '192.168.1.100',
      localUrl: 'http://192.168.1.200:8080',
      trustedWifiSsids: ['HomeWiFi'],
      port: 443,
      username: 'admin',
      password: 'password',
      useHttps: true,
      allowUntrustedCertificates: false,
    );

    await serverProvider.addServer(testServer);
    serverProvider.selectServer(testServer);
  });

  tearDown(() async {
    await database.close();
  });

  group('Edit Server Integration Tests', () {
    testWidgets('should complete full edit flow and refresh parent view', (
      WidgetTester tester,
    ) async {
      // Track navigation results
      bool? editResult;

      Widget createTestApp() {
        return CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Server Details'),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<ServerProvider>(
                      builder: (context, provider, child) {
                        final server = provider.selectedServer;
                        if (server == null) {
                          return const Text('No server selected');
                        }
                        return Column(
                          children: [
                            Text('Server: ${server.name}'),
                            Text('Host: ${server.host}'),
                            Text('HTTPS: ${server.useHttps}'),
                            Text(
                              'Allow Untrusted: ${server.allowUntrustedCertificates}',
                            ),
                            Text(
                              'WiFi SSIDs: ${server.trustedWifiSsids.join(', ')}',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) => CupertinoButton(
                        child: const Text('Edit Server'),
                        onPressed: () async {
                          editResult = await Navigator.of(context).push<bool>(
                            CupertinoPageRoute(
                              builder: (context) => EditServerScreen(
                                server: serverProvider.selectedServer!,
                              ),
                            ),
                          );

                          // Simulate the refresh logic from ServerDetailScreen
                          if (editResult == true && context.mounted) {
                            await context
                                .read<ServerProvider>()
                                .refreshSelectedServer();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Server: Integration Test Server'), findsOneWidget);
      expect(find.text('Host: 192.168.1.100'), findsOneWidget);
      expect(find.text('HTTPS: true'), findsOneWidget);
      expect(find.text('Allow Untrusted: false'), findsOneWidget);
      expect(find.text('WiFi SSIDs: HomeWiFi'), findsOneWidget);

      // Navigate to edit screen
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      // Make changes to the server

      // Update server name
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.enterText(nameField, 'Updated Integration Server');
      await tester.pumpAndSettle();

      // Toggle allow untrusted certificates
      final untrustedCertToggle = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoSwitch &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoFormRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text(
                                'Allow Untrusted Certificates',
                              ),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.tap(untrustedCertToggle);
      await tester.pumpAndSettle();

      // Add a new WiFi SSID
      final wifiSsidField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            widget.placeholder == 'Wi-Fi network name',
      );
      await tester.enterText(wifiSsidField, 'OfficeWiFi');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();

      // Update host
      final hostField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Host'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.enterText(hostField, '192.168.1.150');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify we're back to the main screen
      expect(find.text('Server Details'), findsOneWidget);

      // Verify the changes are reflected in the UI (showing refresh worked)
      expect(find.text('Server: Updated Integration Server'), findsOneWidget);
      expect(find.text('Host: 192.168.1.150'), findsOneWidget);
      expect(find.text('HTTPS: true'), findsOneWidget);
      expect(find.text('Allow Untrusted: true'), findsOneWidget);
      expect(find.text('WiFi SSIDs: HomeWiFi, OfficeWiFi'), findsOneWidget);

      // Verify edit result was true
      expect(editResult, isTrue);

      // Verify changes were persisted to database
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.name, 'Updated Integration Server');
      expect(updatedServer.host, '192.168.1.150');
      expect(updatedServer.allowUntrustedCertificates, isTrue);
      expect(updatedServer.trustedWifiSsids, contains('HomeWiFi'));
      expect(updatedServer.trustedWifiSsids, contains('OfficeWiFi'));
    });

    testWidgets('should handle edit cancellation without refreshing', (
      WidgetTester tester,
    ) async {
      bool? editResult;
      int refreshCount = 0;

      Widget createTestApp() {
        return CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Server Details'),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<ServerProvider>(
                      builder: (context, provider, child) {
                        final server = provider.selectedServer;
                        if (server == null) {
                          return const Text('No server selected');
                        }
                        return Text('Server: ${server.name}');
                      },
                    ),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) => CupertinoButton(
                        child: const Text('Edit Server'),
                        onPressed: () async {
                          editResult = await Navigator.of(context).push<bool>(
                            CupertinoPageRoute(
                              builder: (context) => EditServerScreen(
                                server: serverProvider.selectedServer!,
                              ),
                            ),
                          );

                          // Track refresh attempts
                          if (editResult == true && context.mounted) {
                            refreshCount++;
                            await context
                                .read<ServerProvider>()
                                .refreshSelectedServer();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Server: Integration Test Server'), findsOneWidget);

      // Navigate to edit screen
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      // Make changes but don't save
      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.enterText(nameField, 'This Change Should Not Be Saved');
      await tester.pumpAndSettle();

      // Cancel instead of saving
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify we're back to the main screen with original data
      expect(find.text('Server: Integration Test Server'), findsOneWidget);

      // Verify edit result was null (cancelled)
      expect(editResult, isNull);

      // Verify refresh was not called
      expect(refreshCount, 0);

      // Verify no changes were persisted to database
      final unchangedServer = await database.getServer(testServer.id);
      expect(unchangedServer, isNotNull);
      expect(unchangedServer!.name, 'Integration Test Server');
    });

    testWidgets('should handle multiple consecutive edits correctly', (
      WidgetTester tester,
    ) async {
      Widget createTestApp() {
        return CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: CupertinoPageScaffold(
              navigationBar: const CupertinoNavigationBar(
                middle: Text('Server Details'),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Consumer<ServerProvider>(
                      builder: (context, provider, child) {
                        final server = provider.selectedServer;
                        if (server == null) {
                          return const Text('No server selected');
                        }
                        return Column(
                          children: [
                            Text('Server: ${server.name}'),
                            Text('Port: ${server.port ?? 'default'}'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Builder(
                      builder: (context) => CupertinoButton(
                        child: const Text('Edit Server'),
                        onPressed: () async {
                          final result = await Navigator.of(context).push<bool>(
                            CupertinoPageRoute(
                              builder: (context) => EditServerScreen(
                                server: serverProvider.selectedServer!,
                              ),
                            ),
                          );

                          if (result == true && context.mounted) {
                            await context
                                .read<ServerProvider>()
                                .refreshSelectedServer();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // First edit: Change name
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      final nameField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Name'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.enterText(nameField, 'First Edit');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify first change
      expect(find.text('Server: First Edit'), findsOneWidget);

      // Second edit: Change port
      await tester.tap(find.text('Edit Server'));
      await tester.pumpAndSettle();

      final portField = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField &&
            find
                .ancestor(
                  of: find.byWidget(widget),
                  matching: find.byWidgetPredicate(
                    (parent) =>
                        parent is CupertinoTextFormFieldRow &&
                        find
                            .descendant(
                              of: find.byWidget(parent),
                              matching: find.text('Port'),
                            )
                            .evaluate()
                            .isNotEmpty,
                  ),
                )
                .evaluate()
                .isNotEmpty,
      );
      await tester.enterText(portField, '8080');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify second change and first change persisted
      expect(find.text('Server: First Edit'), findsOneWidget);
      expect(find.text('Port: 8080'), findsOneWidget);

      // Verify both changes are in database
      final finalServer = await database.getServer(testServer.id);
      expect(finalServer, isNotNull);
      expect(finalServer!.name, 'First Edit');
      expect(finalServer.port, 8080);
    });
  });
}
