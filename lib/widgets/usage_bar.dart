import 'package:flutter/cupertino.dart';

/// A reusable progress bar widget for showing usage percentages
class UsageBar extends StatelessWidget {
  final double usage;
  final Color color;
  final double height;
  final double borderRadius;

  const UsageBar({
    super.key,
    required this.usage,
    required this.color,
    this.height = 8,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey5,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: (usage / 100).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}