import 'package:flutter/cupertino.dart';

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
    switch (widget.selectedIndex) {
      case 0:
        return 'Servers';
      case 1:
        return 'Settings';
      default:
        return 'TrueNAS Manager';
    }
  }

  void _showNavigationMenu(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Navigate to'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onDestinationSelected(0);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.house),
                SizedBox(width: 8),
                Text('Servers'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              widget.onDestinationSelected(1);
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.settings),
                SizedBox(width: 8),
                Text('Settings'),
              ],
            ),
          ),
        ],
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
