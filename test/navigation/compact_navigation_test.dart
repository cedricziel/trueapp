import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/navigation/compact_navigation.dart';

/// Regression coverage for issue #112: `CompactNavigation` used to stack the
/// routed screen above `CompactDestinationBar` with a bare `Expanded`, so the
/// routed `child` still saw the full bottom `MediaQuery` padding even though
/// the tab bar's `CupertinoTabBar` already reserves that inset for itself.
/// Any routed screen wrapping its body in `SafeArea` then reserved the same
/// inset a second time, leaving a blank strip above the tab bar.
///
/// `test/helpers/test_surfaces.dart` deliberately renders at zero view
/// padding, so this test stubs `tester.view.padding` / `viewPadding` with a
/// non-zero bottom inset directly rather than using that helper.
void main() {
  testWidgets(
    'removes the bottom padding from the routed child, leaving the tab bar '
    'as the sole consumer of the bottom safe-area inset',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);

      double? childBottomPadding;

      await tester.pumpWidget(
        CupertinoApp(
          home: CompactNavigation(
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            child: Builder(
              builder: (context) {
                childBottomPadding = MediaQuery.paddingOf(context).bottom;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(
        childBottomPadding,
        0,
        reason:
            'the routed child must not see the bottom safe-area inset a '
            'second time - CupertinoTabBar in CompactDestinationBar already '
            'consumes it',
      );

      // The tab bar itself sits outside the removePadding scope (it is a
      // sibling of the wrapped child, not inside it), so it is still present
      // and unaffected - only the routed child's view of the inset changes.
      expect(find.byType(CupertinoTabBar), findsOneWidget);
    },
  );
}
