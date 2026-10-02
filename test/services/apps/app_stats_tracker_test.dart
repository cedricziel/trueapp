import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/app.dart';
import 'package:truehub/services/apps/app_stats_tracker.dart';

import '../../helpers/fake_api_client.dart';

AppResourceUsage _usage({
  double cpu = 0,
  int memory = 0,
  int limit = 0,
  double rx = 0,
  double tx = 0,
}) => AppResourceUsage(
  cpuUsage: cpu,
  memoryUsage: memory,
  memoryLimit: limit,
  networkRxBytes: rx,
  networkTxBytes: tx,
);

void main() {
  late int changes;
  late AppStatsTracker tracker;

  setUp(() {
    changes = 0;
    tracker = AppStatsTracker(onChanged: () => changes++);
  });

  test('stores the first reading for an app as is', () {
    tracker.merge({'plex': _usage(cpu: 5, memory: 100)});

    expect(tracker.usageFor('plex')!.cpuUsage, 5);
    expect(tracker.usageFor('other'), isNull);
  });

  test('a zero reading keeps the previous value per field', () {
    tracker.merge({'plex': _usage(cpu: 5, memory: 100, limit: 200, rx: 3)});
    tracker.merge({'plex': _usage(cpu: 7, tx: 9)});

    final merged = tracker.usageFor('plex')!;
    expect(merged.cpuUsage, 7);
    expect(merged.memoryUsage, 100);
    expect(merged.memoryLimit, 200);
    expect(merged.networkRxBytes, 3);
    expect(merged.networkTxBytes, 9);
  });

  test('clear forgets all usage', () {
    tracker.merge({'plex': _usage(cpu: 5)});
    tracker.clear();

    expect(tracker.usageFor('plex'), isNull);
  });

  test('stream events are merged and reported until unsubscribed', () async {
    final client = FakeApiClient();
    await tracker.subscribe(client);

    client.emitAppStats({'plex': _usage(cpu: 4)});
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);
    expect(tracker.usageFor('plex')!.cpuUsage, 4);

    await tracker.unsubscribe(client);
    client.emitAppStats({'plex': _usage(cpu: 8)});
    await Future<void>.delayed(Duration.zero);
    expect(changes, 1);

    await client.dispose();
  });
}
