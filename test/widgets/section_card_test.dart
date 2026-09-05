import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/section_card.dart';

void main() {
  Widget wrap(Widget child) {
    return CupertinoApp(home: Center(child: child));
  }

  group('SectionCard', () {
    testWidgets('renders its title, icon, and children', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SectionCard(
            title: 'Pool Information',
            icon: CupertinoIcons.square_stack_3d_down_right,
            children: [Text('child row')],
          ),
        ),
      );

      expect(find.text('Pool Information'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.square_stack_3d_down_right),
        findsOneWidget,
      );
      expect(find.text('child row'), findsOneWidget);
    });

    testWidgets('defaults its icon to activeBlue and allows overriding it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SectionCard(
            title: 'Default',
            icon: CupertinoIcons.info_circle,
            children: [],
          ),
        ),
      );
      final defaultIcon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.info_circle),
      );
      expect(defaultIcon.color, CupertinoColors.activeBlue);

      await tester.pumpWidget(
        wrap(
          const SectionCard(
            title: 'Degraded',
            icon: CupertinoIcons.info_circle,
            iconColor: CupertinoColors.systemRed,
            children: [],
          ),
        ),
      );
      final overriddenIcon = tester.widget<Icon>(
        find.byIcon(CupertinoIcons.info_circle),
      );
      expect(overriddenIcon.color, CupertinoColors.systemRed);
    });
  });

  group('InfoRow', () {
    testWidgets('renders its label and value', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(const InfoRow('Status', 'ONLINE')));

      expect(find.text('Status'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('applies a custom value color when given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const InfoRow(
            'Administrator',
            'Yes',
            valueColor: CupertinoColors.systemOrange,
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('Yes'));
      expect(valueText.style?.color, CupertinoColors.systemOrange);
    });
  });

  group('StatusPill', () {
    testWidgets('renders its label in the given color', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusPill(
            label: 'Administrator',
            color: CupertinoColors.systemOrange,
            icon: CupertinoIcons.star_fill,
          ),
        ),
      );

      expect(find.text('Administrator'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.star_fill), findsOneWidget);
      final labelText = tester.widget<Text>(find.text('Administrator'));
      expect(labelText.style?.color, CupertinoColors.systemOrange);
    });

    testWidgets('omits the icon when none is given', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusPill(
            label: 'Installed',
            color: CupertinoColors.systemGreen,
          ),
        ),
      );

      expect(find.text('Installed'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
