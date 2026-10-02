import 'package:flutter/cupertino.dart';
import 'package:truehub/models/app.dart';

class AppDescriptionSection extends StatelessWidget {
  final App app;

  const AppDescriptionSection({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final readme = app.appReadme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          app.description,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        if (readme != null && readme.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _ReadmeContent(readme: readme),
        ],
      ],
    );
  }
}

class _ReadmeContent extends StatelessWidget {
  final String readme;

  const _ReadmeContent({required this.readme});

  @override
  Widget build(BuildContext context) {
    // Remove HTML tags for now (in a real app, you'd use a proper HTML renderer)
    final content = readme
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
    );
  }
}
