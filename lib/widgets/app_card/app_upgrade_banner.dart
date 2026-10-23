import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/widgets/app_lifecycle/app_upgrade_flow.dart';

class AppUpgradeBanner extends StatelessWidget {
  final App app;

  const AppUpgradeBanner({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final upgradeInfo = app.upgradeInfo!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.arrow_up_circle_fill,
            size: 14,
            color: CupertinoColors.systemYellow,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Update available: ${upgradeInfo.availableVersion ?? 'Latest'}',
              style: TextStyle(
                fontSize: 12,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          if (upgradeInfo.canUpgrade) ...[
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Text(
                'Upgrade',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemYellow,
                ),
              ),
              onPressed: () => showAppUpgradeFlow(context, app),
            ),
          ],
        ],
      ),
    );
  }
}
