import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/file_item.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/file_provider.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';

class ServerFilesScreen extends StatefulWidget {
  final NasServer server;

  const ServerFilesScreen({super.key, required this.server});

  @override
  State<ServerFilesScreen> createState() => _ServerFilesScreenState();
}

class _ServerFilesScreenState extends State<ServerFilesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fileProvider = context.read<FileProvider>();
      await fileProvider.setApiClient(widget.server);
      await fileProvider.loadFiles('/');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Files'),
        previousPageTitle: widget.server.name,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JobsBellButton(server: widget.server),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: () => context.read<FileProvider>().refreshFiles(),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<FileProvider>(
          builder: (context, provider, child) {
            return Column(
              children: [
                _buildBreadcrumbs(provider),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: 'Search this folder',
                    onChanged: provider.setSearchQuery,
                  ),
                ),
                Expanded(child: _buildBody(provider)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(FileProvider provider) {
    final segments = provider.currentPath
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList();

    return SizedBox(
      height: 32,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildBreadcrumb(
            'Home',
            '/',
            isCurrent: segments.isEmpty,
            onTap: () => provider.navigateToPath('/'),
          ),
          for (var i = 0; i < segments.length; i++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                CupertinoIcons.chevron_right,
                size: 12,
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
            _buildBreadcrumb(
              segments[i],
              '/${segments.sublist(0, i + 1).join('/')}',
              isCurrent: i == segments.length - 1,
              onTap: () => provider.navigateToPath(
                '/${segments.sublist(0, i + 1).join('/')}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(
    String label,
    String path, {
    required bool isCurrent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent
                ? CupertinoColors.label
                : CupertinoColors.activeBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FileProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (provider.error != null) {
      return ErrorStateWidget(
        title: 'Could Not Load Files',
        message: provider.error!,
        onRetry: () => provider.refreshFiles(),
      );
    }

    final files = provider.filteredFiles;

    if (files.isEmpty) {
      return EmptyStateWidget(
        icon: CupertinoIcons.folder,
        title: provider.searchQuery.isEmpty ? 'Empty Folder' : 'No Matches',
        message: provider.searchQuery.isEmpty
            ? 'This folder has no files or subfolders'
            : 'No files match "${provider.searchQuery}"',
      );
    }

    final sorted = [...files]
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

    return ListView.separated(
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(left: 56),
        child: SizedBox(
          height: 0.5,
          child: ColoredBox(color: CupertinoColors.separator),
        ),
      ),
      itemBuilder: (context, index) {
        final file = sorted[index];
        return _buildFileRow(provider, file);
      },
    );
  }

  Widget _buildFileRow(FileProvider provider, FileItem file) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onPressed: file.isDirectory
          ? () => provider.navigateToPath(file.path)
          : null,
      child: Row(
        children: [
          Icon(_iconFor(file), size: 26, color: _iconColorFor(file)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleFor(file),
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          if (file.isDirectory)
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: CupertinoColors.tertiaryLabel,
            ),
        ],
      ),
    );
  }

  String _subtitleFor(FileItem file) {
    final modified = _formatModified(file.modifiedTime);
    if (file.isDirectory) return 'Folder · $modified';
    return '${file.formattedSize} · $modified';
  }

  String _formatModified(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    return 'Just now';
  }

  IconData _iconFor(FileItem file) {
    if (file.isDirectory) return CupertinoIcons.folder_fill;
    final mimeType = file.mimeType ?? '';
    if (mimeType.startsWith('image/')) return CupertinoIcons.photo_fill;
    if (mimeType.startsWith('video/')) return CupertinoIcons.film_fill;
    if (mimeType.startsWith('audio/')) return CupertinoIcons.music_note;
    if (mimeType.startsWith('text/')) return CupertinoIcons.doc_text_fill;
    return CupertinoIcons.doc_fill;
  }

  Color _iconColorFor(FileItem file) {
    if (file.isDirectory) return CupertinoColors.activeBlue;
    final mimeType = file.mimeType ?? '';
    if (mimeType.startsWith('image/')) return CupertinoColors.systemPurple;
    if (mimeType.startsWith('video/')) return CupertinoColors.systemGreen;
    if (mimeType.startsWith('audio/')) return CupertinoColors.systemOrange;
    return CupertinoColors.systemGrey;
  }
}
