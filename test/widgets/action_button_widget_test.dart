import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/widgets/action_button_widget.dart';

void main() {
  group('ActionButtonWidget', () {
    testWidgets('displays title and subtitle correctly', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        CupertinoApp(
          home: ActionButtonWidget(
            icon: CupertinoIcons.folder,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            onTap: () => tapped = true,
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.folder), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    });

    testWidgets('executes onTap callback when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        CupertinoApp(
          home: ActionButtonWidget(
            icon: CupertinoIcons.folder,
            title: 'Test Title',
            subtitle: 'Test Subtitle',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(ActionButtonWidget));
      expect(tapped, true);
    });
  });
}