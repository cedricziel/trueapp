import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';

class AppDetailActions extends StatelessWidget {
  final App app;

  const AppDetailActions({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final home = app.home;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            child: Text(app.installed ? 'Manage App' : 'Install App'),
            onPressed: () {
              // TODO: Implement app management/installation
            },
          ),
        ),
        if (home != null && home.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              child: const Text('View Homepage'),
              onPressed: () {
                // TODO: Open URL in browser
              },
            ),
          ),
        ],
      ],
    );
  }
}
