import 'api_catalog.dart';
import 'dsm_version.dart';

/// What a NAS must offer for a feature to work.
///
/// [api] at [minApiVersion] or later is the primary check, since DSM
/// advertises exactly which APIs and versions it serves. [minDsm] covers
/// behaviour the catalog cannot express, such as a response shape that
/// changed between DSM releases under the same API version.
final class FeatureRequirement {
  const FeatureRequirement(this.api, {this.minApiVersion = 1, this.minDsm});

  final String api;
  final int minApiVersion;
  final DsmVersion? minDsm;
}

enum SynologyFeature {
  systemInfo(FeatureRequirement('SYNO.DSM.Info')),
  storage(FeatureRequirement('SYNO.Storage.CGI.Storage')),
  fileStation(FeatureRequirement('SYNO.FileStation.List')),
  packages(FeatureRequirement('SYNO.Core.Package')),
  containers(FeatureRequirement('SYNO.Docker.Container'));

  const SynologyFeature(this.requirement);

  final FeatureRequirement requirement;
}

/// Answers which features a particular NAS supports.
final class SynologyCapabilities {
  const SynologyCapabilities(this.catalog, {this.dsmVersion});

  final ApiCatalog catalog;

  /// Null until the DSM version is known; any [FeatureRequirement.minDsm]
  /// then counts as unmet.
  final DsmVersion? dsmVersion;

  bool supports(SynologyFeature feature) => meets(feature.requirement);

  bool meets(FeatureRequirement requirement) {
    final info = catalog[requirement.api];
    if (info == null || info.maxVersion < requirement.minApiVersion) {
      return false;
    }
    final minDsm = requirement.minDsm;
    if (minDsm == null) return true;
    final dsm = dsmVersion;
    return dsm != null && dsm >= minDsm;
  }
}
