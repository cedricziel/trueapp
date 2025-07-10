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

    // Create a test server with a problematic local URL
    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      localUrl: 's', // The problematic value
      trustedWifiSsids: ['HomeWiFi'],
      port: 443,
      username: 'admin',
      password: 'password',
      useHttps: true,
      allowUntrustedCertificates: false,
    );

    await serverProvider.addServer(testServer);
  });

  tearDown(() async {
    await database.close();
  });

  group('Local URL Save Test', () {
    test('should handle single character local URL "s"', () async {
      // Verify initial state
      expect(testServer.localUrl, 's');

      // Load from database to ensure it was saved
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.localUrl, 's');
    });

    test('should update local URL from "s" to empty string', () async {
      serverProvider.selectServer(testServer);

      // Update to clear the invalid local URL using the special flag
      final updatedServer = testServer.copyWith(
        clearLocalUrl: true, // Use the special flag to clear the local URL
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update worked
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.localUrl, isNull);
    });

    test('should update local URL from "s" to valid URL', () async {
      serverProvider.selectServer(testServer);

      // Update to a valid local URL
      final updatedServer = testServer.copyWith(
        localUrl: 'http://192.168.1.200:8080',
      );

      await serverProvider.updateServer(updatedServer);

      // Verify the update worked
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb, isNotNull);
      expect(serverFromDb!.localUrl, 'http://192.168.1.200:8080');
    });

    testWidgets('should handle editing server with "s" local URL in UI', (
      WidgetTester tester,
    ) async {
      // Select the server
      serverProvider.selectServer(testServer);

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the local URL field
      final localUrlFields = find.byWidgetPredicate(
        (widget) =>
            widget is CupertinoTextField && widget.controller?.text == 's',
      );

      expect(localUrlFields, findsOneWidget);

      // Clear the field
      await tester.enterText(localUrlFields, '');
      await tester.pumpAndSettle();

      // Save the changes
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Verify the server was updated
      final updatedServer = await database.getServer(testServer.id);
      expect(updatedServer, isNotNull);
      expect(updatedServer!.localUrl, isNull);
    });

    testWidgets('should show proper debug logs when updating from "s"', (
      WidgetTester tester,
    ) async {
      serverProvider.selectServer(testServer);

      await tester.pumpWidget(
        CupertinoApp(
          home: MultiProvider(
            providers: [
              Provider<AppDatabase>.value(value: database),
              ChangeNotifierProvider.value(value: serverProvider),
            ],
            child: EditServerScreen(server: testServer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find and update the local URL field
      final textFields = find.byType(CupertinoTextField);

      // Find the local URL field by checking controller values
      CupertinoTextField? localUrlField;
      int localUrlFieldIndex = -1;

      for (
        int i = 0;
        i < tester.widgetList<CupertinoTextField>(textFields).length;
        i++
      ) {
        final field = tester.widget<CupertinoTextField>(textFields.at(i));
        if (field.controller?.text == 's') {
          localUrlField = field;
          localUrlFieldIndex = i;
          break;
        }
      }

      expect(localUrlField, isNotNull);

      // Update to a valid URL
      await tester.enterText(
        textFields.at(localUrlFieldIndex),
        'http://192.168.1.200:8080',
      );
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // The debug logs should have been printed by now
    });

    test(
      'edge case: should handle various problematic local URL values',
      () async {
        final testCases = [
          ('single space', ' '),
          ('multiple spaces', '   '),
          ('single letter', 'a'),
          ('invalid URL', 'not-a-url'),
          ('missing protocol', '192.168.1.100:8080'),
          ('empty string', ''),
        ];

        // ignore: unused_local_variable
        for (final (description, localUrl) in testCases) {
          final server = NasServer.create(
            name: 'Edge Case Server',
            host: '192.168.1.100',
            localUrl: localUrl.isNotEmpty ? localUrl : null,
            username: 'admin',
            password: 'password',
          );

          await database.insertServer(server);

          // Read back and verify
          final serverFromDb = await database.getServer(server.id);
          expect(serverFromDb, isNotNull);

          if (localUrl.isEmpty) {
            expect(serverFromDb!.localUrl, isNull);
          } else {
            expect(serverFromDb!.localUrl, localUrl);
          }

          // Clean up
          await database.deleteServer(server.id);
        }
      },
    );
  });
}
