import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/services/authentication_session_service.dart';
import 'package:truehub/widgets/session_indicator_widget.dart';
import '../helpers/layout_assertions.dart';

void main() {
  // AuthenticationSessionService is a process-wide singleton, so every test
  // must leave it invalidated - otherwise state leaks into the next test in
  // this file (and, if the isolate is reused, beyond it).
  tearDown(() {
    AuthenticationSessionService.instance.invalidateSession();
  });

  Widget wrap(Widget child) {
    return CupertinoApp(home: Center(child: child));
  }

  group('SessionIndicatorWidget', () {
    testWidgets('renders nothing when there is no active session', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(wrap(const SessionIndicatorWidget()));

      expect(find.byType(SessionIndicatorWidget), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.lock_open), findsNothing);
      expectNoLayoutOverflow(tester);

      // Unmount so the widget's periodic refresh timer is cancelled before
      // the test ends.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'shows the unlocked icon and a countdown once a session is active',
      (WidgetTester tester) async {
        AuthenticationSessionService.instance.markAuthenticated();

        await tester.pumpWidget(wrap(const SessionIndicatorWidget()));

        expect(find.byIcon(CupertinoIcons.lock_open), findsOneWidget);
        // A fresh 30-minute session is comfortably over the 5-minute
        // warning threshold, so the icon renders green.
        final icon = tester.widget<Icon>(find.byIcon(CupertinoIcons.lock_open));
        expect(icon.color, CupertinoColors.systemGreen);

        // kDebugMode is true under `flutter test`, so the mm:ss countdown is
        // also rendered.
        expect(find.textContaining(RegExp(r'^\d+:\d{2}$')), findsOneWidget);
        expectNoLayoutOverflow(tester);

        await tester.pumpWidget(const SizedBox());
        // AuthenticationSessionService.markAuthenticated schedules its own
        // 30-minute expiry Timer independent of the widget's lifecycle, so
        // unmounting the widget above is not enough to clear it - the
        // binding's end-of-test pending-timer check runs before tearDown, so
        // this has to happen here rather than there.
        AuthenticationSessionService.instance.invalidateSession();
      },
    );

    testWidgets('tapping opens the session dialog with a Lock Now action while '
        'the session is active', (WidgetTester tester) async {
      AuthenticationSessionService.instance.markAuthenticated();

      await tester.pumpWidget(wrap(const SessionIndicatorWidget()));
      await tester.tap(find.byType(CupertinoButton));
      await tester.pump();

      expect(find.text('Authentication Session'), findsOneWidget);
      expect(find.textContaining('Session is active'), findsOneWidget);
      expect(find.text('Lock Now'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      AuthenticationSessionService.instance.invalidateSession();
    });

    testWidgets(
      'tapping Lock Now invalidates the session and dismisses the dialog',
      (WidgetTester tester) async {
        AuthenticationSessionService.instance.markAuthenticated();

        await tester.pumpWidget(wrap(const SessionIndicatorWidget()));
        await tester.tap(find.byType(CupertinoButton));
        await tester.pump();

        await tester.tap(find.text('Lock Now'));
        await tester.pump();

        expect(find.text('Authentication Session'), findsNothing);
        expect(AuthenticationSessionService.instance.isSessionValid, isFalse);
        // The widget rebuilds and hides itself once the session is gone.
        expect(find.byIcon(CupertinoIcons.lock_open), findsNothing);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('tapping OK dismisses the dialog and keeps the session', (
      WidgetTester tester,
    ) async {
      AuthenticationSessionService.instance.markAuthenticated();

      await tester.pumpWidget(wrap(const SessionIndicatorWidget()));
      await tester.tap(find.byType(CupertinoButton));
      await tester.pump();

      await tester.tap(find.text('OK'));
      await tester.pump();

      expect(find.text('Authentication Session'), findsNothing);
      expect(AuthenticationSessionService.instance.isSessionValid, isTrue);
      expect(find.byIcon(CupertinoIcons.lock_open), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      AuthenticationSessionService.instance.invalidateSession();
    });
  });
}
