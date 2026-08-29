import 'package:flutter/widgets.dart';

/// Notifies when the app returns to the foreground.
///
/// No timer runs while the process is suspended, so a connection torn down by
/// the OS in the background goes unnoticed until something asks for it. This
/// widget provides that trigger: wrap the app once and recover the connection
/// in [onResumed].
class AppLifecycleReconnector extends StatefulWidget {
  const AppLifecycleReconnector({
    super.key,
    required this.onResumed,
    required this.child,
  });

  /// Called on every transition back to [AppLifecycleState.resumed].
  final VoidCallback onResumed;

  final Widget child;

  @override
  State<AppLifecycleReconnector> createState() =>
      _AppLifecycleReconnectorState();
}

class _AppLifecycleReconnectorState extends State<AppLifecycleReconnector>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      widget.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
