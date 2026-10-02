import 'package:flutter/cupertino.dart';
import 'package:truehub/screens/app_detail/open_link.dart';
import 'package:truehub/services/url_opener.dart';

class AppSourcesSection extends StatelessWidget {
  final List<String> sources;
  final UrlOpener urlOpener;

  const AppSourcesSection({
    super.key,
    required this.sources,
    this.urlOpener = const UrlLauncherOpener(),
  });

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
          (source) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: isWebUrl(source)
                ? _SourceLink(
                    source: source,
                    onTap: () => openLinkOrAlert(context, urlOpener, source),
                  )
                : _SourceText(source: source),
          ),
        ),
      ],
    );
  }
}

class _SourceLink extends StatelessWidget {
  final String source;
  final VoidCallback onTap;

  const _SourceLink({required this.source, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
    );
  }
}

class _SourceText extends StatelessWidget {
  final String source;

  const _SourceText({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        source,
        style: TextStyle(
          fontSize: 14,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    );
  }
}
