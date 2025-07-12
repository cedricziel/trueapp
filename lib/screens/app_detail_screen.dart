import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:truenas_manager/models/app.dart';
import 'package:truenas_manager/widgets/app_icon.dart';

class AppDetailScreen extends StatefulWidget {
  final App app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  int _selectedScreenshot = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.app.effectiveDisplayName),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.ellipsis),
          onPressed: () => _showAppActions(),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAppHeader(),
            const SizedBox(height: 24),
            if (widget.app.screenshots.isNotEmpty) ...[
              _buildScreenshotsSection(),
              const SizedBox(height: 24),
            ],
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            _buildMetadataSection(),
            const SizedBox(height: 24),
            if (widget.app.maintainers.isNotEmpty) ...[
              _buildMaintainersSection(),
              const SizedBox(height: 24),
            ],
            if (widget.app.sources.isNotEmpty) ...[
              _buildSourcesSection(),
              const SizedBox(height: 24),
            ],
            _buildActionButtons(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAppHeader() {
    return Row(
      children: [
        AppIcon(app: widget.app, size: 80),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.app.effectiveDisplayName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.app.latestHumanVersion.isNotEmpty
                    ? 'v${widget.app.latestHumanVersion}'
                    : 'v${widget.app.latestAppVersion}',
                style: const TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.app.installed
                      ? CupertinoColors.systemGreen.withOpacity(0.1)
                      : CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.app.installed ? 'Installed' : 'Available',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: widget.app.installed
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshotsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Screenshots',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Main screenshot display
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: CupertinoColors.systemGrey6,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.app.screenshots[_selectedScreenshot],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.photo,
                        size: 48,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Screenshot unavailable',
                        style: TextStyle(color: CupertinoColors.systemGrey),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CupertinoActivityIndicator());
              },
            ),
          ),
        ),
        if (widget.app.screenshots.length > 1) ...[
          const SizedBox(height: 12),
          // Screenshot thumbnails
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.app.screenshots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedScreenshot;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedScreenshot = index;
                    });
                  },
                  child: Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.separator,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.app.screenshots[index],
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: CupertinoColors.systemGrey6,
                            child: const Icon(
                              CupertinoIcons.photo,
                              size: 24,
                              color: CupertinoColors.systemGrey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Text(
          widget.app.description,
          style: const TextStyle(fontSize: 16, height: 1.4),
        ),
        if (widget.app.appReadme != null &&
            widget.app.appReadme!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          // Simple HTML-like text rendering
          _buildReadmeContent(),
        ],
      ],
    );
  }

  Widget _buildReadmeContent() {
    // Simple HTML to text conversion for basic formatting
    String content = widget.app.appReadme ?? '';

    // Remove HTML tags for now (in a real app, you'd use a proper HTML renderer)
    content = content.replaceAll(RegExp(r'<[^>]*>'), '');
    content = content.replaceAll('&amp;', '&');
    content = content.replaceAll('&lt;', '<');
    content = content.replaceAll('&gt;', '>');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(content, style: const TextStyle(fontSize: 14, height: 1.4)),
    );
  }

  Widget _buildMetadataSection() {
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
            color: CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Category', widget.app.categories.join(', ')),
              if (widget.app.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow('Tags', widget.app.tags.join(', ')),
              ],
              const SizedBox(height: 12),
              _buildInfoRow('Catalog', widget.app.catalog),
              const SizedBox(height: 12),
              _buildInfoRow('Train', widget.app.train),
              if (widget.app.lastUpdate != null) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Last Updated',
                  _formatDate(widget.app.lastUpdate!),
                ),
              ],
              if (widget.app.installed &&
                  !widget.app.healthy &&
                  widget.app.healthyError != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
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
                          widget.app.healthyError!,
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

  Widget _buildMaintainersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maintainers',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...widget.app.maintainers.map(
          (maintainer) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.person_circle,
                  size: 24,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        maintainer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (maintainer.email.isNotEmpty)
                        Text(
                          maintainer.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sources',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ...widget.app.sources.map(
          (source) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                if (kDebugMode) {
                  print('Open URL: $source');
                }
                // TODO: Open URL in browser
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoButton.filled(
            child: Text(widget.app.installed ? 'Manage App' : 'Install App'),
            onPressed: () {
              if (kDebugMode) {
                print(
                  '${widget.app.installed ? 'Manage' : 'Install'} app: ${widget.app.name}',
                );
              }
              // TODO: Implement app management/installation
            },
          ),
        ),
        if (widget.app.home != null && widget.app.home!.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              child: const Text('View Homepage'),
              onPressed: () {
                if (kDebugMode) {
                  print('Open homepage: ${widget.app.home}');
                }
                // TODO: Open URL in browser
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
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

  String _formatDate(DateTime date) {
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

  void _showAppActions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(widget.app.effectiveDisplayName),
        actions: [
          CupertinoActionSheetAction(
            child: Text(widget.app.installed ? 'Manage App' : 'Install App'),
            onPressed: () {
              Navigator.pop(context);
              if (kDebugMode) {
                print(
                  '${widget.app.installed ? 'Manage' : 'Install'} app: ${widget.app.name}',
                );
              }
            },
          ),
          if (widget.app.home != null && widget.app.home!.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Homepage'),
              onPressed: () {
                Navigator.pop(context);
                if (kDebugMode) {
                  print('Open homepage: ${widget.app.home}');
                }
              },
            ),
          if (widget.app.sources.isNotEmpty)
            CupertinoActionSheetAction(
              child: const Text('View Sources'),
              onPressed: () {
                Navigator.pop(context);
                // Scroll to sources section
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
