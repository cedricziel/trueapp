import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool_scan.dart';
import 'package:truehub/widgets/pool_scan/pool_scan_section.dart';
import 'package:truehub/widgets/usage_bar.dart';

import '../../helpers/layout_assertions.dart';
import '../../helpers/pool_scan_fixtures.dart';

void main() {
  final now = poolScanStart.add(const Duration(minutes: 10));
  const mib = 1024 * 1024;
  final redArgb = CupertinoColors.systemRed.color.toARGB32();

  Widget wrap(PoolScan scan) => CupertinoApp(
    home: CupertinoPageScaffold(
      child: SingleChildScrollView(
        child: Center(
          child: SizedBox(
            width: 375,
            child: PoolScanSection(scan: scan, now: now),
          ),
        ),
      ),
    ),
  );

  PoolScan runningScrub({
    Object? pause,
    Object? totalSecsLeft = 3725,
    Object? errors = 0,
  }) => poolScan(
    percentage: 42.5,
    bytesToProcess: 1000 * mib,
    // 600 MiB over the 10 minutes since the scan started => 1.0 MiB/s.
    bytesIssued: 600 * mib,
    pause: pause,
    totalSecsLeft: totalSecsLeft,
    errors: errors,
  );

  group('PoolScanSection - running', () {
    testWidgets('shows scrub type, percent, speed, time left and errors', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(runningScrub()));

      expect(find.text('Scrub'), findsOneWidget);
      expect(find.text('Scanning'), findsOneWidget);
      expect(find.text('42.5%'), findsOneWidget);
      expect(find.text('1.0MB/s'), findsOneWidget);
      expect(find.text('1h 2m'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byType(UsageBar), findsOneWidget);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('titles a resilver as such', (tester) async {
      await tester.pumpWidget(
        wrap(poolScan(function: 'RESILVER', startTime: null)),
      );

      expect(find.text('Resilver'), findsOneWidget);
    });

    testWidgets('derives time left from speed when the middleware sends none', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(runningScrub(totalSecsLeft: null)));

      // 400 MiB left at 1 MiB/s.
      expect(find.text('6m'), findsOneWidget);
    });

    testWidgets('omits speed and time left it cannot know', (tester) async {
      await tester.pumpWidget(
        wrap(
          poolScan(
            percentage: 5.0,
            bytesIssued: null,
            bytesToProcess: null,
            startTime: null,
          ),
        ),
      );

      expect(find.text('5.0%'), findsOneWidget);
      expect(find.text('Speed'), findsNothing);
      expect(find.text('Time left'), findsNothing);
    });

    testWidgets('marks a paused scan and drops the live estimates', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(runningScrub(pause: truenasDate(now))));

      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Scanning'), findsNothing);
      expect(find.text('Speed'), findsNothing);
      expect(find.text('Time left'), findsNothing);
    });

    testWidgets('highlights errors in red', (tester) async {
      await tester.pumpWidget(wrap(runningScrub(errors: 3)));

      final errors = tester.widget<Text>(find.text('3'));
      expect(errors.style!.color!.toARGB32(), redArgb);
    });
  });

  group('PoolScanSection - last completed scan', () {
    final end = DateTime(2026, 10, 1, 15, 30);

    testWidgets('shows when a finished scrub completed and how long it took', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          poolScan(
            state: 'FINISHED',
            percentage: 100.0,
            startTime: truenasDate(end.subtract(const Duration(hours: 3))),
            endTime: truenasDate(end),
          ),
        ),
      );

      expect(find.text('Last scrub'), findsOneWidget);
      expect(find.text('Completed'), findsNWidgets(2));
      expect(find.text('Oct 1, 2026 15:30'), findsOneWidget);
      expect(find.text('3h 0m'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.byType(UsageBar), findsNothing);
      expect(find.text('Speed'), findsNothing);
      expectNoLayoutOverflow(tester);
    });

    testWidgets('reports errors found by a finished scan', (tester) async {
      await tester.pumpWidget(
        wrap(
          poolScan(
            state: 'FINISHED',
            percentage: 100.0,
            endTime: truenasDate(end),
            errors: 2,
          ),
        ),
      );

      expect(
        tester.widget<Text>(find.text('2')).style!.color!.toARGB32(),
        redArgb,
      );
    });

    testWidgets('labels a canceled resilver', (tester) async {
      await tester.pumpWidget(
        wrap(
          poolScan(
            function: 'RESILVER',
            state: 'CANCELED',
            endTime: truenasDate(end),
          ),
        ),
      );

      expect(find.text('Last resilver'), findsOneWidget);
      expect(find.text('Canceled'), findsOneWidget);
      expect(find.text('Oct 1, 2026 15:30'), findsOneWidget);
    });

    testWidgets('copes with a finished scan that has no timestamps', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(poolScan(state: 'FINISHED', startTime: null)),
      );

      expect(find.text('Last scrub'), findsOneWidget);
      expect(find.text('Duration'), findsNothing);
    });
  });
}
