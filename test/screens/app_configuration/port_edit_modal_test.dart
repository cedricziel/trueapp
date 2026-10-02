import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app_config.dart';
import 'package:truehub/screens/app_configuration/port_edit_modal.dart';

void main() {
  Future<void> pumpModal(
    WidgetTester tester, {
    required ValueChanged<AppPortConfig> onSave,
    VoidCallback? onDelete,
    VoidCallback? onSetPrimary,
    bool isNewPort = false,
  }) {
    return tester.pumpWidget(
      CupertinoApp(
        home: PortEditModal(
          port: const AppPortConfig(portNumber: 80),
          onSave: onSave,
          onDelete: onDelete,
          onSetPrimary: onSetPrimary,
          isNewPort: isNewPort,
        ),
      ),
    );
  }

  testWidgets('saves the edited port number and protocol', (tester) async {
    AppPortConfig? saved;
    await pumpModal(
      tester,
      onSave: (port) => saved = port,
      onSetPrimary: () {},
    );

    await tester.enterText(find.byType(CupertinoTextField).first, '8443');
    await tester.tap(find.text('HTTPS'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(saved?.portNumber, 8443);
    expect(saved?.protocol, 'https');
  });

  testWidgets('does not save when the port number is empty', (tester) async {
    AppPortConfig? saved;
    await pumpModal(
      tester,
      onSave: (port) => saved = port,
      onSetPrimary: () {},
    );

    await tester.enterText(find.byType(CupertinoTextField).first, '');
    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(saved, isNull);
  });

  testWidgets('hides primary and delete actions for a new port', (
    tester,
  ) async {
    await pumpModal(
      tester,
      onSave: (_) {},
      onDelete: () {},
      onSetPrimary: () {},
      isNewPort: true,
    );

    expect(find.text('Add Port'), findsOneWidget);
    expect(find.text('Set as Primary'), findsNothing);
    expect(find.text('Delete Port'), findsNothing);
  });

  testWidgets('invokes the delete callback for an existing port', (
    tester,
  ) async {
    var deleted = false;
    await pumpModal(
      tester,
      onSave: (_) {},
      onDelete: () => deleted = true,
      onSetPrimary: () {},
    );

    await tester.ensureVisible(find.text('Delete Port'));
    await tester.tap(find.text('Delete Port'));
    await tester.pump();

    expect(deleted, isTrue);
  });

  testWidgets('builds an existing port with no actions available', (
    tester,
  ) async {
    await pumpModal(tester, onSave: (_) {});

    expect(tester.takeException(), isNull);
    expect(find.text('Set as Primary'), findsNothing);
    expect(find.text('Delete Port'), findsNothing);
  });
}
