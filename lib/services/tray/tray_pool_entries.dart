import 'package:truehub/models/pool.dart';
import 'package:truehub/models/pool_usage.dart';
import 'package:truehub/services/tray/tray_host.dart';

/// Menu rows listing each pool's used and total capacity.
///
/// Native menus cannot colour text, so the usage level is carried by a
/// coloured circle at the start of the label.
List<TrayMenuEntry> buildPoolMenuEntries(List<Pool> pools) {
  if (pools.isEmpty) return const [];
  return [
    const TrayMenuEntry(key: 'pools_header', label: 'Pools', enabled: false),
    for (final pool in pools)
      TrayMenuEntry(
        key: 'pool_${pool.id}',
        label: _poolLabel(pool),
        enabled: false,
      ),
  ];
}

String _poolLabel(Pool pool) {
  final usage = PoolUsage.fromPool(pool);
  final indicator = switch (usage.level) {
    PoolUsageLevel.normal => '\u{1F7E2}',
    PoolUsageLevel.warning => '\u{1F7E1}',
    PoolUsageLevel.critical => '\u{1F534}',
  };
  return '$indicator ${pool.name}: ${_formatBytes(usage.allocatedBytes)} / '
      '${_formatBytes(usage.totalBytes)} (${usage.percent}%)';
}

String _formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return unit == 0 ? '${bytes}B' : '${value.toStringAsFixed(1)}${units[unit]}';
}
