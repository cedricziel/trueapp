import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/providers/pool_provider.dart';
import 'package:truenas_manager/providers/dataset_provider.dart';
import 'package:truenas_manager/providers/app_provider.dart';
import 'package:truenas_manager/screens/home_screen.dart';
import 'package:truenas_manager/services/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppDatabase>.value(value: database),
        ChangeNotifierProvider(create: (context) => ServerProvider(database)),
        ChangeNotifierProvider(create: (context) => PoolProvider()),
        ChangeNotifierProvider(create: (context) => DatasetProvider()),
        ChangeNotifierProvider(create: (context) => AppProvider()),
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
