import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/widgets/empty_state_widget.dart';

void main() {
  group('EmptyStateWidget', () {
    testWidgets('displays message and icon correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: EmptyStateWidget(
            icon: CupertinoIcons.app,
            message: 'No apps found',
          ),
        ),
      );

      expect(find.text('No apps found'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.app), findsOneWidget);
    });

    testWidgets('displays different icons correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: EmptyStateWidget(
            icon: CupertinoIcons.square_stack_3d_down_right,
            message: 'No storage pools found',
          ),
        ),
      );

      expect(find.text('No storage pools found'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
        findsOneWidget,
      );
    });
  });
}
