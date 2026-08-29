import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';

class DatasetDetailScreen extends StatelessWidget {
  final NasServer server;
  final Map<String, dynamic> dataset;

  const DatasetDetailScreen({
    super.key,
    required this.server,
    required this.dataset,
  });

  @override
  Widget build(BuildContext context) {
    final name = dataset['name'] as String? ?? 'Unknown Dataset';

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(name.split('/').last),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Back'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGeneralInfo(),
            const SizedBox(height: 16),
            _buildStorageInfo(),
            const SizedBox(height: 16),
            _buildCompressionInfo(),
            const SizedBox(height: 16),
            _buildSecurityInfo(),
            const SizedBox(height: 16),
            _buildAdvancedInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralInfo() {
    final type = dataset['type'] as String? ?? 'FILESYSTEM';
    final mountpoint = dataset['mountpoint'] as String? ?? '';
    final pool = dataset['pool'] as String? ?? '';
    final encrypted = dataset['encrypted'] as bool? ?? false;
    final creation = dataset['creation'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'General Information',
      icon: CupertinoIcons.info_circle,
      children: [
        _buildInfoRow('Name', dataset['name'] as String? ?? 'Unknown'),
        _buildInfoRow('Type', type),
        _buildInfoRow('Pool', pool),
        if (mountpoint.isNotEmpty) _buildInfoRow('Mount Point', mountpoint),
        _buildInfoRow('Encrypted', encrypted ? 'Yes' : 'No'),
        if (creation != null)
          _buildInfoRow('Created', creation['value'] as String? ?? 'Unknown'),
      ],
    );
  }

  Widget _buildStorageInfo() {
    final used = dataset['used'] as Map<String, dynamic>?;
    final available = dataset['available'] as Map<String, dynamic>?;
    final usedByDataset = dataset['usedbydataset'] as Map<String, dynamic>?;
    final usedByChildren = dataset['usedbychildren'] as Map<String, dynamic>?;
    final usedBySnapshots = dataset['usedbysnapshots'] as Map<String, dynamic>?;
    final quota = dataset['quota'] as Map<String, dynamic>?;
    final reservation = dataset['reservation'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'Storage Information',
      icon: CupertinoIcons.chart_pie,
      children: [
        if (used != null)
          _buildInfoRow('Used Space', used['value'] as String? ?? '0B'),
        if (available != null)
          _buildInfoRow(
            'Available Space',
            available['value'] as String? ?? '0B',
          ),
        if (usedByDataset != null)
          _buildInfoRow(
            'Used by Dataset',
            usedByDataset['value'] as String? ?? '0B',
          ),
        if (usedByChildren != null)
          _buildInfoRow(
            'Used by Children',
            usedByChildren['value'] as String? ?? '0B',
          ),
        if (usedBySnapshots != null)
          _buildInfoRow(
            'Used by Snapshots',
            usedBySnapshots['value'] as String? ?? '0B',
          ),
        if (quota != null && quota['value'] != null)
          _buildInfoRow('Quota', quota['value'] as String),
        if (reservation != null && reservation['value'] != null)
          _buildInfoRow('Reservation', reservation['value'] as String),
      ],
    );
  }

  Widget _buildCompressionInfo() {
    final compression = dataset['compression'] as Map<String, dynamic>?;
    final compressRatio = dataset['compressratio'] as Map<String, dynamic>?;
    final deduplication = dataset['deduplication'] as Map<String, dynamic>?;
    final checksum = dataset['checksum'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'Compression & Efficiency',
      icon: CupertinoIcons.archivebox,
      children: [
        if (compression != null)
          _buildInfoRow(
            'Compression',
            compression['value'] as String? ?? 'Unknown',
          ),
        if (compressRatio != null)
          _buildInfoRow(
            'Compression Ratio',
            compressRatio['value'] as String? ?? '1.00x',
          ),
        if (deduplication != null)
          _buildInfoRow(
            'Deduplication',
            deduplication['value'] as String? ?? 'Unknown',
          ),
        if (checksum != null)
          _buildInfoRow('Checksum', checksum['value'] as String? ?? 'Unknown'),
      ],
    );
  }

  Widget _buildSecurityInfo() {
    final aclmode = dataset['aclmode'] as Map<String, dynamic>?;
    final acltype = dataset['acltype'] as Map<String, dynamic>?;
    final readonly = dataset['readonly'] as Map<String, dynamic>?;
    final exec = dataset['exec'] as Map<String, dynamic>?;
    final encryptionAlgorithm =
        dataset['encryption_algorithm'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'Security & Permissions',
      icon: CupertinoIcons.lock_shield,
      children: [
        if (aclmode != null)
          _buildInfoRow('ACL Mode', aclmode['value'] as String? ?? 'Unknown'),
        if (acltype != null)
          _buildInfoRow('ACL Type', acltype['value'] as String? ?? 'Unknown'),
        if (readonly != null)
          _buildInfoRow('Read Only', readonly['value'] as String? ?? 'Unknown'),
        if (exec != null)
          _buildInfoRow('Execute', exec['value'] as String? ?? 'Unknown'),
        if (encryptionAlgorithm != null && encryptionAlgorithm['value'] != null)
          _buildInfoRow('Encryption', encryptionAlgorithm['value'] as String),
      ],
    );
  }

  Widget _buildAdvancedInfo() {
    final recordsize = dataset['recordsize'] as Map<String, dynamic>?;
    final copies = dataset['copies'] as Map<String, dynamic>?;
    final sync = dataset['sync'] as Map<String, dynamic>?;
    final atime = dataset['atime'] as Map<String, dynamic>?;
    final casesensitivity = dataset['casesensitivity'] as Map<String, dynamic>?;

    return _buildSection(
      title: 'Advanced Properties',
      icon: CupertinoIcons.gear,
      children: [
        if (recordsize != null)
          _buildInfoRow(
            'Record Size',
            recordsize['value'] as String? ?? 'Unknown',
          ),
        if (copies != null)
          _buildInfoRow('Copies', copies['value'] as String? ?? 'Unknown'),
        if (sync != null)
          _buildInfoRow('Sync', sync['value'] as String? ?? 'Unknown'),
        if (atime != null)
          _buildInfoRow('Access Time', atime['value'] as String? ?? 'Unknown'),
        if (casesensitivity != null)
          _buildInfoRow(
            'Case Sensitivity',
            casesensitivity['value'] as String? ?? 'Unknown',
          ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.separator, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CupertinoColors.activeBlue, size: 20),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
      ),
    );
  }
}
