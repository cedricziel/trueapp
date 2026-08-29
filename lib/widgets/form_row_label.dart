import 'package:flutter/cupertino.dart';

/// A `CupertinoFormRow`'s `prefix`: a title paired with a lighter subtitle
/// underneath it.
///
/// `CupertinoFormRow` lays its `prefix` out with unbounded width - a bare
/// two-line `Column` (title + subtitle) prefix overflows at phone widths
/// once a trailing control (a switch, a button) also claims space in the
/// row. Wrapping the prefix in [Flexible] fixes that; this widget makes the
/// fix structural for every settings-style row instead of something each
/// new `CupertinoFormRow` has to remember to repeat - the same class of fix
/// [SectionHeader] makes structural for section header rows.
class FormRowLabel extends StatelessWidget {
  const FormRowLabel({super.key, required this.title, required this.subtitle});

  /// The row's title, e.g. "Clear Database".
  final String title;

  /// A lighter, smaller line of explanatory text under [title].
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
