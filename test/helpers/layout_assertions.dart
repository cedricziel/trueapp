import 'package:flutter_test/flutter_test.dart';

/// Assertions for catching `RenderFlex` overflow at a given test surface.
///
/// `RenderFlex` only reports an overflow during PAINT, not layout - so a
/// `Row` that overflows below the fold of a `ListView` never reports until
/// the test actually scrolls it into view. Pump, assert, scroll, assert
/// again: a single first-frame check is not enough to prove a screen never
/// overflows.
///
/// When more than one overflow is live in the same frame,
/// `tester.takeException()` collapses them into a single synthetic
/// "Multiple exceptions (N) were detected during the running of the current
/// test" object, while each individual error - including its
/// `Row … file:line` provenance - is still dumped to the console by the test
/// binding. Read the console output, not just the returned exception, to
/// find the offending widget.
///
/// [tester.takeException] also *consumes* the pending error: calling it a
/// second time in the same test returns `null` even if a second overflow is
/// still live. Call [expectNoLayoutOverflow] once per phase of a test (e.g.
/// once before scrolling, once after), never twice for the same pump.

/// Asserts that no exception - in particular no `RenderFlex` overflow - is
/// pending for the current frame.
///
/// This deliberately does not assert on an overflow's pixel count: the
/// widget-test environment renders with a synthetic square-glyph font whose
/// metrics do not match the real typeface, so a pixel figure measured under
/// test says nothing about whether a device would actually overflow. Only
/// "no exception" is asserted.
void expectNoLayoutOverflow(WidgetTester tester, {String? reason}) {
  final exception = tester.takeException();
  expect(
    exception,
    isNull,
    reason: reason ?? 'The layout must not overflow at this surface size',
  );
}
