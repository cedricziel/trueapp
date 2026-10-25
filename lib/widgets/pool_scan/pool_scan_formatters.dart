import 'package:truehub/models/pool_scan.dart';

extension PoolScanFunctionLabel on PoolScanFunction {
  /// Noun form, e.g. "Scrub".
  String get label => switch (this) {
    PoolScanFunction.scrub => 'Scrub',
    PoolScanFunction.resilver => 'Resilver',
    PoolScanFunction.unknown => 'Scan',
  };

  /// Progressive form for a compact indicator, e.g. "Scrubbing".
  String get progressiveLabel => switch (this) {
    PoolScanFunction.scrub => 'Scrubbing',
    PoolScanFunction.resilver => 'Resilvering',
    PoolScanFunction.unknown => 'Scanning',
  };
}

String formatScanSpeed(double bytesPerSecond) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytesPerSecond;
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)}${units[unit]}/s';
}

/// Two most significant units: "2d 3h", "1h 2m", "5m", "45s".
String formatScanDuration(Duration duration) {
  if (duration.inDays > 0) {
    return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
  }
  if (duration.inHours > 0) {
    return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
  }
  if (duration.inMinutes > 0) return '${duration.inMinutes}m';
  return '${duration.inSeconds}s';
}

String formatScanTimestamp(DateTime time) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = time.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute';
}
