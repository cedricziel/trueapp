import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/server_files_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late FileProvider fileProvider;
  late NasServer testServer;

  FileItem file(String name, {bool isDirectory = false}) {
    return FileItem(
      name: name,
      path: '/$name',
      isDirectory: isDirectory,
      size: 2048,
      modifiedTime: DateTime(2026, 1, 1),
      permissions: '644',
      owner: 'root',
      group: 'wheel',
    );
  }

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
    fileProvider = FileProvider(unifiedServerService);

    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );
  });

  tearDown(() async {
    await TestProviders.disposeTestStack(
      providers: [serverProvider, fileProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  Widget createTestApp() {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      fileProvider: fileProvider,
      child: CupertinoApp(home: ServerFilesScreen(server: testServer)),
    );
  }

  testWidgets('shows an empty state when the folder has no files', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    expectNoLayoutOverflow(tester);
    expect(find.text('Empty Folder'), findsOneWidget);
  });

  testWidgets('lists files and folders, folders sorted first', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    await tester.pumpWidget(createTestApp());
    // Let the screen's own initState (setApiClient + loadFiles, both
    // no-ops with no live server) settle before seeding test data -
    // setApiClient resets the file list, so seeding first would race it.
    await tester.pumpAndSettle();

    fileProvider.debugSetFiles([
      file('notes.txt'),
      file('movies', isDirectory: true),
      file('backups', isDirectory: true),
    ]);
    await tester.pump();

    expectNoLayoutOverflow(tester);
    expect(find.text('backups'), findsOneWidget);
    expect(find.text('movies'), findsOneWidget);
    expect(find.text('notes.txt'), findsOneWidget);

    final names = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Text),
          ),
        )
        .map((t) => t.data)
        .whereType<String>()
        .where((t) => ['backups', 'movies', 'notes.txt'].contains(t))
        .toList();
    expect(names, ['backups', 'movies', 'notes.txt']);
  });

  testWidgets('filters the list as the user types in the search field', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    fileProvider.debugSetFiles([
      file('Interstellar.mkv'),
      file('Documentary.mkv'),
    ]);
    await tester.pump();

    await tester.enterText(find.byType(CupertinoSearchTextField), 'doc');
    await tester.pump();

    expectNoLayoutOverflow(tester);
    expect(find.text('Documentary.mkv'), findsOneWidget);
    expect(find.text('Interstellar.mkv'), findsNothing);
  });

  testWidgets('shows a breadcrumb reflecting the current path', (
    WidgetTester tester,
  ) async {
    useCompactSurface(tester);
    await tester.pumpWidget(createTestApp());
    await tester.pumpAndSettle();

    fileProvider.debugSetFiles([file('movies', isDirectory: true)]);
    await tester.pump();

    expectNoLayoutOverflow(tester);
    expect(find.text('Home'), findsOneWidget);
  });
}
