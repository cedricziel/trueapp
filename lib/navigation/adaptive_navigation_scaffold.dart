import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:cupertino_sidebar/cupertino_sidebar.dart';
import 'package:truehub/navigation/compact_navigation.dart';
import 'package:truehub/navigation/navigation_layout.dart';

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
  bool _isSidebarExpanded = true;

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
    final width = MediaQuery.sizeOf(context).width;
    return NavigationLayout.resolve(
          width: width,
          platform: defaultTargetPlatform,
        ) ==
        NavigationLayoutMode.expanded;
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
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Row(
            children: [
              // Collapsible sidebar wrapper
              CupertinoSidebarCollapsible(
                isExpanded: _isSidebarExpanded,
                child: CupertinoSidebar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onDestinationSelected,
                  navigationBar: const SidebarNavigationBar(
                    title: Text('TrueNAS Manager'),
                  ),
                  children: const [
                    // Main Navigation - index 0
                    SidebarDestination(
                      icon: Icon(CupertinoIcons.house),
                      label: Text('Servers'),
                    ),
                    // Settings - index 1
                    SidebarDestination(
                      icon: Icon(CupertinoIcons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTabTransitionBuilder(
                  child: Container(
                    key: ValueKey(_selectedIndex),
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemGroupedBackground,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
          // Sidebar toggle button - positioned to avoid overlap with connection info
          Positioned(
            top: 0,
            left: _isSidebarExpanded
                ? 280
                : 10, // Move right when expanded, left when collapsed
            child: SafeArea(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _isSidebarExpanded = !_isSidebarExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground.withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.separator,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isSidebarExpanded
                          ? CupertinoIcons.sidebar_left
                          : CupertinoIcons.sidebar_right,
                      size: 18,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
