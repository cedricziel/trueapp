import 'dart:async';

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

class _SlowSubscribeClient extends FakeApiClient {
  final subscribeGate = Completer<void>();

  @override
  Future<void> subscribeToAppStats() async {
    await super.subscribeToAppStats();
    await subscribeGate.future;
  }
}

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

  test(
    'does not start listening when unsubscribed while subscribing',
    () async {
      final client = _SlowSubscribeClient();
      final subscribing = tracker.subscribe(client);

      await tracker.unsubscribe(null);
      client.subscribeGate.complete();
      await subscribing;

      client.emitAppStats({'plex': _usage(cpu: 4)});
      await Future<void>.delayed(Duration.zero);
      expect(changes, 0);

      await client.dispose();
    },
  );

  test(
    'keeps the new subscription when resubscribing during an unsubscribe',
    () async {
      final oldClient = FakeApiClient();
      final newClient = FakeApiClient();
      await tracker.subscribe(oldClient);

      final unsubscribing = tracker.unsubscribe(oldClient);
      await tracker.subscribe(newClient);
      await unsubscribing;

      await tracker.unsubscribe(newClient);
      newClient.emitAppStats({'plex': _usage(cpu: 4)});
      await Future<void>.delayed(Duration.zero);
      expect(changes, 0);

      await oldClient.dispose();
      await newClient.dispose();
    },
  );
}
