import 'package:flutter/cupertino.dart';

/// Builds the leading widget a screen hosted inside the app's shell route
/// should show in its own [CupertinoNavigationBar].
///
/// Ticket #85: `HomeScreen` used to reach server detail with `context.go`,
/// which replaces the whole route stack rather than pushing onto it, so
/// there was nothing to pop back to - the detail screen (and everything
/// reachable from it) stranded the user with no way back to the server
/// list. Now that the list uses `context.push`, [maybeBuild] hands back a
/// back button whenever the enclosing navigator actually has somewhere to
/// pop to, and `null` - Cupertino's default of no leading widget - when it
/// does not, which is exactly the cold-start / deep-link case where there
/// is nothing to go back to.
abstract final class ShellNavigationLeading {
  /// Returns a back button if [context]'s route can pop, or `null`
  /// otherwise. Pass [previousPageTitle] to caption it with the screen
  /// being returned to.
  static Widget? maybeBuild(BuildContext context, {String? previousPageTitle}) {
    if (ModalRoute.of(context)?.canPop ?? false) {
      return ShellBackButton(previousPageTitle: previousPageTitle);
    }
    return null;
  }
}

/// A back button for a shell-hosted screen's navigation bar.
///
/// This deliberately does not use Cupertino's own
/// `CupertinoNavigationBarBackButton`: that widget asserts
/// `ModalRoute.of(context)?.canPop` internally, and Cupertino's page
/// transition briefly renders a second, transitional copy of the outgoing
/// navigation bar's `leading` widget in a context where that check reports
/// `false` even though the check [ShellNavigationLeading.maybeBuild] made a
/// moment earlier - on the "real" copy - was `true`. That transient
/// mismatch crashes the frame. Every other back button already in this
/// codebase (`ServerPoolsScreen`, `EditServerScreen`, ...) sidesteps the
/// same hazard the same way: a plain [CupertinoButton] that calls
/// `Navigator.pop` directly instead of asserting on the route it is built
/// in.
class ShellBackButton extends StatelessWidget {
  const ShellBackButton({super.key, this.previousPageTitle});

  final String? previousPageTitle;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => Navigator.maybePop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(CupertinoIcons.back),
          if (previousPageTitle != null) Text(previousPageTitle!),
        ],
      ),
    );
  }
}
