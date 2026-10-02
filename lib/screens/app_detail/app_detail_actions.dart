import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/services/url_opener.dart';

class AppDetailActions extends StatelessWidget {
  final App app;
  final UrlOpener urlOpener;

  const AppDetailActions({
    super.key,
    required this.app,
    this.urlOpener = const UrlLauncherOpener(),
  });

  @override
  Widget build(BuildContext context) {
    final home = app.home;
    if (home == null || home.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        child: const Text('View Homepage'),
        onPressed: () => urlOpener.open(home),
      ),
    );
  }
}
