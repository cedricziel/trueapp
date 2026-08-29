import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/screens/app_configuration_screen.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/pump_helpers.dart';
import '../helpers/provider_scope.dart';
import '../helpers/test_providers.dart';
import '../helpers/test_surfaces.dart';

/// Coverage for [AppConfigurationScreen] - the port/URL/display-name editor
/// pushed from an installed app's card. The screen edits an in-memory
/// `AppConfig` copy locally (every field change is a `setState`) and only
/// writes through `AppProvider.updateAppConfig` - a real `database
/// .updateFullAppConfig` call - when the navigation bar's Save button is
/// tapped, after which it pops itself.
///
/// `AppDatabase.updateFullAppConfig` requires a non-null `AppConfig.id`, so
/// every fixture here is round-tripped through `insertFullAppConfig` +
/// `getFullAppConfig` first, the same way the real app would only ever open
/// this screen on an already-persisted config.
void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late UnifiedServerService unifiedServerService;
  late AppProvider appProvider;
  late NasServer testServer;

  // url_launcher has no platform implementation under the `flutter test` VM,
  // and unlike AppCardWidget's equivalent tap handler, `_openUrl` in this
  // screen does not catch the resulting MissingPluginException. A mock
  // channel handler keeps the "link" button's tap safe to exercise.
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

  setUp(() async {
    await TestProviders.cleanupTestEnvironment();
    TestProviders.setupTestEnvironment();
    database = AppDatabase.forTesting(NativeDatabase.memory());
    unifiedServerService = await TestProviders.createMockUnifiedServerService(
      database: database,
    );
    serverProvider = ServerProvider(unifiedServerService);
    appProvider = AppProvider(
      database: database,
      serverService: unifiedServerService,
    );

    // `app_configs.server_id` carries a foreign key to `servers`, so a
    // config can only be inserted against a server that really exists.
    testServer = NasServer.create(
      name: 'Test Server',
      host: '192.168.1.100',
      port: 443,
      username: 'admin',
      password: 'password',
    );
    await serverProvider.addServer(testServer, 'password');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          if (call.method == 'canLaunch') return false;
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
    await TestProviders.disposeTestStack(
      providers: [serverProvider, appProvider],
      service: unifiedServerService,
      database: database,
    );
  });

  /// Inserts an [AppConfig] and reads it back so the returned copy carries
  /// real database ids for itself and every port - required for
  /// `updateFullAppConfig` and for `_updatePort`/`_deletePort`, which match
  /// ports by `id`.
  Future<AppConfig> seedConfig({
    String appName = 'plex',
    String? displayName,
    bool isEnabled = true,
    List<AppPortConfig> ports = const [],
  }) async {
    final config = AppConfig(
      serverId: testServer.id,
      appName: appName,
      displayName: displayName,
      isEnabled: isEnabled,
      ports: ports,
    );
    await database.insertFullAppConfig(config);
    final loaded = await database.getFullAppConfig(testServer.id, appName);
    return loaded!;
  }

  /// Hosts the screen behind a button push, the way it is reached in the
  /// real app, so `Navigator.of(context).pop()` inside `_saveConfiguration`
  /// has somewhere to pop to. [onClosed] fires once the pushed route's
  /// `Future` completes (i.e. once it has popped).
  Widget buildHost(AppConfig config, {VoidCallback? onClosed}) {
    return provideAppProviders(
      database: database,
      service: unifiedServerService,
      serverProvider: serverProvider,
      appProvider: appProvider,
      child: CupertinoApp(
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  await Navigator.of(context).push<void>(
                    CupertinoPageRoute<void>(
                      builder: (_) => AppConfigurationScreen(appConfig: config),
                    ),
                  );
                  onClosed?.call();
                },
                child: const Text('Open Configuration'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Pumps [buildHost], pushes the screen and returns a notifier that flips
  /// to `true` once the screen has popped (i.e. once Save or an equivalent
  /// finished).
  Future<ValueNotifier<bool>> openConfigScreen(
    WidgetTester tester,
    AppConfig config,
  ) async {
    final closed = ValueNotifier<bool>(false);
    await tester.pumpWidget(
      buildHost(config, onClosed: () => closed.value = true),
    );
    await tester.pump();
    await tester.tap(find.text('Open Configuration'));
    await settleRouteTransition(tester);
    return closed;
  }

  // The modal's title text ("Add Port"/"Edit Port") also appears verbatim
  // elsewhere (the main screen's "Add Port" button), so the modal has to be
  // identified by its *navigation bar* carrying that title, not just any
  // ancestor of the text.
  Finder modalScaffoldWithTitle(String title) => find.ancestor(
    of: find.descendant(
      of: find.byType(CupertinoNavigationBar),
      matching: find.text(title),
    ),
    matching: find.byType(CupertinoPageScaffold),
  );

  // Both this screen's rows and its port-edit modal label every input with
  // `CupertinoFormRow(prefix: Text(label), child: ...)` - the label is a
  // *sibling* of the field, not an ancestor of it, so a plain
  // ancestor-of-the-field lookup (as `form_finders.dart` assumes for a
  // `CupertinoTextFormFieldRow(prefix: ...)`) cannot find it. Resolve the
  // shared row first, then look for the field/switch inside it instead.
  Finder formRowFor(String label) => find.ancestor(
    of: find.text(label),
    matching: find.byType(CupertinoFormRow),
  );

  Finder switchForLabel(String label, {Finder? scope}) {
    final row = scope == null
        ? formRowFor(label)
        : find.descendant(of: scope, matching: formRowFor(label));
    return find.descendant(of: row, matching: find.byType(CupertinoSwitch));
  }

  Finder fieldForLabel(String label, {Finder? scope}) {
    final row = scope == null
        ? formRowFor(label)
        : find.descendant(of: scope, matching: formRowFor(label));
    return find.descendant(of: row, matching: find.byType(EditableText));
  }

  Finder buttonWithText(String text, {Finder? scope}) {
    final base = find.widgetWithText(CupertinoButton, text);
    return scope == null ? base : find.descendant(of: scope, matching: base);
  }

  /// The single port row's `Row` ancestor for the row whose service name is
  /// [label] - the scope every pencil/link tap has to be resolved within,
  /// since every row repeats the same two icon buttons.
  Finder portRowFor(String label) =>
      find.ancestor(of: find.text(label), matching: find.byType(Row)).first;

  /// A `Text` widget showing [value] verbatim - unlike `find.text`, this
  /// deliberately does NOT also match an `EditableText` whose controller
  /// happens to hold the same string, which happens throughout this screen
  /// whenever a URL just typed into a field is simultaneously mirrored by a
  /// port row below it.
  Finder staticText(String value) => find.byWidgetPredicate(
    (widget) => widget is Text && widget.data == value,
  );

  group('rendering', () {
    testWidgets('shows app info and existing ports', (tester) async {
      const webPort = AppPortConfig(
        portNumber: 32400,
        protocol: 'http',
        serviceName: 'Web UI',
        isPrimary: true,
        isEnabled: true,
      );
      const adminPort = AppPortConfig(
        portNumber: 32401,
        protocol: 'https',
        serviceName: 'Admin',
        isEnabled: true,
      );
      final config = await runRealAsync(
        tester,
        () => seedConfig(displayName: 'My Plex', ports: [webPort, adminPort]),
      );

      await openConfigScreen(tester, config!);

      expect(find.text('Configure plex'), findsOneWidget);
      expect(find.text('My Plex'), findsOneWidget);
      expect(find.text('Web UI'), findsOneWidget);
      expect(find.text('http://localhost:32400'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('https://localhost:32401'), findsOneWidget);
      expect(find.text('Primary'), findsOneWidget);
      expect(
        tester.widget<CupertinoSwitch>(switchForLabel('Enabled')).value,
        isTrue,
      );
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows the empty state when no ports are configured', (
      tester,
    ) async {
      final config = await runRealAsync(tester, () => seedConfig());

      await openConfigScreen(tester, config!);

      expect(find.text('No ports configured'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(fieldForLabel('Primary URL'))
            .controller
            .text,
        isEmpty,
      );
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'does not overflow at iPhone width with a long name and port list',
      (tester) async {
        useCompactSurface(tester);

        const longPort = AppPortConfig(
          portNumber: 8443,
          protocol: 'https',
          serviceName:
              'A Very Long Service Name That Stresses The Port Row Layout',
          customUrl: 'https://a-very-long-custom-hostname.example.com:8443',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(
            appName: 'a-long-installed-application-instance-name',
            displayName:
                'A Long Display Name That Also Stresses The Layout Row',
            ports: [longPort],
          ),
        );

        await openConfigScreen(tester, config!);
        expectNoLayoutOverflow(tester);

        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pump();
        expectNoLayoutOverflow(tester);
      },
    );
  });

  group('app info editing', () {
    testWidgets('editing the display name persists on save', (tester) async {
      final config = await runRealAsync(
        tester,
        () => seedConfig(displayName: 'Original Name'),
      );

      final closed = await openConfigScreen(tester, config!);

      await tester.enterText(fieldForLabel('Display Name'), 'Renamed App');
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(tester, () => closed.value);
      expect(closed.value, isTrue);

      final saved = await runRealAsync(
        tester,
        () => database.getFullAppConfig(testServer.id, config.appName),
      );
      expect(saved!.displayName, 'Renamed App');
    });

    testWidgets('clearing the display name field clears it on save', (
      tester,
    ) async {
      final config = await runRealAsync(
        tester,
        () => seedConfig(displayName: 'Original Name'),
      );

      final closed = await openConfigScreen(tester, config!);

      await tester.enterText(fieldForLabel('Display Name'), '');
      await tester.pump();

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(tester, () => closed.value);

      final saved = await runRealAsync(
        tester,
        () => database.getFullAppConfig(testServer.id, config.appName),
      );
      expect(saved!.displayName, isNull);
    });

    testWidgets('toggling the Enabled switch off persists on save', (
      tester,
    ) async {
      final config = await runRealAsync(tester, () => seedConfig());

      final closed = await openConfigScreen(tester, config!);

      expect(
        tester.widget<CupertinoSwitch>(switchForLabel('Enabled')).value,
        isTrue,
      );
      await tester.tap(switchForLabel('Enabled'));
      await tester.pump();
      expect(
        tester.widget<CupertinoSwitch>(switchForLabel('Enabled')).value,
        isFalse,
      );

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(tester, () => closed.value);

      final saved = await runRealAsync(
        tester,
        () => database.getFullAppConfig(testServer.id, config.appName),
      );
      expect(saved!.isEnabled, isFalse);
    });

    testWidgets(
      'editing the Primary URL field updates the primary port live and on '
      'save',
      (tester) async {
        const webPort = AppPortConfig(
          portNumber: 8080,
          protocol: 'http',
          serviceName: 'Web UI',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [webPort]),
        );

        final closed = await openConfigScreen(tester, config!);

        expect(find.text('http://localhost:8080'), findsOneWidget);

        await tester.enterText(
          fieldForLabel('Primary URL'),
          'https://custom.example.com:9999',
        );
        await tester.pump();

        // The port row reflects the edit immediately, without saving.
        expect(staticText('https://custom.example.com:9999'), findsOneWidget);
        expect(find.text('http://localhost:8080'), findsNothing);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        expect(saved!.ports, hasLength(1));
        expect(saved.ports.single.customUrl, 'https://custom.example.com:9999');
      },
    );

    testWidgets(
      'clearing an existing Primary URL falls back to the default URL and '
      'clears the stored customUrl on save',
      (tester) async {
        const webPort = AppPortConfig(
          portNumber: 8080,
          protocol: 'http',
          serviceName: 'Web UI',
          customUrl: 'https://custom.example.com',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [webPort]),
        );

        final closed = await openConfigScreen(tester, config!);

        expect(staticText('https://custom.example.com'), findsOneWidget);

        await tester.enterText(fieldForLabel('Primary URL'), '');
        await tester.pump();

        expect(staticText('https://custom.example.com'), findsNothing);
        expect(find.text('http://localhost:8080'), findsOneWidget);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        expect(saved!.ports.single.customUrl, isNull);
      },
    );

    testWidgets(
      'typing a Primary URL with no existing ports creates a new primary '
      'port',
      (tester) async {
        final config = await runRealAsync(tester, () => seedConfig());

        final closed = await openConfigScreen(tester, config!);

        expect(find.text('No ports configured'), findsOneWidget);

        await tester.enterText(
          fieldForLabel('Primary URL'),
          'http://newly-created.example.com',
        );
        await tester.pump();

        expect(find.text('No ports configured'), findsNothing);
        expect(find.text('Web Interface'), findsOneWidget);
        expect(staticText('http://newly-created.example.com'), findsOneWidget);
        expect(find.text('Primary'), findsOneWidget);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        expect(saved!.ports, hasLength(1));
        final newPort = saved.ports.single;
        expect(newPort.serviceName, 'Web Interface');
        expect(newPort.customUrl, 'http://newly-created.example.com');
        expect(newPort.isPrimary, isTrue);
        expect(newPort.portNumber, 80);
      },
    );
  });

  group('port row actions', () {
    testWidgets('tapping the link icon does not throw', (tester) async {
      const webPort = AppPortConfig(
        portNumber: 32400,
        serviceName: 'Web UI',
        isPrimary: true,
        isEnabled: true,
      );
      final config = await runRealAsync(
        tester,
        () => seedConfig(ports: [webPort]),
      );

      await openConfigScreen(tester, config!);

      await tester.tap(
        find.descendant(
          of: portRowFor('Web UI'),
          matching: find.byIcon(CupertinoIcons.link),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'the pencil icon opens an edit modal pre-filled with the port',
      (tester) async {
        const apiPort = AppPortConfig(
          portNumber: 8443,
          protocol: 'https',
          serviceName: 'API',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [apiPort]),
        );

        await openConfigScreen(tester, config!);

        await tester.tap(
          find.descendant(
            of: portRowFor('API'),
            matching: find.byIcon(CupertinoIcons.pencil),
          ),
        );
        await settleRouteTransition(tester);

        final modal = modalScaffoldWithTitle('Edit Port');
        expect(modal, findsOneWidget);
        expect(find.text('8443'), findsOneWidget);
        expect(find.text('API'), findsWidgets);
        expect(
          tester
              .widget<CupertinoSwitch>(switchForLabel('Enabled', scope: modal))
              .value,
          isTrue,
        );
        expect(buttonWithText('Set as Primary', scope: modal), findsOneWidget);
        expect(buttonWithText('Delete Port', scope: modal), findsOneWidget);
      },
    );

    testWidgets(
      'editing a port in the modal updates the row and persists on save',
      (tester) async {
        const webPort = AppPortConfig(
          portNumber: 32400,
          protocol: 'http',
          serviceName: 'Web UI',
          isPrimary: true,
          isEnabled: true,
        );
        const adminPort = AppPortConfig(
          portNumber: 32401,
          protocol: 'https',
          serviceName: 'Admin',
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [webPort, adminPort]),
        );

        final closed = await openConfigScreen(tester, config!);

        await tester.tap(
          find.descendant(
            of: portRowFor('Admin'),
            matching: find.byIcon(CupertinoIcons.pencil),
          ),
        );
        await settleRouteTransition(tester);

        final modal = modalScaffoldWithTitle('Edit Port');
        await tester.enterText(
          fieldForLabel('Service Name', scope: modal),
          'Admin UI',
        );
        await tester.enterText(fieldForLabel('Port', scope: modal), '9443');
        await tester.tap(switchForLabel('Enabled', scope: modal));
        await tester.pump();

        await tester.tap(buttonWithText('Save', scope: modal));
        await settleRouteTransition(tester);

        // Reflected on the main screen without needing the outer Save yet.
        expect(find.text('Admin'), findsNothing);
        expect(find.text('Admin UI'), findsOneWidget);
        expect(find.text('https://localhost:9443'), findsOneWidget);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        final updated = saved!.ports.firstWhere(
          (p) => p.serviceName == 'Admin UI',
        );
        expect(updated.portNumber, 9443);
        expect(updated.isEnabled, isFalse);
        expect(updated.isPrimary, isFalse);
      },
    );

    testWidgets(
      'clearing the Custom URL field in the edit-port modal clears it on '
      'save',
      (tester) async {
        const webPort = AppPortConfig(
          portNumber: 32400,
          protocol: 'http',
          serviceName: 'Web UI',
          customUrl: 'https://custom.example.com',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [webPort]),
        );

        final closed = await openConfigScreen(tester, config!);

        await tester.tap(
          find.descendant(
            of: portRowFor('Web UI'),
            matching: find.byIcon(CupertinoIcons.pencil),
          ),
        );
        await settleRouteTransition(tester);

        final modal = modalScaffoldWithTitle('Edit Port');
        await tester.enterText(fieldForLabel('Custom URL', scope: modal), '');
        await tester.pump();

        await tester.tap(buttonWithText('Save', scope: modal));
        await settleRouteTransition(tester);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        expect(saved!.ports.single.customUrl, isNull);
      },
    );

    testWidgets('"Set as Primary" in the modal reassigns the primary port', (
      tester,
    ) async {
      const webPort = AppPortConfig(
        portNumber: 32400,
        serviceName: 'Web UI',
        isPrimary: true,
        isEnabled: true,
      );
      const adminPort = AppPortConfig(
        portNumber: 32401,
        serviceName: 'Admin',
        isEnabled: true,
      );
      final config = await runRealAsync(
        tester,
        () => seedConfig(ports: [webPort, adminPort]),
      );

      final closed = await openConfigScreen(tester, config!);

      await tester.tap(
        find.descendant(
          of: portRowFor('Admin'),
          matching: find.byIcon(CupertinoIcons.pencil),
        ),
      );
      await settleRouteTransition(tester);

      final modal = modalScaffoldWithTitle('Edit Port');
      await tester.tap(buttonWithText('Set as Primary', scope: modal));
      await settleRouteTransition(tester);

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(tester, () => closed.value);

      final saved = await runRealAsync(
        tester,
        () => database.getFullAppConfig(testServer.id, config.appName),
      );
      final primary = saved!.ports.firstWhere((p) => p.isPrimary);
      expect(primary.serviceName, 'Admin');
      expect(
        saved.ports.firstWhere((p) => p.serviceName == 'Web UI').isPrimary,
        isFalse,
      );
    });

    testWidgets('"Delete Port" in the modal removes the port immediately', (
      tester,
    ) async {
      const webPort = AppPortConfig(
        portNumber: 32400,
        serviceName: 'Web UI',
        isPrimary: true,
        isEnabled: true,
      );
      const adminPort = AppPortConfig(
        portNumber: 32401,
        serviceName: 'Admin',
        isEnabled: true,
      );
      final config = await runRealAsync(
        tester,
        () => seedConfig(ports: [webPort, adminPort]),
      );

      final closed = await openConfigScreen(tester, config!);

      await tester.tap(
        find.descendant(
          of: portRowFor('Admin'),
          matching: find.byIcon(CupertinoIcons.pencil),
        ),
      );
      await settleRouteTransition(tester);

      final modal = modalScaffoldWithTitle('Edit Port');
      await tester.tap(buttonWithText('Delete Port', scope: modal));
      await settleRouteTransition(tester);

      expect(find.text('Admin'), findsNothing);
      expect(find.text('Web UI'), findsOneWidget);

      await tapWhenUnambiguous(tester, find.text('Save'));
      await pumpUntilAsync(tester, () => closed.value);

      final saved = await runRealAsync(
        tester,
        () => database.getFullAppConfig(testServer.id, config.appName),
      );
      expect(saved!.ports, hasLength(1));
      expect(saved.ports.single.serviceName, 'Web UI');
    });

    testWidgets(
      '"Add Port" opens a modal without Set Primary/Delete and appends a '
      'port on save',
      (tester) async {
        const webPort = AppPortConfig(
          portNumber: 32400,
          serviceName: 'Web UI',
          isPrimary: true,
          isEnabled: true,
        );
        final config = await runRealAsync(
          tester,
          () => seedConfig(ports: [webPort]),
        );

        final closed = await openConfigScreen(tester, config!);

        await tester.tap(find.text('Add Port'));
        await settleRouteTransition(tester);

        final modal = modalScaffoldWithTitle('Add Port');
        expect(modal, findsOneWidget);
        expect(buttonWithText('Set as Primary', scope: modal), findsNothing);
        expect(buttonWithText('Delete Port', scope: modal), findsNothing);

        await tester.enterText(fieldForLabel('Port', scope: modal), '9000');
        await tester.enterText(
          fieldForLabel('Service Name', scope: modal),
          'New Service',
        );
        await tester.tap(buttonWithText('Save', scope: modal));
        await settleRouteTransition(tester);

        expect(find.text('New Service'), findsOneWidget);
        expect(find.text('http://localhost:9000'), findsOneWidget);

        await tapWhenUnambiguous(tester, find.text('Save'));
        await pumpUntilAsync(tester, () => closed.value);

        final saved = await runRealAsync(
          tester,
          () => database.getFullAppConfig(testServer.id, config.appName),
        );
        expect(saved!.ports, hasLength(2));
        expect(
          saved.ports.any(
            (p) => p.serviceName == 'New Service' && p.portNumber == 9000,
          ),
          isTrue,
        );
      },
    );

    testWidgets(
      'an invalid port number in the modal is ignored - the modal stays '
      'open and nothing is added',
      (tester) async {
        final config = await runRealAsync(tester, () => seedConfig());

        await openConfigScreen(tester, config!);

        await tester.tap(find.text('Add Port'));
        await settleRouteTransition(tester);

        final modal = modalScaffoldWithTitle('Add Port');
        await tester.enterText(fieldForLabel('Port', scope: modal), '');
        await tester.tap(buttonWithText('Save', scope: modal));
        await tester.pump();

        // _savePort returns early on an unparsable port number, so the
        // modal never pops.
        expect(modalScaffoldWithTitle('Add Port'), findsOneWidget);

        await tester.tap(buttonWithText('Cancel', scope: modal));
        await settleRouteTransition(tester);

        expect(find.text('No ports configured'), findsOneWidget);
      },
    );
  });
}
