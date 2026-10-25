import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/widgets/pool_scan/pool_scan_formatters.dart';

void main() {
  test('formatScanSpeed scales through the byte units', () {
    expect(formatScanSpeed(512), '512B/s');
    expect(formatScanSpeed(2048), '2.0KB/s');
    expect(formatScanSpeed(150 * 1024 * 1024), '150.0MB/s');
    expect(formatScanSpeed(3 * 1024 * 1024 * 1024), '3.0GB/s');
  });

  test('formatScanDuration keeps the two most significant units', () {
    expect(formatScanDuration(const Duration(seconds: 45)), '45s');
    expect(formatScanDuration(const Duration(minutes: 5, seconds: 30)), '5m');
    expect(formatScanDuration(const Duration(hours: 1, minutes: 2)), '1h 2m');
    expect(formatScanDuration(const Duration(days: 2, hours: 27)), '3d 3h');
  });

  test('formatScanTimestamp zero-pads the time', () {
    expect(
      formatScanTimestamp(DateTime(2026, 3, 4, 5, 6)),
      'Mar 4, 2026 05:06',
    );
  });
}
