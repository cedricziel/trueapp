import 'package:flutter/cupertino.dart';

/// A section title paired with an optional trailing action, e.g. a "View
/// All" button.
///
/// A bare `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, ...)` lays
/// its non-flex children out with unbounded main-axis constraints, so
/// neither the title nor the action can shrink to fit a narrow screen - this
/// is what overflowed `ServerDetailScreen` at phone widths. Giving the title
/// an [Expanded] slot instead reproduces the same spaceBetween look while
/// letting it shrink and ellipsize, and keeps the trailing [action] at its
/// natural width.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.action});

  /// The section title, shown at the leading edge.
  final String title;

  /// An optional trailing widget, e.g. a "View All" button.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        ?action,
      ],
    );
  }
}
