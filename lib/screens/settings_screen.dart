import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/providers/server_provider.dart';
import 'package:truehub/providers/tray_provider.dart';
import 'package:truehub/services/database.dart';
import 'package:truehub/services/authentication_session_service.dart';
import 'package:truehub/services/secure_storage_service.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) ...[
              Consumer<TrayProvider>(
                builder: (context, trayProvider, child) {
                  return CupertinoFormSection(
                    header: Text(Platform.isMacOS ? 'MENU BAR' : 'SYSTEM TRAY'),
                    children: [
                      CupertinoFormRow(
                        prefix: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Platform.isMacOS
                                  ? 'Minimize to Menu Bar'
                                  : 'Minimize to System Tray',
                            ),
                            Text(
                              Platform.isMacOS
                                  ? 'Close window minimizes to menu bar instead of quitting'
                                  : 'Close window minimizes to system tray instead of quitting',
                              style: const TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        child: CupertinoSwitch(
                          value: trayProvider.minimizeToTray,
                          onChanged: trayProvider.setMinimizeToTray,
                        ),
                      ),
                      CupertinoFormRow(
                        prefix: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Show in Dock'),
                            Text(
                              'Display app icon in dock while running',
                              style: TextStyle(
                                fontSize: 13,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        child: CupertinoSwitch(
                          value: trayProvider.showInDock,
                          onChanged: trayProvider.setShowInDock,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
            CupertinoFormSection(
              header: const Text('SECURITY'),
              children: [
                CupertinoFormRow(
                  prefix: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Authentication Session'),
                      Text(
                        'Manage biometric authentication session',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (builderContext) {
                      final session = AuthenticationSessionService.instance;
                      final isValid = session.isSessionValid;

                      return CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () async {
                          if (isValid) {
                            // Lock the session
                            session.invalidateSession();
                            setState(() {});
                            if (!mounted) return;
                            showCupertinoDialog(
                              context: builderContext,
                              builder: (dialogContext) => CupertinoAlertDialog(
                                title: const Text('Session Locked'),
                                content: const Text(
                                  'Your authentication session has been locked. You will need to authenticate again to access server credentials.',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    onPressed: () =>
                                        Navigator.of(dialogContext).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Test authentication
                            final success =
                                await SecureStorageService.authenticate(
                                  reason: 'Authenticate to unlock session',
                                );
                            if (!mounted) return;
                            setState(() {});
                            if (success && mounted) {
                              showCupertinoDialog(
                                // ignore: use_build_context_synchronously
                                context: builderContext,
                                builder: (dialogContext) => CupertinoAlertDialog(
                                  title: const Text('Session Unlocked'),
                                  content: const Text(
                                    'Authentication successful. Your session will remain active for 30 minutes.',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          isValid ? 'Lock Session' : 'Unlock Session',
                          style: TextStyle(
                            color: isValid
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.activeBlue,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CupertinoFormSection(
              header: const Text('DATABASE'),
              children: [
                CupertinoFormRow(
                  prefix: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Clear Database'),
                      Text(
                        'Remove all servers and reset app data',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showClearDatabaseDialog(context),
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CupertinoFormSection(
              header: const Text('ABOUT'),
              children: [
                const CupertinoFormRow(
                  prefix: Text('Version'),
                  child: Text(
                    '1.0.0+1',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
                const CupertinoFormRow(
                  prefix: Text('Database Schema'),
                  child: Text(
                    'Version 1',
                    style: TextStyle(color: CupertinoColors.systemGrey),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDatabaseDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear Database'),
        content: const Text(
          'This will permanently delete all servers and app data. This action cannot be undone.\n\n'
          'Are you sure you want to continue?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _clearDatabase(context);
            },
            child: const Text('Clear Database'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearDatabase(BuildContext context) async {
    try {
      // Show loading indicator
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const CupertinoAlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text('Recreating database...'),
            ],
          ),
        ),
      );

      // Clear the provider state first
      final serverProvider = context.read<ServerProvider>();
      serverProvider.clearSelectedServer();

      // Completely recreate the database file to ensure fresh schema
      try {
        // Close and dispose the database singleton
        await AppDatabase.disposeInstance();

        // Get the database file path and delete it
        final documentsDir = await getApplicationDocumentsDirectory();
        final dbPath = path.join(documentsDir.path, 'truenas_manager.sqlite');
        final dbFile = File(dbPath);

        if (await dbFile.exists()) {
          await dbFile.delete();
        }

        // Also delete any associated files (WAL, SHM)
        final walFile = File('$dbPath-wal');
        final shmFile = File('$dbPath-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();
      } catch (e) {
        // Fallback: Drop table method
        final database = AppDatabase.instance;
        await database.customStatement('DROP TABLE IF EXISTS nas_servers');
        await AppDatabase.disposeInstance();
      }

      // Reload servers in the provider - this will create a fresh database
      await serverProvider.loadServersAndAutoSelect();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Database Recreated'),
            content: const Text(
              'The database has been completely recreated with the latest schema. You can now add servers without any constraint issues.',
            ),
            actions: [
              CupertinoDialogAction(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  Navigator.of(context).pop(); // Return to home screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's still open
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to clear database: ${e.toString()}'),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
