import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/screens/app_detail/app_detail_actions.dart';
import 'package:truehub/screens/app_detail/app_sources_section.dart';

import '../../helpers/fake_url_opener.dart';

App _app({required bool installed, String? home}) => App(
  name: 'plex',
  title: 'Plex',
  description: '',
  installed: installed,
  healthy: true,
  latestVersion: '1.0.0',
  latestAppVersion: '1.0.0',
  latestHumanVersion: '1.0.0',
  categories: const [],
  home: home,
  tags: const [],
  screenshots: const [],
  sources: const [],
  maintainers: const [],
  recommended: false,
  catalog: 'community',
  train: 'stable',
  usedPorts: const [],
  portals: const {},
);

void main() {
  late FakeUrlOpener opener;

  setUp(() => opener = FakeUrlOpener());

  testWidgets('tapping a source opens its URL', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: AppSourcesSection(
          sources: const ['https://github.com/example/plex', 'https://b.test'],
          urlOpener: opener,
        ),
      ),
    );

    await tester.tap(find.text('https://b.test'));

    expect(opener.opened, ['https://b.test']);
  });

  testWidgets('View Homepage opens the app home URL', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: AppDetailActions(
          app: _app(installed: true, home: 'https://plex.tv'),
          urlOpener: opener,
        ),
      ),
    );

    await tester.tap(find.text('View Homepage'));

    expect(opener.opened, ['https://plex.tv']);
  });

  testWidgets('has no install or manage button that does nothing', (
    tester,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: AppDetailActions(
          app: _app(installed: false, home: 'https://plex.tv'),
          urlOpener: opener,
        ),
      ),
    );

    expect(find.text('Install App'), findsNothing);
    expect(find.text('Manage App'), findsNothing);
  });
}
