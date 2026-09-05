import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/trend_sparkline.dart';

void main() {
  Widget wrap(Widget child) {
    return CupertinoApp(
      home: Center(child: SizedBox(width: 260, height: 40, child: child)),
    );
  }

  testWidgets('renders without error for an empty history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(const TrendSparkline(values: [], color: CupertinoColors.systemBlue)),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without error for a single sample', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const TrendSparkline(values: [42], color: CupertinoColors.systemBlue),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without error for a flat (zero-range) history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const TrendSparkline(
          values: [50, 50, 50, 50],
          color: CupertinoColors.systemGreen,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without error for varying history', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const TrendSparkline(
          values: [10, 45, 20, 80, 33, 60],
          color: CupertinoColors.systemOrange,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
