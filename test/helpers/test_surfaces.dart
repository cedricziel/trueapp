import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sizing utilities for choosing the logical surface a widget test renders
/// at.
///
/// `flutter_test` renders every widget test at a fixed 800x600 logical
/// surface unless a test overrides it. [AdaptiveNavigationScaffold] switches
/// between its sidebar and compact layouts at a 768pt width breakpoint, so
/// every existing widget test - simply by inheriting the 800x600 default -
/// only ever exercises the sidebar (regular/wide) branch. The compact branch,
/// which is what the vast majority of users see on an iPhone, has never been
/// rendered by the test suite. [useCompactSurface] and [useRegularSurface]
/// exist to make that choice explicit for a test, rather than an accident of
/// the framework default.
///
/// Call these BEFORE `tester.pumpWidget`. `tester.view.physicalSize` only
/// takes effect for the next layout pass; setting it after a widget has
/// already been pumped leaves that widget laid out at the old size until the
/// next `pump()`, which can silently pass a test that should have failed.
///
/// [useSurface] and its two named convenience wrappers register
/// `tester.view.reset` with [addTearDown], which restores every override
/// this made (size, device pixel ratio, and padding) so it cannot leak into
/// a later test in the same file - `tester.view` is shared by the whole
/// binding, not scoped to one test.
///
/// View padding (notches, home indicators, status/nav bar insets) is
/// deliberately left at zero here. The overflow this module exists to catch
/// is horizontal, and zero padding keeps `SafeArea` math predictable; a
/// `kCompactSurfaceWithInsets` constant that also stubs `tester.view.padding`
/// is a natural follow-up if a test ever needs to cover the notch/home
/// indicator case specifically.

/// A named logical surface a widget test can render at.
@immutable
class TestSurface {
  const TestSurface({
    required this.name,
    required this.size,
    required this.devicePixelRatio,
  });

  /// A human-readable label for failure messages, e.g. in a `reason:`.
  final String name;

  /// The logical size `MediaQuery` should report for widgets under test.
  final Size size;

  /// The device pixel ratio backing [size].
  final double devicePixelRatio;

  /// The physical size to assign to `tester.view.physicalSize`, which is
  /// specified in physical pixels rather than logical ones.
  Size get physicalSize => size * devicePixelRatio;
}

/// An iPhone-class surface, below [kNavigationBreakpoint] - exercises
/// `AdaptiveNavigationScaffold`'s compact layout.
const TestSurface kCompactSurface = TestSurface(
  name: 'iPhone 14 (390x844)',
  size: Size(390, 844),
  devicePixelRatio: 3.0,
);

/// An iPad-class surface, comfortably above [kNavigationBreakpoint] -
/// exercises `AdaptiveNavigationScaffold`'s sidebar layout.
///
/// This is deliberately its own named surface rather than a reuse of
/// `flutter_test`'s 800x600 default: a test that asks for the regular
/// surface should say so explicitly, instead of relying on the default
/// happening to sit 32pt above the breakpoint.
const TestSurface kRegularSurface = TestSurface(
  name: 'iPad (1024x768)',
  size: Size(1024, 768),
  devicePixelRatio: 2.0,
);

/// Sizes the test surface to [surface] and restores the previous surface on
/// teardown. Call this before `tester.pumpWidget`.
void useSurface(WidgetTester tester, TestSurface surface) {
  tester.view.physicalSize = surface.physicalSize;
  tester.view.devicePixelRatio = surface.devicePixelRatio;
  addTearDown(tester.view.reset);
}

/// Sizes the test surface to [kCompactSurface] (an iPhone-class phone,
/// below the navigation breakpoint) and restores it on teardown.
void useCompactSurface(WidgetTester tester) {
  useSurface(tester, kCompactSurface);
}

/// Sizes the test surface to [kRegularSurface] (an iPad-class device, above
/// the navigation breakpoint) and restores it on teardown.
void useRegularSurface(WidgetTester tester) {
  useSurface(tester, kRegularSurface);
}
