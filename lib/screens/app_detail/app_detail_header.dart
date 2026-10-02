import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/widgets/app_icon.dart';

class AppDetailHeader extends StatelessWidget {
  final App app;

  const AppDetailHeader({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIcon(app: app, size: 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.effectiveDisplayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                app.latestHumanVersion.isNotEmpty
                    ? 'v${app.latestHumanVersion}'
                    : 'v${app.latestAppVersion}',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: app.installed
                      ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                      : CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  app.installed ? 'Installed' : 'Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: app.installed
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
