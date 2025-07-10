import 'package:drift/native.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/models/nas_server.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/screens/home_screen.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/models/server_health.dart';
import 'package:truenas_manager/models/user_info.dart';
import 'package:truenas_manager/models/connection_error.dart';

// Mock providers that don't make network calls
class MockServerProvider extends ChangeNotifier implements ServerProvider {
  final AppDatabase _database;
  final List<NasServer> _servers = [];
  NasServer? _selectedServer;

  MockServerProvider(this._database);

  AppDatabase get database => _database;

  @override
  List<NasServer> get servers => _servers;

  @override
  NasServer? get selectedServer => _selectedServer;

  @override
  Future<void> addServer(NasServer server) async {
    await _database.insertServer(server);
    _servers.add(server);
    notifyListeners();
  }

  @override
  void selectServer(NasServer? server) {
    _selectedServer = server;
    notifyListeners();
  }

  @override
  Future<void> updateServer(NasServer server) async {
    await _database.updateServer(server);
    final index = _servers.indexWhere((s) => s.id == server.id);
    if (index != -1) {
      _servers[index] = server;
    }
    if (_selectedServer?.id == server.id) {
      _selectedServer = server;
    }
    notifyListeners();
  }

  @override
  Future<void> loadCurrentUser() async {
    // Don't make network calls
  }

  @override
  Future<void> refreshSelectedServer() async {
    if (_selectedServer != null) {
      final updated = await _database.getServer(_selectedServer!.id);
      if (updated != null) {
        _selectedServer = updated;
        notifyListeners();
      }
    }
  }

  @override
  Future<void> deleteServer(String id) async {
    await _database.deleteServer(id);
    _servers.removeWhere((s) => s.id == id);
    if (_selectedServer?.id == id) {
      _selectedServer = null;
    }
    notifyListeners();
  }

  // Additional required methods
  @override
  Future<void> loadServers() async {
    _servers.clear();
    _servers.addAll(await _database.getAllServers());
    notifyListeners();
  }

  @override
  void clearSelectedServer() {
    _selectedServer = null;
    notifyListeners();
  }

  @override
  Future<void> loadServerHealth() async {
    // Mock - don't make network calls
  }

  @override
  Future<bool> testServerConnection(NasServer server) async {
    return true; // Mock - always return success
  }

  @override
  Future<bool> validateServerCredentials(NasServer server) async {
    return true; // Mock - always return success
  }

  // Getters
  @override
  ServerHealth? get serverHealth => null;

  @override
  bool get isLoadingHealth => false;

  @override
  String? get healthError => null;

  @override
  UserInfo? get currentUser => null;

  @override
  bool get isLoadingUser => false;

  @override
  String? get userError => null;

  @override
  Future<void> setDefaultServer(String serverId) async {
    await _database.setDefaultServer(serverId);
    await loadServers();
  }

  @override
  Future<void> clearDefaultServer() async {
    await _database.clearDefaultServer();
    await loadServers();
  }

  @override
  Future<void> loadServersAndAutoSelect() async {
    await loadServers();
  }

  @override
  NasServer? get defaultServer {
    try {
      return _servers.firstWhere((server) => server.isDefault);
    } catch (e) {
      return null;
    }
  }
}

class MockPoolProvider extends ChangeNotifier implements PoolProvider {
  @override
  void setApiClient(NasServer server) {
    // Don't create WebSocket connection
  }

  @override
  Future<void> loadPools() async {
    // Don't make network calls
    notifyListeners();
  }

  @override
  List<Map<String, dynamic>> get pools => [];

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  ConnectionError? get connectionError => null;

  @override
  Future<void> refreshPools() async {
    // Mock - don't refresh
  }

  @override
  void setServer(NasServer? server) {
    // Mock - don't set server
  }
}

void main() {
  late AppDatabase database;
  late ServerProvider serverProvider;
  late PoolProvider poolProvider;
  late NasServer testServer;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    serverProvider = ServerProvider(database);
    poolProvider = PoolProvider();

    // Create and register a test server
    testServer = NasServer.create(
      name: 'Test TrueNAS Server',
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
    await serverProvider.loadServers(); // Make sure servers are loaded
  });

  tearDown(() async {
    await database.close();
  });

  group('Complete Edit Flow End-to-End Test', () {
    testWidgets('should complete full user journey with mocked providers', (
      WidgetTester tester,
    ) async {
      // Set a larger surface size to accommodate all UI elements
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      // Create the complete app with providers
      Widget createTestApp() {
        return MultiProvider(
          providers: [
            Provider<AppDatabase>.value(value: database),
            ChangeNotifierProvider.value(value: serverProvider),
            ChangeNotifierProvider.value(value: poolProvider),
          ],
          child: const CupertinoApp(home: HomeScreen()),
        );
      }

      await tester.pumpWidget(createTestApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // STEP 1: Verify we're on the Home Screen
      expect(find.text('TrueNAS Manager'), findsOneWidget);
      expect(find.text('Test TrueNAS Server'), findsOneWidget);

      // STEP 2: Navigate to Server Detail Screen
      await tester.tap(find.text('Test TrueNAS Server'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Extra wait for async operations in ServerDetailScreen
      await tester.pump(const Duration(milliseconds: 500));

      // Verify we're on Server Detail Screen
      expect(find.text('Host'), findsOneWidget);
      expect(find.text('192.168.1.100'), findsOneWidget);

      // STEP 3: Navigate to Edit Screen via ellipsis menu
      final ellipsisButton = find.byIcon(CupertinoIcons.ellipsis);
      expect(ellipsisButton, findsOneWidget);

      await tester.tap(ellipsisButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify action sheet is displayed
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Edit Server'), findsOneWidget);

      // Tap "Edit Server"
      await tester.tap(find.text('Edit Server'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify we're on Edit Server Screen
      expect(find.text('Save'), findsWidgets);
      expect(find.text('Cancel'), findsWidgets);

      // STEP 4: Make changes
      final nameFields = find.byType(CupertinoTextField);
      await tester.enterText(nameFields.first, 'Updated TrueNAS Server');
      await tester.pump();

      // Wait for form to settle after text entry
      await tester.pump(const Duration(milliseconds: 500));

      // STEP 5: Save changes
      // Use the exact pattern from the working test
      final saveButtons = find.text('Save');
      expect(saveButtons, findsWidgets);
      await tester.tap(saveButtons.first, warnIfMissed: false);
      // Use pump with duration for navigation (longer wait)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // STEP 6: Verify we're back on Server Detail Screen
      expect(find.text('Updated TrueNAS Server'), findsWidgets);

      // STEP 7: Verify changes in provider
      expect(serverProvider.selectedServer?.name, 'Updated TrueNAS Server');

      // STEP 8: Verify changes in database
      final serverFromDb = await database.getServer(testServer.id);
      expect(serverFromDb?.name, 'Updated TrueNAS Server');
    });
  });
}
