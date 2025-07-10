// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/main.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    // Create a fresh test database for each test using in-memory SQLite
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    // Clean up after each test
    await database.close();
  });

  testWidgets('TrueNAS Manager app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppDatabase>.value(value: database),
          ChangeNotifierProvider(create: (context) => ServerProvider(database)),
        ],
        child: const TrueNASManagerApp(),
      ),
    );

    // Verify that the app renders the home screen
    expect(find.text('TrueNAS Manager'), findsOneWidget);
  });
}
