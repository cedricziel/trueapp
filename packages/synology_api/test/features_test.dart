import 'package:synology_api/synology_api.dart';
import 'package:synology_api/testing.dart';
import 'package:test/test.dart';

void main() {
  final dsm7 = ApiCatalog(FakeSynologyNas.dsm7Apis());
  final dsm6 = ApiCatalog(FakeSynologyNas.dsm6Apis());

  test('a feature is available when the NAS serves its API', () {
    final capabilities = SynologyCapabilities(dsm7);
    expect(capabilities.supports(SynologyFeature.containers), isTrue);
    expect(
      SynologyCapabilities(dsm6).supports(SynologyFeature.containers),
      isFalse,
    );
  });

  test('a minimum API version above what the NAS serves is unmet', () {
    final capabilities = SynologyCapabilities(dsm6);
    expect(
      capabilities.meets(
        const FeatureRequirement('SYNO.API.Auth', minApiVersion: 6),
      ),
      isTrue,
    );
    expect(
      capabilities.meets(
        const FeatureRequirement('SYNO.API.Auth', minApiVersion: 7),
      ),
      isFalse,
    );
  });

  group('minimum DSM version', () {
    const requirement = FeatureRequirement(
      'SYNO.DSM.Info',
      minDsm: DsmVersion(7, 2),
    );

    test('is met by that release or later', () {
      expect(
        SynologyCapabilities(
          dsm7,
          dsmVersion: const DsmVersion(7, 2, 1),
        ).meets(requirement),
        isTrue,
      );
      expect(
        SynologyCapabilities(
          dsm7,
          dsmVersion: const DsmVersion(7, 1, 1),
        ).meets(requirement),
        isFalse,
      );
    });

    test('is unmet while the DSM version is unknown', () {
      expect(SynologyCapabilities(dsm7).meets(requirement), isFalse);
    });
  });
}
