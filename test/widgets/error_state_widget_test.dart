import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/error_state_widget.dart';

void main() {
  group('ErrorStateWidget', () {
    testWidgets('displays error message correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: ErrorStateWidget(
            title: 'Error',
            message: 'Failed to load data',
          ),
        ),
      );

      expect(find.text('Failed to load data'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );
    });

    testWidgets('displays custom icon when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: ErrorStateWidget(
            title: 'Network Error',
            message: 'Network error',
            icon: CupertinoIcons.wifi_slash,
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.wifi_slash), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsNothing,
      );
    });
  });
}
