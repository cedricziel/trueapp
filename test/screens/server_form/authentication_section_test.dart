import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/screens/server_form/authentication_section.dart';

import '../../helpers/form_finders.dart';

void main() {
  testWidgets('never autocorrects the username or password', (tester) async {
    final username = TextEditingController();
    final password = TextEditingController();
    addTearDown(username.dispose);
    addTearDown(password.dispose);

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AuthenticationSection(
            usernameController: username,
            passwordController: password,
            onChanged: () {},
          ),
        ),
      ),
    );

    for (final label in ['Username', 'Password']) {
      final field = tester.widget<EditableText>(formFieldWithLabel(label));
      expect(field.autocorrect, isFalse, reason: label);
    }
  });
}
