import 'package:flutter/cupertino.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';

final List<SidebarDestination> navigationDestinations = [
  SidebarDestination(
    icon: Icon(CupertinoIcons.desktopcomputer),
    label: Text('Servers'),
  ),
  SidebarDestination(
    icon: Icon(CupertinoIcons.settings),
    label: Text('Settings'),
  ),
];

final List<NavigationDestination> compactNavigationDestinations = [
  NavigationDestination(icon: CupertinoIcons.desktopcomputer, label: 'Servers'),
  NavigationDestination(icon: CupertinoIcons.settings, label: 'Settings'),
];

class NavigationDestination {
  final IconData icon;
  final String label;

  const NavigationDestination({required this.icon, required this.label});
}
