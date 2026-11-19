/// Cuboid's *project architecture version* -- distinct from two other,
/// related version numbers that live elsewhere in this package:
///
/// * `cuboidVersion` (`cli/cuboid_command_runner.dart`) is the installed
///   Cuboid CLI's own version.
/// * `cuboid_flutter`'s `pubspec.yaml` `version:` is the runtime/framework
///   package's own version.
///
/// The architecture version instead answers "which generation of Cuboid's
/// generated-project *structure and infrastructure* (navigation, locator,
/// router conventions, etc.) does this project follow?" A project's
/// installed `cuboid_flutter` version can move independently of this --
/// `cuboid create app` always pairs a freshly generated project with the
/// architecture version those files actually match, but upgrading the
/// `cuboid_flutter` dependency alone (a plain pub upgrade) does not rewrite
/// already-generated application source, which is exactly the gap
/// `cuboid doctor`/`cuboid upgrade` exist to close.
///
/// Versions are plain three-part semver strings compared numerically (not
/// lexically), so `0.10.0` sorts after `0.9.0`.
library;

/// The newest project architecture this installed Cuboid CLI knows how to
/// generate and migrate to. Bump this, and add a matching [Migration] to
/// `migrate/migration_registry.dart`, whenever a new generation of
/// Cuboid-owned project infrastructure ships.
const currentArchitectureVersion = '0.2.0';

/// The architecture version generated projects carried before Cuboid
/// recorded architecture metadata at all (see [ArchitectureMetadata]) --
/// `lib/app/app.router.dart` built routes with `MaterialPageRoute` directly
/// and `NavigationService` had no direct-widget navigation methods.
const legacyArchitectureVersion = '0.1.0';

/// A parsed `MAJOR.MINOR.PATCH` architecture version. Comparison is
/// numeric per component, matching semver ordering for the plain
/// (pre-release-free) versions Cuboid architecture uses.
class ArchitectureVersion implements Comparable<ArchitectureVersion> {
  const ArchitectureVersion(this.major, this.minor, this.patch);

  final int major;
  final int minor;
  final int patch;

  static final RegExp _pattern = RegExp(r'^(\d+)\.(\d+)\.(\d+)$');

  /// Parses [value], or returns `null` if it is not a plain `MAJOR.MINOR.PATCH`
  /// string. Deliberately permissive about no other format (no pre-release
  /// or build metadata) -- Cuboid architecture versions are always plain.
  static ArchitectureVersion? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    return ArchitectureVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  @override
  int compareTo(ArchitectureVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(ArchitectureVersion other) => compareTo(other) < 0;
  bool operator <=(ArchitectureVersion other) => compareTo(other) <= 0;
  bool operator >(ArchitectureVersion other) => compareTo(other) > 0;
  bool operator >=(ArchitectureVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is ArchitectureVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => '$major.$minor.$patch';
}
