import 'package:synology_api/synology_api.dart';
import 'package:test/test.dart';

void main() {
  group('DsmVersion.tryParse', () {
    test('reads the version_string DSM reports', () {
      expect(
        DsmVersion.tryParse('DSM 7.2.1-69057 Update 5'),
        const DsmVersion(7, 2, 1, 69057, 5),
      );
    });

    test('defaults missing micro, build and update to zero', () {
      expect(
        DsmVersion.tryParse('DSM 7.2-64570'),
        const DsmVersion(7, 2, 0, 64570),
      );
      expect(DsmVersion.tryParse('6.2'), const DsmVersion(6, 2));
    });

    test('returns null for text without a version', () {
      expect(DsmVersion.tryParse('DSM'), isNull);
    });
  });

  test('orders by each component in turn', () {
    const versions = [
      DsmVersion(6, 2, 4, 25556, 7),
      DsmVersion(7, 0),
      DsmVersion(7, 2, 1, 69057),
      DsmVersion(7, 2, 1, 69057, 5),
    ];
    expect([...versions.reversed]..sort(), versions);
    expect(versions[1] >= const DsmVersion(7, 0), isTrue);
    expect(versions[0] >= versions[1], isFalse);
  });

  test('prints the DSM form back', () {
    expect('${const DsmVersion(7, 2, 1, 69057, 5)}', '7.2.1-69057 Update 5');
    expect('${const DsmVersion(7, 0)}', '7.0.0');
  });
}
