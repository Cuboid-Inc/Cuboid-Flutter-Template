/// The installed Cuboid CLI's own version.
///
/// Distinct from a generated project's *architecture version* (see
/// `architecture/architecture_version.dart`) and from the `cuboid_flutter`
/// runtime package's own `pubspec.yaml` version -- three related but
/// independent numbers. Kept in its own file (rather than inline in
/// `cli/cuboid_command_runner.dart`, where it originally lived) so
/// `create/create_project.dart` can record it in a newly generated
/// project's `.cuboid/project.json` without importing the CLI layer.
const cuboidVersion = '0.1.0';
