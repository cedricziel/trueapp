import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:truehub/navigation/navigation_destinations.dart';
import 'package:truehub/navigation/compact_navigation.dart';

class AdaptiveNavigationScaffold extends StatefulWidget {
  final Widget child;

  const AdaptiveNavigationScaffold({super.key, required this.child});

  @override
  State<AdaptiveNavigationScaffold> createState() =>
      _AdaptiveNavigationScaffoldState();
}

class _AdaptiveNavigationScaffoldState
    extends State<AdaptiveNavigationScaffold> {
  int _selectedIndex = 0;

  static const double _breakpoint = 768.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  void _updateSelectedIndex() {
    final String location = GoRouterState.of(context).uri.toString();
    int newIndex = 0;

    if (location.startsWith('/servers') || location.startsWith('/server/')) {
      // Both server list and server detail should highlight "Servers" in sidebar
      newIndex = 0;
    } else if (location.startsWith('/settings')) {
      newIndex = 1;
    }

    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  bool _isLargeScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Use breakpoint for width, but also consider platform
    // macOS should always use sidebar for consistency
    return size.width >= _breakpoint || Platform.isMacOS;
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) {
      // If already on the selected destination, navigate to its root
      switch (index) {
        case 0:
          context.go('/servers');
          break;
        case 1:
          context.go('/settings');
          break;
      }
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go('/servers');
        break;
      case 1:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = _isLargeScreen(context);

    if (isLargeScreen) {
      return _buildSidebarNavigation();
    } else {
      return _buildCompactNavigation();
    }
  }

  Widget _buildSidebarNavigation() {
    return Row(
      children: [
        CupertinoSidebar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          children: navigationDestinations,
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactNavigation() {
    return CompactNavigation(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onDestinationSelected,
      child: widget.child,
    );
  }
}
