import 'package:flutter/cupertino.dart';

/// A titled, icon-led card used to group related label/value rows.
///
/// This is the shared shape behind the property-inspector style sections on
/// the dataset detail, pool detail, and user profile screens - previously
/// three near-identical `_buildSection` helpers with drifting fills
/// (systemBackground vs systemGrey6) and border rules. Pair with [InfoRow]
/// for the label/value rows inside it.
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.iconColor = CupertinoColors.activeBlue,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    // `Container`/`BoxDecoration`/`Icon` don't resolve a CupertinoDynamicColor
    // on their own the way native Cupertino widgets do - left unresolved, it
    // always paints its light-mode variant, so cards would stay light-colored
    // in dark mode.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoDynamicColor.resolve(
          CupertinoColors.systemGrey6,
          context,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.separator,
            context,
          ),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: CupertinoDynamicColor.resolve(iconColor, context),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

/// A fixed-label-width row for use inside a [SectionCard], so values across
/// rows in the same card line up.
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const InfoRow(this.label, this.value, {super.key, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor == null
        ? null
        : CupertinoDynamicColor.resolve(valueColor!, context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.systemGrey,
                  context,
                ),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: resolvedValueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small tinted status/badge pill: a 10%-alpha fill of [color], an
/// optional leading icon, and solid-[color] text.
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = CupertinoDynamicColor.resolve(color, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: resolvedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: resolvedColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: resolvedColor,
            ),
          ),
        ],
      ),
    );
  }
}
