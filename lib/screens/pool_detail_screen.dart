import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/providers/dataset_provider.dart';
import 'package:truehub/screens/dataset_detail_screen.dart';
import 'package:truehub/widgets/empty_state_widget.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/loading_state_widget.dart';

class PoolDetailScreen extends StatefulWidget {
  final NasServer server;
  final Map<String, dynamic> pool;

  const PoolDetailScreen({super.key, required this.server, required this.pool});

  @override
  State<PoolDetailScreen> createState() => _PoolDetailScreenState();
}

class _PoolDetailScreenState extends State<PoolDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadDatasets();
  }

  Future<void> _loadDatasets() async {
    final datasetProvider = context.read<DatasetProvider>();
    await datasetProvider.setApiClient(widget.server);
    await datasetProvider.loadDatasets();
  }

  @override
  Widget build(BuildContext context) {
    final poolName = widget.pool['name'] as String? ?? 'Unknown Pool';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(poolName),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: JobsBellButton(server: widget.server),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Pool Info Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.separator,
                    width: 0.5,
                  ),
                ),
                child: _buildPoolInfo(),
              ),
            ),

            // Datasets Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Datasets',
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            // Datasets List
            Consumer<DatasetProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const SliverToBoxAdapter(
                    child: LoadingStateWidget(message: 'Loading datasets...'),
                  );
                }

                if (provider.error != null) {
                  return SliverToBoxAdapter(
                    child: ErrorStateWidget(
                      title: 'Error loading datasets',
                      message: provider.error!,
                      onRetry: _loadDatasets,
                    ),
                  );
                }

                // Filter datasets for this pool
                final poolDatasets = provider.datasets
                    .where((dataset) => dataset['pool'] == poolName)
                    .toList();

                if (poolDatasets.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyStateWidget(
                      icon: CupertinoIcons.folder,
                      title: 'No datasets found',
                      message:
                          'Datasets created in this pool will appear here.',
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final dataset = poolDatasets[index];
                    return _buildDatasetTile(dataset);
                  }, childCount: poolDatasets.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPoolInfo() {
    final status = widget.pool['status'] as String? ?? 'Unknown';
    final healthy = widget.pool['healthy'] as bool? ?? false;
    final topology = widget.pool['topology'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.square_stack_3d_down_right,
              color: healthy
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pool Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Status', status),
        const SizedBox(height: 8),
        _buildInfoRow('Health', healthy ? 'Healthy' : 'Degraded'),
        if (topology != null) ...[
          const SizedBox(height: 8),
          _buildInfoRow('Configuration', _getPoolTypeDescription(topology)),
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
              color: CupertinoColors.systemGrey,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildDatasetTile(Map<String, dynamic> dataset) {
    final name = dataset['name'] as String? ?? 'Unknown';
    final type = dataset['type'] as String? ?? 'FILESYSTEM';
    final mountpoint = dataset['mountpoint'] as String? ?? '';
    final used = dataset['used'] as Map<String, dynamic>?;
    final available = dataset['available'] as Map<String, dynamic>?;

    final usedValue = used?['value'] as String? ?? '0B';
    final availableValue = available?['value'] as String? ?? '0B';

    // Calculate indentation based on dataset path depth
    final pathParts = name.split('/');
    final indentLevel = pathParts.length - 1;
    final indentWidth = indentLevel * 20.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) =>
                  DatasetDetailScreen(server: widget.server, dataset: dataset),
            ),
          );
        },
        child: Container(
          padding: EdgeInsets.fromLTRB(16 + indentWidth, 12, 16, 12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CupertinoColors.separator, width: 0.5),
          ),
          child: Row(
            children: [
              Icon(
                type == 'FILESYSTEM'
                    ? CupertinoIcons.folder
                    : CupertinoIcons.cube,
                color: CupertinoColors.activeBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pathParts.last, // Show only the last part of the path
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (mountpoint.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        mountpoint,
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    usedValue,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'of $availableValue',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey3,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPoolTypeDescription(Map<String, dynamic> topology) {
    final data = topology['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) return 'Unknown configuration';

    final firstVdev = data.first as Map<String, dynamic>?;
    final type = firstVdev?['type'] as String?;
    final children = firstVdev?['children'] as List<dynamic>?;

    if (type == 'mirror' && children != null) {
      return 'Mirror (${children.length} drives)';
    } else if (type == 'raidz1') {
      return 'RAID-Z1 (${children?.length ?? 0} drives)';
    } else if (type == 'raidz2') {
      return 'RAID-Z2 (${children?.length ?? 0} drives)';
    } else if (type == 'raidz3') {
      return 'RAID-Z3 (${children?.length ?? 0} drives)';
    } else if (children != null && children.length == 1) {
      return 'Single drive';
    }

    return 'Custom configuration';
  }
}
