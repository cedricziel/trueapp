import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';

class AppMetadataSection extends StatelessWidget {
  final App app;

  const AppMetadataSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Information',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey6.resolveFrom(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _InfoRow(label: 'Category', value: app.categories.join(', ')),
              if (app.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _InfoRow(label: 'Tags', value: app.tags.join(', ')),
              ],
              const SizedBox(height: 12),
              _InfoRow(label: 'Catalog', value: app.catalog),
              const SizedBox(height: 12),
              _InfoRow(label: 'Train', value: app.train),
              if (app.lastUpdate != null) ...[
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Last Updated',
                  value: _formatDate(app.lastUpdate!),
                ),
              ],
              if (app.installed &&
                  !app.healthy &&
                  app.healthyError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.exclamationmark_triangle_fill,
                        size: 16,
                        color: CupertinoColors.systemRed,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          app.healthyError!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${difference.inDays > 730 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${difference.inDays > 60 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Recently';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey.resolveFrom(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not specified' : value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
