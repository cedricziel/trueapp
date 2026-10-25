import 'package:flutter_test/flutter_test.dart';
import 'package:truehub/models/pool.dart';
import 'package:truehub/services/tray/tray_pool_entries.dart';

const _tib = 1 << 40;
const _gib = 1 << 30;

Pool _pool(String name, {required int allocated, required int free}) => Pool(
  id: name,
  name: name,
  status: 'ONLINE',
  healthy: true,
  allocatedBytes: allocated,
  freeBytes: free,
  dataVdevs: const [],
);

void main() {
  test('builds no entries when there are no pools', () {
    expect(buildPoolMenuEntries(const []), isEmpty);
  });

  test('starts with a disabled header', () {
    final entries = buildPoolMenuEntries([
      _pool('tank', allocated: _tib, free: 3 * _tib),
    ]);

    expect(entries.first.key, 'pools_header');
    expect(entries.first.label, 'Pools');
    expect(entries.first.enabled, isFalse);
    expect(entries.where((e) => e.isSeparator), isEmpty);
  });

  test('shows used and total capacity with the percentage', () {
    final entries = buildPoolMenuEntries([
      _pool('tank', allocated: _tib, free: 3 * _tib),
    ]);

    final tank = entries.firstWhere((e) => e.key == 'pool_tank');
    expect(tank.label, endsWith('tank: 1.0TB / 4.0TB (25%)'));
    expect(tank.enabled, isFalse);
  });

  test('formats sub-terabyte sizes in smaller units', () {
    final entries = buildPoolMenuEntries([
      _pool('scratch', allocated: 512 * _gib, free: 512 * _gib),
    ]);

    expect(entries.last.label, endsWith('scratch: 512.0GB / 1.0TB (50%)'));
  });

  test('uses a different indicator for each usage level', () {
    final entries = buildPoolMenuEntries([
      _pool('ok', allocated: 79, free: 21),
      _pool('warn', allocated: 80, free: 20),
      _pool('crit', allocated: 90, free: 10),
    ]);

    String indicatorOf(String key) =>
        entries.firstWhere((e) => e.key == key).label!.split(' ').first;

    final indicators = {
      indicatorOf('pool_ok'),
      indicatorOf('pool_warn'),
      indicatorOf('pool_crit'),
    };
    expect(indicators, hasLength(3));
    expect(indicatorOf('pool_ok'), '\u{1F7E2}');
    expect(indicatorOf('pool_warn'), '\u{1F7E1}');
    expect(indicatorOf('pool_crit'), '\u{1F534}');
  });
}
