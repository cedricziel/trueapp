import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool.dart';

void main() {
  group('Pool.fromJson', () {
    test('parses a healthy mirrored pool', () {
      final pool = Pool.fromJson({
        'id': 1,
        'name': 'tank',
        'status': 'ONLINE',
        'healthy': true,
        'allocated': 1200,
        'free': 2600,
        'topology': {
          'data': [
            {
              'type': 'MIRROR',
              'children': [
                {'disk': 'ada0', 'status': 'ONLINE'},
                {'disk': 'ada1', 'status': 'ONLINE'},
              ],
            },
          ],
        },
      });

      expect(pool.id, '1');
      expect(pool.name, 'tank');
      expect(pool.status, 'ONLINE');
      expect(pool.healthy, isTrue);
      expect(pool.allocatedBytes, 1200);
      expect(pool.freeBytes, 2600);
      expect(pool.totalBytes, 3800);
      expect(pool.dataVdevs, hasLength(1));
      expect(pool.topologyDescription, 'Mirror (2 drives)');
      expect(pool.allDisks.map((d) => d.name), ['ada0', 'ada1']);
      expect(pool.allDisks.every((d) => d.isHealthy), isTrue);
    });

    test('surfaces which specific disk needs attention in a degraded pool', () {
      final pool = Pool.fromJson({
        'name': 'backup',
        'status': 'DEGRADED',
        'healthy': false,
        'allocated': 3100,
        'free': 4900,
        'topology': {
          'data': [
            {
              'type': 'RAIDZ1',
              'children': [
                {'disk': 'ada0', 'status': 'ONLINE'},
                {'disk': 'ada1', 'status': 'ONLINE'},
                {'disk': 'ada2', 'status': 'ONLINE'},
                {'disk': 'ada3', 'status': 'OFFLINE'},
              ],
            },
          ],
        },
      });

      expect(pool.healthy, isFalse);
      expect(pool.topologyDescription, 'RAID-Z1 (4 drives)');
      final offline = pool.allDisks.where((d) => !d.isHealthy).toList();
      expect(offline, hasLength(1));
      expect(offline.single.name, 'ada3');
      expect(offline.single.status, VdevDiskStatus.offline);
    });

    test('treats a leaf vdev (single disk, no children) as a single drive', () {
      final pool = Pool.fromJson({
        'name': 'scratch',
        'status': 'ONLINE',
        'healthy': true,
        'allocated': 100,
        'free': 400,
        'topology': {
          'data': [
            {'type': 'DISK', 'disk': 'ada4', 'status': 'ONLINE'},
          ],
        },
      });

      expect(pool.topologyDescription, 'Single drive');
      expect(pool.allDisks, hasLength(1));
      expect(pool.allDisks.single.name, 'ada4');
    });

    test('falls back to safe defaults for missing or unknown fields', () {
      final pool = Pool.fromJson(const {});

      expect(pool.name, 'Unknown');
      expect(pool.status, 'Unknown');
      expect(pool.healthy, isFalse);
      expect(pool.allocatedBytes, 0);
      expect(pool.freeBytes, 0);
      expect(pool.dataVdevs, isEmpty);
      expect(pool.topologyDescription, 'Unknown configuration');
      expect(pool.allDisks, isEmpty);
    });

    test('combines vdev descriptions when a pool has more than one', () {
      final pool = Pool.fromJson({
        'name': 'wide',
        'status': 'ONLINE',
        'healthy': true,
        'allocated': 0,
        'free': 0,
        'topology': {
          'data': [
            {
              'type': 'MIRROR',
              'children': [
                {'disk': 'ada0', 'status': 'ONLINE'},
                {'disk': 'ada1', 'status': 'ONLINE'},
              ],
            },
            {
              'type': 'MIRROR',
              'children': [
                {'disk': 'ada2', 'status': 'ONLINE'},
                {'disk': 'ada3', 'status': 'ONLINE'},
              ],
            },
          ],
        },
      });

      expect(pool.dataVdevs, hasLength(2));
      expect(pool.topologyDescription, '2 × Mirror (2 drives)');
      expect(pool.allDisks, hasLength(4));
    });
  });
}
