import 'package:flutter/cupertino.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/widgets/app_icon.dart';
import 'package:truenas_manager/screens/app_detail_screen.dart';

class AppCardWidget extends StatelessWidget {
  final App app;

  const AppCardWidget({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => AppDetailScreen(app: app)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CupertinoColors.separator, width: 0.5),
        ),
        child: Row(
          children: [
            AppIcon(app: app, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.systemGrey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: app.installed
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    app.installed ? 'Installed' : 'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: app.installed
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemBlue,
                    ),
                  ),
                ),
                if (app.categories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      app.categories.first,
                      style: const TextStyle(
                        fontSize: 11,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
