import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truenas_manager/widgets/storage_metric_widget.dart';

void main() {
  group('StorageMetricWidget', () {
    testWidgets('displays label and value correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: StorageMetricWidget(
            label: 'Used',
            value: '10.5 GB',
            color: CupertinoColors.systemBlue,
          ),
        ),
      );

      expect(find.text('Used'), findsOneWidget);
      expect(find.text('10.5 GB'), findsOneWidget);
    });

    testWidgets('applies correct color to value text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: StorageMetricWidget(
            label: 'Available',
            value: '50.2 GB',
            color: CupertinoColors.systemGreen,
          ),
        ),
      );

      final valueText = tester.widget<Text>(find.text('50.2 GB'));
      expect(valueText.style?.color, CupertinoColors.systemGreen);
    });
  });
}