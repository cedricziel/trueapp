import 'package:truehub/models/pool.dart';

enum PoolUsageLevel { normal, warning, critical }

/// How full a pool is, and how worried to be about it.
class PoolUsage {
  const PoolUsage({required this.allocatedBytes, required this.totalBytes});

  factory PoolUsage.fromPool(Pool pool) => PoolUsage(
    allocatedBytes: pool.allocatedBytes,
    totalBytes: pool.totalBytes,
  );

  static const int warningPercent = 80;
  static const int criticalPercent = 90;

  final int allocatedBytes;
  final int totalBytes;

  int get percent =>
      totalBytes <= 0 ? 0 : (allocatedBytes * 100 / totalBytes).round();

  /// Compares in integers so a pool sitting exactly on a threshold is never
  /// tipped either way by floating point rounding.
  PoolUsageLevel get level {
    if (totalBytes <= 0) return PoolUsageLevel.normal;
    final scaled = allocatedBytes * 100;
    if (scaled >= totalBytes * criticalPercent) return PoolUsageLevel.critical;
    if (scaled >= totalBytes * warningPercent) return PoolUsageLevel.warning;
    return PoolUsageLevel.normal;
  }
}
