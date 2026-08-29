import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';

class AppIcon extends StatelessWidget {
  final App app;
  final double size;
  final Color? fallbackBackgroundColor;
  final Color? fallbackIconColor;

  const AppIcon({
    super.key,
    required this.app,
    this.size = 44,
    this.fallbackBackgroundColor,
    this.fallbackIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        fallbackBackgroundColor ??
        (app.installed
            ? (app.healthy
                  ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                  : CupertinoColors.systemRed.withValues(alpha: 0.1))
            : CupertinoColors.systemBlue.withValues(alpha: 0.1));

    final iconColor =
        fallbackIconColor ??
        (app.installed
            ? (app.healthy
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed)
            : CupertinoColors.systemBlue);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2),
        child: app.iconUrl != null && app.iconUrl!.isNotEmpty
            ? Image.network(
                app.iconUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackIcon(iconColor);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: size * 0.4,
                      height: size * 0.4,
                      child: CupertinoActivityIndicator(radius: size * 0.1),
                    ),
                  );
                },
              )
            : _buildFallbackIcon(iconColor),
      ),
    );
  }

  Widget _buildFallbackIcon(Color iconColor) {
    IconData iconData;

    if (app.installed) {
      iconData = app.healthy
          ? CupertinoIcons.checkmark_circle
          : CupertinoIcons.exclamationmark_circle;
    } else {
      iconData = CupertinoIcons.app;
    }

    return Icon(iconData, color: iconColor, size: size * 0.5);
  }
}
