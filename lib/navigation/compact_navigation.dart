import 'package:flutter/cupertino.dart';
import 'package:truehub/navigation/navigation_destinations.dart';

class CompactNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final Widget child;

  const CompactNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  State<CompactNavigation> createState() => _CompactNavigationState();
}

class _CompactNavigationState extends State<CompactNavigation> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.line_horizontal_3),
          onPressed: () {
            _showNavigationMenu(context);
          },
        ),
        middle: Text(_getCurrentPageTitle()),
      ),
      child: widget.child,
    );
  }

  String _getCurrentPageTitle() {
    if (widget.selectedIndex < compactNavigationDestinations.length) {
      return compactNavigationDestinations[widget.selectedIndex].label;
    }
    return 'TrueNAS Manager';
  }

  void _showNavigationMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Navigate to'),
        actions: compactNavigationDestinations.asMap().entries.map((entry) {
          final index = entry.key;
          final destination = entry.value;

          return CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onDestinationSelected(index);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(destination.icon),
                const SizedBox(width: 8),
                Text(destination.label),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }
}
