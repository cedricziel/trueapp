import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:truehub/models/alert.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/models/server_health.dart';
import 'package:truehub/models/service_status.dart';
import 'package:truehub/providers/health_provider.dart';
import 'package:truehub/widgets/error_state_widget.dart';
import 'package:truehub/widgets/jobs_bell_button.dart';
import 'package:truehub/widgets/section_card.dart';

class ServerHealthScreen extends StatefulWidget {
  final NasServer server;

  const ServerHealthScreen({super.key, required this.server});

  @override
  State<ServerHealthScreen> createState() => _ServerHealthScreenState();
}

class _ServerHealthScreenState extends State<ServerHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final healthProvider = context.read<HealthProvider>();
      await healthProvider.setApiClient(widget.server);
      await healthProvider.loadHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Health'),
        previousPageTitle: widget.server.name,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            JobsBellButton(server: widget.server),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.refresh),
              onPressed: () => context.read<HealthProvider>().refreshHealth(),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Consumer<HealthProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (provider.error != null) {
              return ErrorStateWidget(
                title: 'Could Not Load Health',
                message: provider.error!,
                onRetry: () => provider.refreshHealth(),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryBanner(provider.activeAlerts),
                if (provider.activeAlerts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Active Alerts'),
                  const SizedBox(height: 12),
                  ...provider.activeAlerts.map(
                    (alert) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAlertCard(alert),
                    ),
                  ),
                ],
                if (provider.serverHealth != null &&
                    provider.serverHealth!.disks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildSectionHeader('Disks'),
                  const SizedBox(height: 12),
                  _buildDisksGrid(provider.serverHealth!.disks),
                ],
                if (provider.services.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildServicesSection(provider.services),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildSummaryBanner(List<Alert> activeAlerts) {
    final hasAlerts = activeAlerts.isNotEmpty;
    final color = hasAlerts
        ? CupertinoColors.systemRed
        : CupertinoColors.systemGreen;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            hasAlerts
                ? CupertinoIcons.exclamationmark_triangle_fill
                : CupertinoIcons.checkmark_shield_fill,
            color: color,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAlerts
                      ? '${activeAlerts.length} active ${activeAlerts.length == 1 ? 'alert' : 'alerts'}'
                      : 'All Systems Operational',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (hasAlerts) ...[
                  const SizedBox(height: 2),
                  Text(
                    activeAlerts.first.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    final color = switch (alert.level) {
      AlertLevel.critical => CupertinoColors.systemRed,
      AlertLevel.error => CupertinoColors.systemOrange,
      AlertLevel.warning => CupertinoColors.systemYellow,
      AlertLevel.info || AlertLevel.unknown => CupertinoColors.systemBlue,
    };

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (alert.occurredAt != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _formatRelativeTime(alert.occurredAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisksGrid(List<DiskInfo> disks) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: disks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) => _buildDiskCard(disks[index]),
    );
  }

  Widget _buildDiskCard(DiskInfo disk) {
    final color = _diskHealthColor(disk.health);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  disk.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(disk.health, style: TextStyle(fontSize: 11, color: color)),
          if (disk.temperature > 0) ...[
            const SizedBox(height: 2),
            Text(
              '${disk.temperature}°C',
              style: const TextStyle(
                fontSize: 11,
                color: CupertinoColors.tertiaryLabel,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _diskHealthColor(String health) {
    final normalized = health.toUpperCase();
    if (normalized.contains('FAIL')) return CupertinoColors.systemRed;
    if (normalized == 'PASSED' ||
        normalized == 'HEALTHY' ||
        normalized == 'OK') {
      return CupertinoColors.systemGreen;
    }
    return CupertinoColors.systemGrey;
  }

  Widget _buildServicesSection(List<ServiceStatus> services) {
    return SectionCard(
      title: 'Services',
      icon: CupertinoIcons.gear_alt,
      children: [
        for (final service in services)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: service.isRunning
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemGrey,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    service.displayName,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  service.isRunning ? 'Running' : 'Stopped',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: service.isRunning
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
