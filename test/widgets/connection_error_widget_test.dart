import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/connection_error.dart';
import 'package:truehub/widgets/connection_error_widget.dart';
import '../helpers/layout_assertions.dart';

void main() {
  Widget wrap(Widget child, {double width = 375}) {
    return CupertinoApp(
      home: Center(
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    );
  }

  group('ConnectionErrorWidget', () {
    testWidgets('displays short message, friendly message and correct icon '
        'for each error type', (WidgetTester tester) async {
      final cases = <ConnectionError, IconData>{
        ConnectionError.networkUnreachable(): CupertinoIcons.wifi_slash,
        ConnectionError.connectionTimeout(): CupertinoIcons.time,
        ConnectionError.authenticationFailed(): CupertinoIcons.lock_slash,
        ConnectionError.invalidCredentials(): CupertinoIcons.lock_slash,
        ConnectionError.permissionDenied():
            CupertinoIcons.exclamationmark_shield,
        ConnectionError.serverError(): CupertinoIcons.exclamationmark_triangle,
        ConnectionError.unknown(): CupertinoIcons.question_circle,
      };

      for (final entry in cases.entries) {
        final error = entry.key;
        await tester.pumpWidget(wrap(ConnectionErrorWidget(error: error)));

        expect(find.text(error.shortMessage), findsOneWidget);
        expect(
          find.textContaining(error.userFriendlyMessage.split('\n').first),
          findsOneWidget,
        );
        expect(find.byIcon(entry.value), findsOneWidget);
        expectNoLayoutOverflow(tester);
      }
    });

    testWidgets('shows the retry button only when the error is retryable and a '
        'callback is supplied, and invokes it when tapped', (
      WidgetTester tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(
          ConnectionErrorWidget(
            error: ConnectionError.networkUnreachable(),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Try Again'), findsOneWidget);
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('hides the retry button when the error is not retryable', (
      WidgetTester tester,
    ) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(
          ConnectionErrorWidget(
            error: ConnectionError.invalidCredentials(),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
      expect(retried, isFalse);
    });

    testWidgets('hides the retry button when no onRetry callback is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ConnectionErrorWidget(error: ConnectionError.networkUnreachable()),
        ),
      );

      expect(find.text('Try Again'), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'shows the settings button only when a callback is supplied, and '
      'invokes it when tapped',
      (WidgetTester tester) async {
        var settingsTapped = false;

        await tester.pumpWidget(
          wrap(
            ConnectionErrorWidget(
              error: ConnectionError.serverError(),
              onSettings: () => settingsTapped = true,
            ),
          ),
        );

        expect(find.text('Check Settings'), findsOneWidget);
        await tester.tap(find.text('Check Settings'));
        await tester.pump();
        expect(settingsTapped, isTrue);
      },
    );

    testWidgets('renders with neither action button without overflowing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(ConnectionErrorWidget(error: ConnectionError.unknown())),
      );

      expect(find.text('Try Again'), findsNothing);
      expect(find.text('Check Settings'), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets(
      'shows the technical details button only when details are present, '
      'and opens a dialog with them on tap',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          wrap(
            ConnectionErrorWidget(
              error: ConnectionError.serverError(
                details: 'HTTP 500: internal error',
              ),
            ),
          ),
        );

        expect(find.text('Show Technical Details'), findsOneWidget);

        await tester.tap(find.text('Show Technical Details'));
        await tester.pump();

        expect(find.text('Technical Details'), findsOneWidget);
        expect(find.text('HTTP 500: internal error'), findsOneWidget);

        await tester.tap(find.text('Close'));
        await tester.pump();

        expect(find.text('Technical Details'), findsNothing);
      },
    );

    testWidgets('hides the technical details button when none are given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(ConnectionErrorWidget(error: ConnectionError.unknown())),
      );

      expect(find.text('Show Technical Details'), findsNothing);
    });
  });

  group('CompactConnectionErrorWidget', () {
    testWidgets('displays the short message and a fixed warning icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CompactConnectionErrorWidget(
            error: ConnectionError.connectionTimeout(),
          ),
        ),
      );

      expect(find.text('Connection timed out'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
      expectNoLayoutOverflow(tester);
    });

    testWidgets('shows a retry button only when retryable with a callback, and '
        'invokes it on tap', (WidgetTester tester) async {
      var retried = false;

      await tester.pumpWidget(
        wrap(
          CompactConnectionErrorWidget(
            error: ConnectionError.networkUnreachable(),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('hides the retry button when the error is not retryable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CompactConnectionErrorWidget(
            error: ConnectionError.permissionDenied(),
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('does not overflow at a narrow width with a long message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CompactConnectionErrorWidget(
            error: ConnectionError.serverError(),
            onRetry: () {},
          ),
          width: 320,
        ),
      );

      expectNoLayoutOverflow(tester);
    });
  });
}
