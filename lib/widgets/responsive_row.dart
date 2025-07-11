import 'package:flutter/cupertino.dart';

/// A responsive row widget that switches between row and column layout
/// based on screen width breakpoints
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final double breakpoint;
  final double spacing;
  final bool forceColumn;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.breakpoint = 600, // Default breakpoint for mobile/tablet
    this.spacing = 12,
    this.forceColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < breakpoint || forceColumn;

    if (isMobile) {
      // Column layout for mobile
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    } else {
      // Row layout for larger screens
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) SizedBox(width: spacing),
          ],
        ],
      );
    }
  }
}