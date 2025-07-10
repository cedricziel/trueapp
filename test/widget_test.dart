// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:truenas_manager/main.dart';
import 'package:truenas_manager/providers/server_provider.dart';
import 'package:truenas_manager/services/database.dart';

void main() {
  testWidgets('TrueNAS Manager app smoke test', (WidgetTester tester) async {
    // Create a test database
    final database = AppDatabase();
    
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
    
    // Clean up
    await database.close();
  });
}
