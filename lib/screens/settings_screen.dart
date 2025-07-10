import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/services/database.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Settings')),
      child: SafeArea(
        child: ListView(
          children: [
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
        // Get the database instance and close it
        final database = AppDatabase();
        await database.close();

        // Get the database file path and delete it
        final documentsDir = await getApplicationDocumentsDirectory();
        final dbPath = path.join(documentsDir.path, 'truenas_manager.sqlite');
        final dbFile = File(dbPath);

        if (await dbFile.exists()) {
          await dbFile.delete();
          print('Deleted old database file: $dbPath');
        }

        // Also delete any associated files (WAL, SHM)
        final walFile = File('$dbPath-wal');
        final shmFile = File('$dbPath-shm');
        if (await walFile.exists()) await walFile.delete();
        if (await shmFile.exists()) await shmFile.delete();

        print('Database files completely removed');
      } catch (e) {
        print('Error deleting database files: $e');

        // Fallback: Drop table method
        final database = AppDatabase();
        await database.customStatement('DROP TABLE IF EXISTS nas_servers');
        await database.close();
        print('Fallback: Dropped nas_servers table');
      }

      // Reload servers in the provider - this will create a fresh database
      await serverProvider.loadServers();

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
