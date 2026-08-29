import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/section_header.dart';
import '../helpers/layout_assertions.dart';

void main() {
  Widget wrapNarrow(Widget child) {
    return CupertinoApp(
      home: Center(child: SizedBox(width: 320, child: child)),
    );
  }

  testWidgets(
    'renders a title and a trailing action without overflowing a narrow row',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapNarrow(
          SectionHeader(
            title: 'Storage Pools',
            action: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {},
              child: const Text('View All'),
            ),
          ),
        ),
      );

      expectNoLayoutOverflow(tester);
      expect(find.text('Storage Pools'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
    },
  );

  testWidgets('ellipsizes a title too long for the available width', (
    WidgetTester tester,
  ) async {
    const longTitle =
        'A Section Title That Is Far Too Long For This Narrow Row';

    await tester.pumpWidget(
      wrapNarrow(
        SectionHeader(
          title: longTitle,
          action: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Text('View All'),
          ),
        ),
      ),
    );

    expectNoLayoutOverflow(tester);
    final text = tester.widget<Text>(find.text(longTitle));
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.maxLines, 1);
  });
}
