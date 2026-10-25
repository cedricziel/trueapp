import 'package:synology_api/synology_api.dart';
import 'package:test/test.dart';

void main() {
  final catalog = ApiCatalog.fromJson({
    'SYNO.API.Auth': {
      'path': 'entry.cgi',
      'minVersion': 3,
      'maxVersion': 7,
      'requestFormat': 'JSON',
    },
  });

  final info = catalog['SYNO.API.Auth']!;

  test('parses path and version range', () {
    expect(info.path, 'entry.cgi');
    expect(info.supports(3), isTrue);
    expect(info.supports(8), isFalse);
  });

  test('knows only the advertised APIs', () {
    expect(catalog.has('SYNO.Nope'), isFalse);
    expect(catalog['SYNO.Nope'], isNull);
  });

  group('negotiate', () {
    test('picks the highest version both sides support', () {
      expect(info.negotiate(1, 6), 6);
      expect(info.negotiate(1, 9), 7);
    });

    test('returns null when the ranges do not overlap', () {
      expect(info.negotiate(1, 2), isNull);
      expect(info.negotiate(8, 9), isNull);
    });
  });
}
