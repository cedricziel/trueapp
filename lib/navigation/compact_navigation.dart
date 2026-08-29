import 'package:flutter/cupertino.dart';

/// The compact (phone-width) layout for [AdaptiveNavigationScaffold].
///
/// Every routed screen (`HomeScreen`, `SettingsScreen`, `ServerDetailScreen`)
/// already supplies its own [CupertinoNavigationBar], so this widget does
/// not add a second one - doing so used to stack two navigation bars on
/// every phone-width screen, which is exactly the class of bug ticket #87
/// exists to catch by finally rendering this branch under test. Destination
/// switching instead lives in a bottom [CompactDestinationBar], matching the
/// iPhone-first tab-bar convention rather than a hamburger menu.
class CompactNavigation extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget child;

  const CompactNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: child),
          CompactDestinationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
        ],
      ),
    );
  }
}

/// The bottom tab bar the compact layout uses to switch between the
/// "Servers" and "Settings" destinations.
class CompactDestinationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const CompactDestinationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          label: 'Servers',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}
