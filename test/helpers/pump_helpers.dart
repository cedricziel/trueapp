import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumping utilities for widget tests.
///
/// Large parts of the app render an indefinite [CupertinoActivityIndicator]
/// while a server connection is being authenticated. `pumpAndSettle` never
/// returns in that situation because the animation never stops, which is why
/// the widget tests in this repository must not use it.
///
/// The helpers below pump a bounded number of frames and stop as soon as a
/// condition holds, which gives the same intent as `pumpAndSettle` without the
/// risk of hanging the whole test file.

/// The default budget a single [pumpUntil] call may spend.
const Duration kPumpUntilTimeout = Duration(seconds: 5);

/// The amount of virtual time advanced per pumped frame.
const Duration kPumpStep = Duration(milliseconds: 50);

/// Pumps frames until [condition] returns `true`, or until [timeout] of
/// virtual time has been consumed.
///
/// Returns `true` when [condition] became satisfied and `false` when the
/// timeout was hit. Callers that require the condition should assert on the
/// widget tree afterwards so the failure message points at the real problem.
Future<bool> pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = kPumpUntilTimeout,
  Duration step = kPumpStep,
}) async {
  if (condition()) {
    return true;
  }

  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.pump(step);
    elapsed += step;
    if (condition()) {
      return true;
    }
  }
  return false;
}

/// Pumps until [finder] matches at least one widget.
Future<bool> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = kPumpUntilTimeout,
  Duration step = kPumpStep,
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    timeout: timeout,
    step: step,
  );
}

/// Pumps until [finder] matches exactly one widget.
///
/// Cupertino route transitions temporarily render a second copy of the
/// navigation bar so its contents can be animated between routes. Tapping
/// during that window fails with an "ambiguously found multiple matching
/// widgets" error, so tests must wait for the transition to finish before
/// interacting with navigation bar items.
Future<bool> pumpUntilExactlyOne(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = kPumpUntilTimeout,
  Duration step = kPumpStep,
}) {
  return pumpUntil(
    tester,
    () => finder.evaluate().length == 1,
    timeout: timeout,
    step: step,
  );
}

/// Waits for [finder] to resolve to exactly one widget and taps it.
///
/// This is the safe replacement for `await tester.tap(find.text('Save'))`
/// directly after a navigation, where the target may still be duplicated by an
/// in-flight route transition.
Future<void> tapWhenUnambiguous(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = kPumpUntilTimeout,
  Duration step = kPumpStep,
}) async {
  final settled = await pumpUntilExactlyOne(
    tester,
    finder,
    timeout: timeout,
    step: step,
  );
  expect(
    settled,
    isTrue,
    reason:
        'Expected exactly one widget for $finder within $timeout, '
        'found ${finder.evaluate().length}',
  );
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(kPumpStep);
}

/// Pumps enough frames for a pushed or popped route to finish animating.
///
/// Cupertino page transitions run for well under a second; the extra budget
/// covers the post-frame callbacks the screens use to load their data.
Future<void> settleRouteTransition(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 800),
  Duration step = kPumpStep,
}) async {
  var elapsed = Duration.zero;
  while (elapsed < duration) {
    await tester.pump(step);
    elapsed += step;
  }
}

/// The real-time slice granted per iteration of [pumpUntilAsync].
const Duration kRealAsyncStep = Duration(milliseconds: 20);

/// Pumps until [condition] holds, while letting *real* asynchronous work make
/// progress between frames.
///
/// `testWidgets` runs its body inside a `FakeAsync` zone, where only timers
/// driven by [WidgetTester.pump] advance. Anything backed by the real event
/// loop — drift queries against `NativeDatabase`, keychain calls, platform
/// channels — never completes there, so a screen that saves to the database
/// simply stalls and the test observes nothing happening.
///
/// [WidgetTester.runAsync] steps outside the fake zone and lets that work run.
/// Interleaving it with [WidgetTester.pump] gives both the widget animations
/// and the real futures a chance to progress.
///
/// Use this instead of [pumpUntil] whenever the awaited effect crosses the
/// database, the keychain or a platform channel.
Future<bool> pumpUntilAsync(
  WidgetTester tester,
  bool Function() condition, {
  Duration timeout = kPumpUntilTimeout,
  Duration step = kRealAsyncStep,
}) async {
  if (condition()) {
    return true;
  }

  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.runAsync(() => Future<void>.delayed(step));
    await tester.pump(step);
    elapsed += step;
    if (condition()) {
      return true;
    }
  }
  return false;
}

/// Runs [action] outside the `FakeAsync` zone and pumps a frame afterwards.
///
/// Wrap every direct database access made from inside a `testWidgets` body in
/// this, otherwise the returned future never completes.
Future<T?> runRealAsync<T>(
  WidgetTester tester,
  Future<T> Function() action,
) async {
  final result = await tester.runAsync(action);
  await tester.pump();
  return result;
}
