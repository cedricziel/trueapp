import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/refreshable_scroll_view.dart';
import '../helpers/pump_helpers.dart';

void main() {
  Widget host(Widget child) => CupertinoApp(home: child);

  testWidgets('pulling down a list invokes onRefresh once', (tester) async {
    var refreshes = 0;
    await tester.pumpWidget(
      host(
        RefreshableScrollView.list(
          onRefresh: () async => refreshes++,
          children: const [Text('first'), Text('second')],
        ),
      ),
    );

    await pullToRefresh(tester);

    expect(refreshes, 1);
    expect(find.text('first'), findsOneWidget);
  });

  testWidgets('pulling down a builder list invokes onRefresh', (tester) async {
    var refreshes = 0;
    await tester.pumpWidget(
      host(
        RefreshableScrollView.builder(
          onRefresh: () async => refreshes++,
          itemCount: 3,
          itemBuilder: (context, index) => Text('item $index'),
        ),
      ),
    );

    await pullToRefresh(tester);

    expect(refreshes, 1);
    expect(find.text('item 2'), findsOneWidget);
  });

  testWidgets('pulling down a separated list invokes onRefresh', (
    tester,
  ) async {
    var refreshes = 0;
    await tester.pumpWidget(
      host(
        RefreshableScrollView.separated(
          onRefresh: () async => refreshes++,
          itemCount: 2,
          itemBuilder: (context, index) => Text('item $index'),
          separatorBuilder: (context, index) => const Text('---'),
        ),
      ),
    );

    await pullToRefresh(tester);

    expect(refreshes, 1);
    expect(find.text('---'), findsOneWidget);
  });

  testWidgets('short content is still pullable', (tester) async {
    var refreshes = 0;
    await tester.pumpWidget(
      host(
        RefreshableScrollView.list(
          onRefresh: () async => refreshes++,
          children: const [Text('only')],
        ),
      ),
    );

    await pullToRefresh(tester);

    expect(refreshes, 1);
  });

  testWidgets('a failing refresh does not throw out of the gesture', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        RefreshableScrollView.list(
          onRefresh: () async => throw StateError('offline'),
          children: const [Text('only')],
        ),
      ),
    );

    await pullToRefresh(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('only'), findsOneWidget);
  });
}
