import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/app_lifecycle_reconnector.dart';

void main() {
  Future<void> pumpReconnector(
    WidgetTester tester,
    VoidCallback onResumed,
  ) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: AppLifecycleReconnector(
          onResumed: onResumed,
          child: const Text('content'),
        ),
      ),
    );
  }

  testWidgets('calls onResumed when the app returns to the foreground', (
    tester,
  ) async {
    var resumes = 0;
    await pumpReconnector(tester, () => resumes++);

    expect(resumes, 0, reason: 'mounting alone is not a resume');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(resumes, 0);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(resumes, 1);
  });

  testWidgets('reports every foreground transition, not just the first', (
    tester,
  ) async {
    var resumes = 0;
    await pumpReconnector(tester, () => resumes++);

    for (var i = 0; i < 3; i++) {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
    }

    expect(resumes, 3);
  });

  testWidgets('renders its child', (tester) async {
    await pumpReconnector(tester, () {});
    expect(find.text('content'), findsOneWidget);
  });
}
