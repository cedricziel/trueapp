import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/form_row_label.dart';
import '../helpers/layout_assertions.dart';
import '../helpers/test_surfaces.dart';

/// Regression coverage for the duplicated `Flexible(child: Column(title,
/// subtitle))` prefix that used to be written out four times in
/// `settings_screen.dart` (once per `CupertinoFormRow`). [FormRowLabel]
/// makes the fix a single reusable widget instead, so the next row added to
/// SettingsScreen gets it for free.
void main() {
  Widget wrapCompact(WidgetTester tester, Widget prefix, Widget trailing) {
    useCompactSurface(tester);
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: CupertinoFormSection(
          children: [CupertinoFormRow(prefix: prefix, child: trailing)],
        ),
      ),
    );
  }

  testWidgets('renders a title and subtitle beside a trailing control without '
      'overflowing a compact (390pt) row', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrapCompact(
        tester,
        const FormRowLabel(
          title: 'Authentication Session',
          subtitle: 'Manage biometric authentication session',
        ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {},
          child: const Text('Unlock Session'),
        ),
      ),
    );

    expectNoLayoutOverflow(tester);
    expect(find.text('Authentication Session'), findsOneWidget);
    expect(
      find.text('Manage biometric authentication session'),
      findsOneWidget,
    );
    expect(find.text('Unlock Session'), findsOneWidget);
  });
}
