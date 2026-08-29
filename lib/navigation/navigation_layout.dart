import 'package:flutter/foundation.dart';

/// The layout mode [AdaptiveNavigationScaffold] renders.
enum NavigationLayoutMode {
  /// A single navigation bar with the routed screen filling the remaining
  /// space - the layout used below the breakpoint on non-macOS platforms.
  compact,

  /// The persistent sidebar layout - used at or above the breakpoint, and
  /// always on macOS regardless of width.
  expanded,
}

/// Decides which layout [AdaptiveNavigationScaffold] should render.
///
/// This is pulled out of the widget so the decision is unit-testable
/// without pumping a widget tree, and so it can be driven off
/// [defaultTargetPlatform] - the framework's platform, forced to
/// [TargetPlatform.android] under `flutter test` - rather than `dart:io`'s
/// `Platform`, which reflects the *host running the test* and therefore
/// makes the compact branch permanently unreachable in widget tests run on
/// a macOS development machine.
abstract final class NavigationLayout {
  /// The logical width, in points, at or above which the sidebar layout is
  /// used.
  static const double breakpoint = 768.0;

  /// Resolves the layout mode for a screen of [width] logical points on
  /// [platform].
  ///
  /// macOS always uses the sidebar layout, regardless of width, for
  /// consistency with the rest of the platform's app conventions.
  static NavigationLayoutMode resolve({
    required double width,
    required TargetPlatform platform,
  }) {
    return (width >= breakpoint || platform == TargetPlatform.macOS)
        ? NavigationLayoutMode.expanded
        : NavigationLayoutMode.compact;
  }
}
