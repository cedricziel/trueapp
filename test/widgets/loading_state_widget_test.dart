import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/loading_state_widget.dart';

void main() {
  group('LoadingStateWidget', () {
    testWidgets('shows an activity indicator with no message by default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(home: LoadingStateWidget()),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('shows the message when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: LoadingStateWidget(message: 'Loading pools...'),
        ),
      );

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Loading pools...'), findsOneWidget);
    });
  });
}
