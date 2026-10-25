/// A DSM release, ordered by major, minor, micro, build and update.
///
/// DSM reports itself as e.g. `DSM 7.2.1-69057 Update 5`; [tryParse] reads
/// that form and the bare `7.2.1-69057` one.
final class DsmVersion implements Comparable<DsmVersion> {
  const DsmVersion(
    this.major,
    this.minor, [
    this.micro = 0,
    this.build = 0,
    this.update = 0,
  ]);

  final int major;
  final int minor;
  final int micro;
  final int build;
  final int update;

  static final _pattern = RegExp(
    r'(\d+)\.(\d+)(?:\.(\d+))?(?:-(\d+))?(?:\s+Update\s+(\d+))?',
  );

  static DsmVersion? tryParse(String value) {
    final match = _pattern.firstMatch(value);
    if (match == null) return null;
    int group(int i) => int.parse(match.group(i) ?? '0');
    return DsmVersion(group(1), group(2), group(3), group(4), group(5));
  }

  bool operator >=(DsmVersion other) => compareTo(other) >= 0;

  @override
  int compareTo(DsmVersion other) {
    for (final (a, b) in [
      (major, other.major),
      (minor, other.minor),
      (micro, other.micro),
      (build, other.build),
      (update, other.update),
    ]) {
      if (a != b) return a.compareTo(b);
    }
    return 0;
  }

  @override
  bool operator ==(Object other) =>
      other is DsmVersion && compareTo(other) == 0;

  @override
  int get hashCode => Object.hash(major, minor, micro, build, update);

  @override
  String toString() {
    final base = '$major.$minor.$micro';
    final withBuild = build == 0 ? base : '$base-$build';
    return update == 0 ? withBuild : '$withBuild Update $update';
  }
}
