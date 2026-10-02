import 'package:flutter/cupertino.dart';

class AppSourcesSection extends StatelessWidget {
  final List<String> sources;

  const AppSourcesSection({super.key, required this.sources});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sources',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...sources.map(
          (source) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                // TODO: Open URL in browser
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.link,
                      size: 20,
                      color: CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        source,
                        style: const TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.arrow_up_right,
                      size: 16,
                      color: CupertinoColors.systemBlue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
