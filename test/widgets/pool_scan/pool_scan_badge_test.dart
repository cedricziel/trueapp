import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool_scan.dart';
import 'package:truehub/widgets/pool_scan/pool_scan_badge.dart';
import 'package:truehub/widgets/usage_bar.dart';

import '../../helpers/layout_assertions.dart';
import '../../helpers/pool_scan_fixtures.dart';

void main() {
  Widget wrap(PoolScan scan) => CupertinoApp(
    home: Center(
      child: SizedBox(width: 200, child: PoolScanBadge(scan: scan)),
    ),
  );

  testWidgets('shows a running scrub with its percent and a progress bar', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(poolScan(percentage: 42.0)));

    expect(find.text('Scrubbing 42%'), findsOneWidget);
    expect(find.byType(UsageBar), findsOneWidget);
    expectNoLayoutOverflow(tester);
  });

  testWidgets('shows a running resilver', (tester) async {
    await tester.pumpWidget(
      wrap(poolScan(function: 'RESILVER', percentage: 7.0)),
    );

    expect(find.text('Resilvering 7%'), findsOneWidget);
  });

  testWidgets('says so when the scan is paused', (tester) async {
    await tester.pumpWidget(
      wrap(poolScan(percentage: 42.0, pause: truenasDate(poolScanStart))),
    );

    expect(find.text('Scrub paused 42%'), findsOneWidget);
  });

  testWidgets('omits the percent when progress is unknown', (tester) async {
    await tester.pumpWidget(
      wrap(poolScan(percentage: null, bytesIssued: null)),
    );

    expect(find.text('Scrubbing'), findsOneWidget);
    expect(find.byType(UsageBar), findsNothing);
  });

  testWidgets('renders nothing once the scan is no longer running', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(poolScan(state: 'FINISHED')));

    expect(find.byType(UsageBar), findsNothing);
    expect(find.textContaining('Scrub'), findsNothing);
  });
}
