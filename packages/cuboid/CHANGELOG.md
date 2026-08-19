# Changelog

## 0.1.0 - 2026-08-19

Initial public release.

### Cuboid CLI

- `cuboid create app <display-name> <package-identifier>` stamps out a new
  Flutter project from Cuboid's built-in MVVM starter template, including a
  bootstrap step that renames the project's package identifier, Dart package
  name, and platform identifiers.
- `cuboid create feature <name>` scaffolds a feature (view, view model,
  repository) and registers its route automatically.
- `cuboid create view <name> [feature]` adds an additional view to an
  existing feature (or a shared view) and registers its route.
- `cuboid create service <name>` scaffolds and registers a core service.
- `cuboid create bottomsheet <name>` / `cuboid create dialog <name>` scaffold
  a bottom sheet or dialog and its model, wiring up the owning
  `BottomSheetService` / `DialogService` on first use.
- `cuboid create storage` adds a local key-value/secure storage wrapper.
- `cuboid create database supabase` provisions a Supabase example model,
  repository, and migration, adding the `supabase_flutter` dependency and a
  network guard only when they are missing.
- `cuboid create model <name>` and `cuboid create widget <name> [feature]`
  scaffold a bare model and a shared or feature-scoped widget with its view
  model.
- `cuboid delete <artifact> ...` reverses feature, service, bottom sheet,
  dialog, storage, database, view, widget, and route creation, including
  tearing down bottom sheet/dialog infrastructure when the last one is
  removed.
- Every `create`/`delete` command supports `--dry-run` to preview the plan
  without touching the filesystem, and treats deleting something that was
  never created as an error rather than a silent no-op.
- `lib/app/app.locator.dart`, `app.router.dart`, `app.bottomsheets.dart`, and
  `app.dialogs.dart` are patched directly as plain Dart -- no code-generation
  step is required after any command.

### Template and runtime

- The Flutter app template (project structure, MVVM bootstrap, navigation,
  and the `cuboid_flutter` runtime package) is embedded directly in the CLI
  binary, so `cuboid create app` works identically whether the CLI runs from
  source or as a compiled executable, with no dependency on the developer's
  checkout.
- `cuboid_flutter` (the `CuboidView`/`CuboidViewModel` MVVM runtime) is
  vendored into a machine-global cache on first use and referenced from each
  generated project via a `path:` dependency, keeping it out of the
  generated project's visible source tree.
- Generated projects follow a feature-first MVVM structure
  (`lib/app`, `lib/core`, `lib/features`, `lib/shared`) with a
  technology-neutral base -- no backend or storage technology is installed
  until a project asks for one.

### Quality

- Broad unit test coverage across every create/delete command, the project
  bootstrap step, the template packaging/sync tooling, and the installer.
