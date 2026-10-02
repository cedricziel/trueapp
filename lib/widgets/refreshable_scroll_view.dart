import 'package:flutter/cupertino.dart';

/// A vertical scroll view with the iOS pull-to-refresh control.
///
/// Always scrollable and bouncing so the gesture also works when the content
/// is shorter than the viewport, and on platforms whose default physics don't
/// overscroll.
class RefreshableScrollView extends StatelessWidget {
  const RefreshableScrollView({
    super.key,
    required this.onRefresh,
    required this.slivers,
  });

  /// A refreshable list with a fixed set of [children].
  factory RefreshableScrollView.list({
    Key? key,
    required Future<void> Function() onRefresh,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required List<Widget> children,
  }) => RefreshableScrollView(
    key: key,
    onRefresh: onRefresh,
    slivers: [
      SliverPadding(
        padding: padding,
        sliver: SliverList(delegate: SliverChildListDelegate(children)),
      ),
    ],
  );

  /// A refreshable list whose items are built lazily.
  factory RefreshableScrollView.builder({
    Key? key,
    required Future<void> Function() onRefresh,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
  }) => RefreshableScrollView(
    key: key,
    onRefresh: onRefresh,
    slivers: [
      SliverPadding(
        padding: padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            itemBuilder,
            childCount: itemCount,
          ),
        ),
      ),
    ],
  );

  final Future<void> Function() onRefresh;
  final List<Widget> slivers;

  // Providers surface their own errors; an exception escaping here would
  // leave the spinner stuck.
  Future<void> _refresh() async {
    try {
      await onRefresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: _refresh),
        ...slivers,
      ],
    );
  }
}
