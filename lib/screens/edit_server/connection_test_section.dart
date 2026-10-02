import 'package:flutter/cupertino.dart';

class ConnectionTestSection extends StatelessWidget {
  final bool isTesting;
  final String? result;
  final VoidCallback onTest;

  const ConnectionTestSection({
    super.key,
    required this.isTesting,
    required this.result,
    required this.onTest,
  });

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    return CupertinoFormSection(
      header: const Text('CONNECTION TEST'),
      children: [
        CupertinoFormRow(
          prefix: const Text('Test Connection'),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: !isTesting ? onTest : null,
            child: isTesting
                ? const CupertinoActivityIndicator()
                : const Text('Test'),
          ),
        ),
        if (result != null)
          CupertinoFormRow(
            prefix: const Text('Result'),
            child: Text(
              result,
              style: TextStyle(
                color: result.startsWith('Connection successful')
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
              ),
            ),
          ),
      ],
    );
  }
}
