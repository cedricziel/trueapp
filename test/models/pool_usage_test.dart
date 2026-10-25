import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/models/pool_usage.dart';

PoolUsage _usage(int allocated, int total) =>
    PoolUsage(allocatedBytes: allocated, totalBytes: total);

void main() {
  group('PoolUsage.level', () {
    test('is normal below 80%', () {
      expect(_usage(0, 100).level, PoolUsageLevel.normal);
      expect(_usage(79, 100).level, PoolUsageLevel.normal);
    });

    test('is warning from 80% up to but excluding 90%', () {
      expect(_usage(80, 100).level, PoolUsageLevel.warning);
      expect(_usage(89, 100).level, PoolUsageLevel.warning);
    });

    test('is critical from 90%', () {
      expect(_usage(90, 100).level, PoolUsageLevel.critical);
      expect(_usage(100, 100).level, PoolUsageLevel.critical);
    });

    test('classifies exact boundaries on large pools without rounding', () {
      const tib = 1 << 40;
      expect(_usage(tib * 8 - 1, tib * 10).level, PoolUsageLevel.normal);
      expect(_usage(tib * 8, tib * 10).level, PoolUsageLevel.warning);
      expect(_usage(tib * 9 - 1, tib * 10).level, PoolUsageLevel.warning);
      expect(_usage(tib * 9, tib * 10).level, PoolUsageLevel.critical);
    });

    test('treats a pool with no capacity as normal', () {
      expect(_usage(0, 0).level, PoolUsageLevel.normal);
      expect(_usage(0, 0).percent, 0);
    });
  });

  group('PoolUsage.percent', () {
    test('rounds down to a whole percent', () {
      expect(_usage(1, 3).percent, 33);
      expect(_usage(2, 3).percent, 66);
      expect(_usage(1, 100).percent, 1);
    });

    test('agrees with the level just below a threshold', () {
      final usage = _usage(796, 1000);
      expect(usage.percent, 79);
      expect(usage.level, PoolUsageLevel.normal);
    });
  });

  test('PoolUsage.fromPool uses allocated over allocated plus free', () {
    const pool = Pool(
      id: '1',
      name: 'tank',
      status: 'ONLINE',
      healthy: true,
      allocatedBytes: 90,
      freeBytes: 10,
      dataVdevs: [],
    );

    final usage = PoolUsage.fromPool(pool);

    expect(usage.totalBytes, 100);
    expect(usage.level, PoolUsageLevel.critical);
  });
}
