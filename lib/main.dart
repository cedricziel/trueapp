import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/dataset_provider.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/providers/system_stats_provider.dart';
import 'package:truenas_manager/providers/connection_status_provider.dart';
import 'package:truenas_manager/screens/home_screen.dart';
import 'package:truenas_manager/services/database.dart';
import 'package:truenas_manager/services/api_client_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final connectionStatusProvider = ConnectionStatusProvider();
  
  // Set up the connection status provider for API client manager
  ApiClientManager.setConnectionStatusProvider(connectionStatusProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider.value(value: connectionStatusProvider),
        ChangeNotifierProvider(create: (context) => ServerProvider(database)),
        ChangeNotifierProvider(create: (context) => PoolProvider()),
        ChangeNotifierProvider(create: (context) => DatasetProvider()),
        ChangeNotifierProvider(create: (context) => AppProvider()),
        ChangeNotifierProvider(create: (context) => SystemStatsProvider()),
      ],
      child: const TrueNASManagerApp(),
    ),
  );
}

class TrueNASManagerApp extends StatelessWidget {
  const TrueNASManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'TrueNAS Manager',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}
