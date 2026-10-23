import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/widgets/app_state_badge.dart';
import 'package:truehub/widgets/section_card.dart';

import '../helpers/app_fixtures.dart';

void main() {
  Future<StatusPill> pumpBadge(WidgetTester tester, App app) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(child: AppStateBadge(app: app)),
      ),
    );
    return tester.widget<StatusPill>(find.byType(StatusPill));
  }

  void expectColor(WidgetTester tester, Color actual, Color expected) {
    final context = tester.element(find.byType(StatusPill));
    expect(
      CupertinoDynamicColor.resolve(actual, context),
      CupertinoDynamicColor.resolve(expected, context),
    );
  }

  final expectations = {
    AppState.running: ('Running', CupertinoColors.systemGreen),
    AppState.deploying: ('Deploying', CupertinoColors.systemOrange),
    AppState.stopping: ('Stopping', CupertinoColors.systemOrange),
    AppState.stopped: ('Stopped', CupertinoColors.systemGrey),
    AppState.crashed: ('Crashed', CupertinoColors.systemRed),
    AppState.unknown: ('Installed', CupertinoColors.systemGrey),
  };

  for (final entry in expectations.entries) {
    testWidgets('shows ${entry.value.$1} for an installed ${entry.key.name} '
        'app', (tester) async {
      final pill = await pumpBadge(tester, buildTestApp(state: entry.key));

      expect(find.text(entry.value.$1), findsOneWidget);
      expectColor(tester, pill.color, entry.value.$2);
    });
  }

  testWidgets('shows a blue Available badge for catalog apps whatever the '
      'state', (tester) async {
    final pill = await pumpBadge(
      tester,
      buildTestApp(installed: false, state: AppState.running),
    );

    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Running'), findsNothing);
    expectColor(tester, pill.color, CupertinoColors.systemBlue);
  });
}
