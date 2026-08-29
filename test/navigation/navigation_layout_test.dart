import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/navigation/navigation_layout.dart';

/// Pure-logic coverage for the compact/expanded decision
/// `AdaptiveNavigationScaffold` makes, isolated from widget pumping so it
/// can enumerate the boundary cases directly.
void main() {
  group('NavigationLayout.resolve', () {
    test('is compact below the breakpoint on a non-macOS platform', () {
      expect(
        NavigationLayout.resolve(width: 390, platform: TargetPlatform.iOS),
        NavigationLayoutMode.compact,
      );
    });

    test('is expanded exactly at the breakpoint (inclusive)', () {
      expect(
        NavigationLayout.resolve(width: 768, platform: TargetPlatform.iOS),
        NavigationLayoutMode.expanded,
      );
    });

    test('is expanded above the breakpoint', () {
      expect(
        NavigationLayout.resolve(width: 1024, platform: TargetPlatform.iOS),
        NavigationLayoutMode.expanded,
      );
    });

    test('is expanded on macOS even below the breakpoint', () {
      expect(
        NavigationLayout.resolve(width: 390, platform: TargetPlatform.macOS),
        NavigationLayoutMode.expanded,
      );
    });
  });
}
