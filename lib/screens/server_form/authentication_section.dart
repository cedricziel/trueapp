import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AuthenticationSection extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final String passwordPlaceholder;
  final VoidCallback onChanged;

  const AuthenticationSection({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.onChanged,
    this.passwordPlaceholder = 'Password',
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoFormSection(
      header: const Text('AUTHENTICATION'),
      children: [
        CupertinoTextFormFieldRow(
          controller: usernameController,
          placeholder: 'admin',
          prefix: const Text('Username'),
          autocorrect: false,
          keyboardType: TextInputType.text,
          autofillHints: const [AutofillHints.username],
          onChanged: (_) => onChanged(),
        ),
        CupertinoTextFormFieldRow(
          controller: passwordController,
          placeholder: passwordPlaceholder,
          prefix: const Text('Password'),
          obscureText: true,
          autocorrect: false,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => onChanged(),
          onEditingComplete: () {
            // Trigger save password prompt on iOS
            TextInput.finishAutofillContext();
          },
        ),
      ],
    );
  }
}
