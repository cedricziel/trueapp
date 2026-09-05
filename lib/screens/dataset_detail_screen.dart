import 'package:flutter/cupertino.dart';
import 'package:truehub/models/nas_server.dart';
import 'package:truehub/widgets/section_card.dart';

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

    return SectionCard(
      title: 'General Information',
      icon: CupertinoIcons.info_circle,
      children: [
        InfoRow('Name', dataset['name'] as String? ?? 'Unknown'),
        InfoRow('Type', type),
        InfoRow('Pool', pool),
        if (mountpoint.isNotEmpty) InfoRow('Mount Point', mountpoint),
        InfoRow('Encrypted', encrypted ? 'Yes' : 'No'),
        if (creation != null)
          InfoRow('Created', creation['value'] as String? ?? 'Unknown'),
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

    return SectionCard(
      title: 'Storage Information',
      icon: CupertinoIcons.chart_pie,
      children: [
        if (used != null)
          InfoRow('Used Space', used['value'] as String? ?? '0B'),
        if (available != null)
          InfoRow('Available Space', available['value'] as String? ?? '0B'),
        if (usedByDataset != null)
          InfoRow('Used by Dataset', usedByDataset['value'] as String? ?? '0B'),
        if (usedByChildren != null)
          InfoRow(
            'Used by Children',
            usedByChildren['value'] as String? ?? '0B',
          ),
        if (usedBySnapshots != null)
          InfoRow(
            'Used by Snapshots',
            usedBySnapshots['value'] as String? ?? '0B',
          ),
        if (quota != null && quota['value'] != null)
          InfoRow('Quota', quota['value'] as String),
        if (reservation != null && reservation['value'] != null)
          InfoRow('Reservation', reservation['value'] as String),
      ],
    );
  }

  Widget _buildCompressionInfo() {
    final compression = dataset['compression'] as Map<String, dynamic>?;
    final compressRatio = dataset['compressratio'] as Map<String, dynamic>?;
    final deduplication = dataset['deduplication'] as Map<String, dynamic>?;
    final checksum = dataset['checksum'] as Map<String, dynamic>?;

    return SectionCard(
      title: 'Compression & Efficiency',
      icon: CupertinoIcons.archivebox,
      children: [
        if (compression != null)
          InfoRow('Compression', compression['value'] as String? ?? 'Unknown'),
        if (compressRatio != null)
          InfoRow(
            'Compression Ratio',
            compressRatio['value'] as String? ?? '1.00x',
          ),
        if (deduplication != null)
          InfoRow(
            'Deduplication',
            deduplication['value'] as String? ?? 'Unknown',
          ),
        if (checksum != null)
          InfoRow('Checksum', checksum['value'] as String? ?? 'Unknown'),
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

    return SectionCard(
      title: 'Security & Permissions',
      icon: CupertinoIcons.lock_shield,
      children: [
        if (aclmode != null)
          InfoRow('ACL Mode', aclmode['value'] as String? ?? 'Unknown'),
        if (acltype != null)
          InfoRow('ACL Type', acltype['value'] as String? ?? 'Unknown'),
        if (readonly != null)
          InfoRow('Read Only', readonly['value'] as String? ?? 'Unknown'),
        if (exec != null)
          InfoRow('Execute', exec['value'] as String? ?? 'Unknown'),
        if (encryptionAlgorithm != null && encryptionAlgorithm['value'] != null)
          InfoRow('Encryption', encryptionAlgorithm['value'] as String),
      ],
    );
  }

  Widget _buildAdvancedInfo() {
    final recordsize = dataset['recordsize'] as Map<String, dynamic>?;
    final copies = dataset['copies'] as Map<String, dynamic>?;
    final sync = dataset['sync'] as Map<String, dynamic>?;
    final atime = dataset['atime'] as Map<String, dynamic>?;
    final casesensitivity = dataset['casesensitivity'] as Map<String, dynamic>?;

    return SectionCard(
      title: 'Advanced Properties',
      icon: CupertinoIcons.gear,
      children: [
        if (recordsize != null)
          InfoRow('Record Size', recordsize['value'] as String? ?? 'Unknown'),
        if (copies != null)
          InfoRow('Copies', copies['value'] as String? ?? 'Unknown'),
        if (sync != null)
          InfoRow('Sync', sync['value'] as String? ?? 'Unknown'),
        if (atime != null)
          InfoRow('Access Time', atime['value'] as String? ?? 'Unknown'),
        if (casesensitivity != null)
          InfoRow(
            'Case Sensitivity',
            casesensitivity['value'] as String? ?? 'Unknown',
          ),
      ],
    );
  }
}
