import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/app_provider.dart';
import 'package:truehub/providers/connection_status_provider.dart';
import 'package:truehub/providers/pool_provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/system_stats_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/unified_server_service.dart';

/// Wraps [child] with the provider stack the app's shell screens
/// (`HomeScreen`, `SettingsScreen`, `ServerDetailScreen`) read from context.
///
/// [ServerProvider] is the one provider every one of those screens needs, so
/// it is required. [PoolProvider], [AppProvider], [SystemStatsProvider] and
/// [ConnectionStatusProvider] are only read by `ServerDetailScreen`, and
/// [TrayProvider] only by `SettingsScreen`; pass one in when a test pumps
/// the screen that needs it, and leave it out otherwise - a
/// `ChangeNotifierProvider(create: ...)` still backs every one of them by
/// default so `Provider.of` never fails to resolve, but tests that need to
/// inspect or seed one should build and pass it explicitly.
///
/// Every notifier is caller-owned: this widget never creates one behind a
/// caller's back unless the caller omits it, and it never disposes what it
/// is handed. That keeps `TestProviders.disposeTestStack` usable for
/// teardown exactly the way the rest of the suite already uses it - the test
/// that created a provider is the test that must dispose it.
Widget provideAppProviders({
  required Widget child,
  required AppDatabase database,
  required UnifiedServerService service,
  required ServerProvider serverProvider,
  PoolProvider? poolProvider,
  AppProvider? appProvider,
  SystemStatsProvider? systemStatsProvider,
  ConnectionStatusProvider? connectionStatusProvider,
  TrayProvider? trayProvider,
}) {
  return MultiProvider(
    providers: [
      Provider<AppDatabase>.value(value: database),
      Provider<UnifiedServerService>.value(value: service),
      ChangeNotifierProvider.value(value: serverProvider),
      poolProvider != null
          ? ChangeNotifierProvider<PoolProvider>.value(value: poolProvider)
          : ChangeNotifierProvider<PoolProvider>(
              create: (_) => PoolProvider(service),
            ),
      appProvider != null
          ? ChangeNotifierProvider<AppProvider>.value(value: appProvider)
          : ChangeNotifierProvider<AppProvider>(
              create: (_) =>
                  AppProvider(database: database, serverService: service),
            ),
      systemStatsProvider != null
          ? ChangeNotifierProvider<SystemStatsProvider>.value(
              value: systemStatsProvider,
            )
          : ChangeNotifierProvider<SystemStatsProvider>(
              create: (_) => SystemStatsProvider(service),
            ),
      connectionStatusProvider != null
          ? ChangeNotifierProvider<ConnectionStatusProvider>.value(
              value: connectionStatusProvider,
            )
          : ChangeNotifierProvider<ConnectionStatusProvider>(
              create: (_) => ConnectionStatusProvider(),
            ),
      trayProvider != null
          ? ChangeNotifierProvider<TrayProvider>.value(value: trayProvider)
          : ChangeNotifierProvider<TrayProvider>(create: (_) => TrayProvider()),
    ],
    child: child,
  );
}
