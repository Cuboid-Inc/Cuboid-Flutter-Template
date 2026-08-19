# Cuboid Flutter Template Architecture

Status: current reusable template architecture

This document describes the architecture that exists in this repository and the
boundaries a generated application should follow when it adds product-specific
features.

The repository is a generic Flutter template using Cuboid's own MVVM,
dependency injection, and routing. It does not currently
contain a production business domain, production repository/data layer, active
product migrations, or application-specific database schema.

Development and AI-agent implementation rules live in `RULES.md`. Design
patterns that remain generic live under `doc/design/`.

## 1. Source-of-truth boundaries

- `ARCHITECTURE.md` defines code structure, dependency direction, state flow,
  generation rules, and backend boundaries.
- `RULES.md` defines implementation, review, validation, and AI-agent rules.
- `doc/design/` contains reusable UI guidance only.
- Existing implementation is evidence of current state, not authority for adding
  product scope.

Deleted product references under `doc/` are archived history, not active
authority for this template. Do not restore or cite removed product documents as
current requirements.

When sources conflict, stop and resolve the conflict before changing behavior.

## 2. Current runtime shape

The template uses Flutter with Cuboid's own in-house MVVM, dependency
injection, and routing -- there is no third-party MVVM framework dependency.

The MVVM implementation itself (`CuboidView`/`CuboidViewModel`) lives outside
the application's `lib/` tree, in a separate framework package:

```text
Cuboid CLI (packages/cuboid)
    |
Cuboid runtime/framework (packages/cuboid_flutter)
    |
Generated application (lib/app, lib/features, lib/shared, lib/main.dart)
```

`packages/cuboid_flutter` is vendored into the repository root and into every
`cuboid create app` output, and depended on via a `path:` entry in
`pubspec.yaml` -- see [10](#10-core-foundations). The application's `lib/`
tree contains only application code.

The current runtime flow is:

```text
main.dart
    |
setupLocator() (lib/app/app.locator.dart)
    |
AppRoot (MaterialApp using lib/app/app.router.dart)
    |
StartupView
    |
StartupViewModel
    |
HomeView
```

The current repository provides application bootstrap, shared foundations, a
startup flow, and a minimal Home feature. There is no application-level
navigation shell in the base template; `cuboid create feature` registers each
feature's view as its own route (see [9](#9-cuboid-cli-command-contract)), and
a generated application that needs tab/section navigation adds that
composition-root infrastructure itself once it actually has more than one
top-level destination.

## 3. Current application structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app_root.dart
|   |-- app.locator.dart       CLI-patched; DI setup (get_it)
|   |-- app.logger.dart        Hand-maintained app logger
|   `-- app.router.dart        CLI-patched; route table
|-- core/
|   |-- constants/
|   |-- errors/
|   |-- formatters/
|   |-- forms/
|   |-- models/
|   |-- services/
|   |-- storage/
|   |-- theme/
|   `-- validators/
|-- features/
|   |-- home/
|   |   `-- ui/
|   `-- startup/
|       `-- ui/
`-- shared/
    `-- widgets/
```

Supporting folders:

```text
packages/cuboid_flutter/  Cuboid's MVVM runtime (CuboidView/CuboidViewModel),
                          a framework package depended on via `path:` --
                          not part of the application's own lib/ tree
test/                     Unit, widget, and bootstrap tests
tool/                     Template bootstrap tooling
doc/design/               Generic design guidance
```

`lib/core/config/` and `lib/core/network/` are not part of the base template.
They are reintroduced only when a generated application adds backend/storage
configuration or network guards (for example, after running `cuboid create
database supabase`) -- see [12](#12-current-data-and-backend-boundary).

Feature folders may grow as a generated application adds real product
requirements.

## 4. Feature structure

Features use a feature-first Cuboid layout:

```text
lib/features/<feature>/
|-- ui/
|   |-- <name>_view.dart       View and ViewModel files, flat (no views/ or
|   |-- <name>_viewmodel.dart  viewmodels/ subdirectories)
|   `-- widgets/               Optional; feature-scoped widgets
`-- data/
    `-- <feature>_repository.dart  The feature's persistent-data boundary
```

For example, `cuboid create feature home` produces:

```text
lib/features/home/
|-- ui/
|   |-- home_view.dart
|   `-- home_viewmodel.dart
`-- data/
    `-- home_repository.dart
```

`cuboid create feature` always generates the feature's repository under
`lib/features/<feature>/data/` and registers it as a `LazySingleton` in
`lib/app/app.locator.dart`, and it registers the feature's view as a route in
`lib/app/app.router.dart` -- see [9](#9-cuboid-cli-command-contract). The
repository starts as an empty,
technology-neutral shell; wire it to a real data source once the feature
actually owns persistent data, matching
[ADR-3](#adr-3-repositories-are-the-persistent-data-boundary).

Do not add domain, use-case, or other layer folders merely to make a feature
look more layered. No UseCase layer is required.

`startup` is an application-bootstrap feature and may stay narrower than a
fully built product feature.

`Home` (`lib/features/home/`) is an ordinary feature, registered as a normal
route in `lib/app/app.router.dart` like any other `cuboid create feature`
output. The
base template has no application-level navigation shell (tab bar, drawer,
etc.); it owns only Home-specific UI/model/data. A generated application that
needs tab/section navigation across multiple features adds that
composition-root infrastructure itself under `lib/app/` -- it does not belong
inside a feature folder.

## 5. Dependency direction

Dependencies point toward shared code and infrastructure boundaries:

```text
Feature UI
    |
    v
Feature repositories/data       Only when persistent feature data exists
    |
    v
Core infrastructure
```

Rules:

- Code under `lib/core/` must not import `lib/features/`.
- Feature UI code may depend on `lib/core/` and `lib/shared/`.
- One feature must not import another feature's UI.
- Shared presentation widgets belong under `lib/shared/widgets/`.
- Cross-feature models belong in the owning feature or in `lib/core/models/`
  only when they are genuinely shared.

## 6. Presentation architecture

Views render state, compose widgets, and forward user actions to their
ViewModels.

Views must not:

- access repositories directly;
- access a backend SDK (e.g. Supabase) directly;
- contain application business rules;
- own persistent application state.

ViewModels own screen state, asynchronous orchestration, user-action handling,
navigation requests, and interaction with repositories or shared services.

ViewModels must not hold `BuildContext`.

ViewModels must not call a backend SDK directly for feature data. When
persistent feature data is added, repositories own backend access.

## 7. Services

`lib/core/services/` ships one framework service in the base template --
`NavigationService`, used by view models to navigate without holding a
`BuildContext` (see [8](#8-navigation-locator-and-routing-files)). Beyond
that, shared reactive services are appropriate only when multiple features
require the same live application state. `cuboid create service <name>`
scaffolds an app-level service alongside it in `lib/core/services/` and
registers it (see [9](#9-cuboid-cli-command-contract)).

Do not create services simply to wrap one method or one repository call.

## 8. Navigation, locator, and routing files

Cuboid does not use a third-party MVVM/DI/routing framework or code
generation for these concerns. Three files under `lib/app/` are
hand-maintained, plain Dart, and are also the files the Cuboid CLI patches
directly (idempotently, via marker comments) when it registers a new
artifact:

```text
lib/app/app.locator.dart   DI setup: `locator` (a get_it instance) and
                            setupLocator(), registering services and
                            repositories as LazySingleton
lib/app/app.router.dart    Route-name constants (`Routes`), the
                            `appRoutes` builder map, and `onGenerateRoute`
lib/app/app.logger.dart    The app's `AppLogger` helper (package:logger)
```

Depending on which optional artifacts a generated application has added,
`lib/app/app.bottomsheets.dart` and/or `lib/app/app.dialogs.dart` may also
exist, each holding a `Map<Type, WidgetBuilder>` of registered sheets/dialogs
keyed by their view model type.

Optional registration folders such as `lib/shared/dialogs/` and
`lib/shared/bottom_sheets/` should be added only when the generated
application registers dialogs or bottom sheets.

These files are not code-generated output: edit them directly for manual
changes, and expect `cuboid create <artifact>` commands to patch them for
generated ones. No build step is required to keep them valid -- there is no
`build_runner` step in this template.

## 9. Cuboid CLI command contract

The public CLI is artifact-oriented under a canonical `create` namespace:

```text
cuboid create <artifact> [arguments] [options]
```

All 10 known artifact categories are implemented and shipped:

```text
app, feature, service, bottomsheet, dialog, storage, database, view, model,
widget
```

None fall through to an unimplemented state; `cuboid create <artifact>` for any
of the ten dispatches to a real generator or registration service. Adding an
11th artifact still requires explicit contract evidence before implementation —
that discipline is unchanged. What has changed is that the ten above are no
longer speculative: they are implemented, tested (`packages/cuboid/test/`), and
live-smoke-tested against a real generated project as part of release
verification.

There is no standalone `route` or `repository` artifact. A View always has a
route, and a feature always has a repository, so `cuboid create feature` and
`cuboid create view` register the route as part of creating the view, and
`cuboid create feature` generates and registers the feature's repository at
the same time -- see the table below. A prior, separately-run `cuboid create
route`/`cuboid create repository` (and their legacy `cuboid route`/`cuboid
repository` top-level forms) duplicated that work as an extra manual step and
had drifted into requiring Supabase for a plain repository; both were removed
rather than kept as redundant, backend-coupled commands.

Shipped `create` command family:

| Command | Generates | Modifies | Registration |
| --- | --- | --- | --- |
| `cuboid create app <display> <package>` | New Flutter project from the template payload | — | Bootstraps package identifiers, Dart project name, app class name, bundle IDs; runs `flutter pub get` and `dart format` as post-steps (skippable with `--no-post-steps`) |
| `cuboid create feature <name>` | `lib/features/<name>/ui/<name>_view.dart` + `.../ui/<name>_viewmodel.dart` + `.../data/<name>_repository.dart` | `lib/app/app.locator.dart`, `lib/app/app.router.dart` | Registers the view as a route and the repository as a `LazySingleton` |
| `cuboid create service <name>` | `lib/core/services/<name>_service.dart` | `lib/app/app.locator.dart` | Registers the service as a `LazySingleton` |
| `cuboid create bottomsheet <name>` | `lib/shared/bottom_sheets/<name>/<name>_sheet.dart` + `_sheet_model.dart` | `lib/app/app.locator.dart` (first use only), `lib/app/app.bottomsheets.dart` | Registers `BottomSheetService` (first use) and the sheet's builder |
| `cuboid create dialog <name>` | `lib/shared/dialogs/<name>/<name>_dialog.dart` + `_dialog_model.dart` | `lib/app/app.locator.dart` (first use only), `lib/app/app.dialogs.dart` | Registers `DialogService` (first use) and the dialog's builder |
| `cuboid create storage` | `lib/core/storage/local_storage.dart` | — | None |
| `cuboid create database <provider>` | `lib/supabase/example_model.dart`, `example_repository.dart`, a timestamped migration under `supabase/migrations/` (provider must be `supabase`; no other provider is currently supported) | `lib/app/app.locator.dart`, `pubspec.yaml`, `lib/core/network/supabase_guard.dart` | Registers the example repository; provisions the `supabase_flutter` dependency and the guard file when either is missing |
| `cuboid create view <name> <feature>` | Additional `..._view.dart` + `..._viewmodel.dart` pair, flat inside the feature's `ui/` | `lib/app/app.router.dart` | Registers the new view as a route |
| `cuboid create model <name>` | `lib/core/models/<name>.dart` | — | None |
| `cuboid create widget <name>` or `<name> <feature>` | `lib/shared/widgets/<name>/<name>_widget.dart` + `<name>_view_model.dart` (shared) or `lib/features/<feature>/ui/widgets/<name>/<name>_widget.dart` + `<name>_view_model.dart` (feature-scoped; the feature must already exist) | — | None |

No command needs `build_runner`: locator, router, and bottom sheet/dialog
registries are plain, CLI-patched Dart files, not code-generated output.

`database` provisions its own Supabase foundation: it adds the
`supabase_flutter` dependency to `pubspec.yaml` and creates
`lib/core/network/supabase_guard.dart` when either is missing (idempotently --
an existing dependency or guard file is left untouched), then generates the
example repository against it. See [12](#12-current-data-and-backend-boundary)
and [13](#13-supabase-and-database-authority).

Dual command surfaces exist for `feature`, `service`, and `view`: each also
has a legacy top-level form (`cuboid feature <name>`, `cuboid service <name>`,
`cuboid view <name> <feature>`). For `service` specifically, the two surfaces
are **not** aliases: `cuboid create service <name>` generates the service file
and registers it; the legacy `cuboid service <name>` only registers an
already-existing service file. `feature` and `view` behave identically under
both surfaces. The legacy top-level forms are retained implementation history,
not deprecated — no migration or removal has been decided.

Every command above supports `--dry-run`, which validates and reports the
plan without writing anything (verified: dry-run never creates files or
directories).

Safety guarantees enforced uniformly across all 10 generators (verified by
source inspection and tests, not assumed):

- Name normalization rejects path separators, `.`/`..` traversal, empty names,
  and Dart keywords; accepted names are letters/numbers joined by `_`/`-`,
  normalized to lower snake_case.
- Collision protection: existing target files/directories/symlinks are
  refused before any write.
- Symlink/traversal protection: every generator that creates files validates
  that each ancestor path segment between the project root and the target
  stays a real directory (not a symlink, not outside the project).
- Rollback: a failure partway through a multi-file write deletes files it had
  already created, restores any registration file (`app.locator.dart`,
  `app.router.dart`, `app.bottomsheets.dart`, `app.dialogs.dart`) to its
  original contents, and prunes any parent directories the operation itself
  created (empty-only; pre-existing directories are left alone).
- No generator needs `build_runner`: `lib/app/app.locator.dart`,
  `app.router.dart`, `app.bottomsheets.dart`, and `app.dialogs.dart` are
  plain Dart files patched directly and idempotently via marker comments
  (`// @cuboid-import`, `// @cuboid-service`, `// @cuboid-route`, etc.) --
  there is no generated/source split and no codegen step to run afterward.

A new artifact command (an 11th category, or a new option on an existing one)
still requires: command syntax, required/optional arguments, normalized names,
generated files, modified files, registration/configuration side effects,
dependencies, dry-run behavior, no-overwrite behavior, failure conditions,
rollback/atomicity expectations, filesystem/path safety, package-name
resolution, and exit-code behavior — defined explicitly before implementation,
matching the standard the 10 shipped commands were held to.

Shipped `delete` command family (the structural mirror image of `create`,
under `cuboid delete <artifact> [arguments] [options]`):

| Command | Removes | Modifies | De-registration / teardown condition |
| --- | --- | --- | --- |
| `cuboid delete service <name>` | `lib/core/services/<name>_service.dart` | `lib/app/app.locator.dart` | Removes the service's import and registration. Refuses `navigation`, `dialog`, and `bottom_sheet` -- those are owned by the framework or by `delete dialog`/`delete bottomsheet` |
| `cuboid delete feature <name>` | `lib/features/<name>/` (recursive) | `lib/app/app.locator.dart`, `lib/app/app.router.dart` | Removes the route for every View found under the feature's `ui/` (the primary View and any added later via `create view`); removes the repository registration only if present (hand-written base-template features have none, and that absence is not an error) |
| `cuboid delete bottomsheet <name>` | `lib/shared/bottom_sheets/<name>/` (recursive) | `lib/app/app.bottomsheets.dart`; `lib/app/app.locator.dart` and `lib/core/services/bottom_sheet_service.dart` only when last | Removes this sheet's two imports and builder entry from `app.bottomsheets.dart`. If it was the last one, also deletes `app.bottomsheets.dart` itself and tears down `BottomSheetService` |
| `cuboid delete dialog <name>` | `lib/shared/dialogs/<name>/` (recursive) | `lib/app/app.dialogs.dart`; `lib/app/app.locator.dart` and `lib/core/services/dialog_service.dart` only when last | Removes this dialog's two imports and builder entry from `app.dialogs.dart`. If it was the last one, also deletes `app.dialogs.dart` itself and tears down `DialogService` |
| `cuboid delete storage` | `lib/core/storage/local_storage.dart` | — | None |
| `cuboid delete database <provider>` | `lib/supabase/example_model.dart`, `example_repository.dart`, its timestamped migration under `supabase/migrations/`, `lib/core/network/supabase_guard.dart` | `lib/app/app.locator.dart`, `pubspec.yaml` | Removes the repository registration and the `supabase_flutter` dependency line. Since only one database resource can ever exist, this is always a full teardown; an ambiguous migration match (more than one `*_create_examples.sql`) is refused rather than guessed |
| `cuboid delete view <name>` or `<name> <feature>` | The `..._view.dart` + `..._viewmodel.dart` pair | `lib/app/app.router.dart` | Removes the route. Prunes `lib/shared/views/` if it becomes empty (shared views only) |
| `cuboid delete widget <name>` or `<name> <feature>` | The widget's own directory (recursive) | — | None. Prunes the widgets container directory if it becomes empty, never the feature's `ui/` directory itself |
| `cuboid delete route <name>` | Nothing (no View/ViewModel files touched) | `lib/app/app.router.dart` | Removes the route only; the narrow inverse of automatic route registration, for un-registering a route by hand without deleting its files |

There is no `cuboid delete model` or `cuboid delete app`. Deleting a resource
that was never created is an error (`<Type> not found: <name>`), not a silent
no-op, matching how every `create` command treats unexpected state -- this is
also what makes repeated deletion fail safely rather than corrupt anything.

**Shared infrastructure ownership.** `DialogService` / `app.dialogs.dart` and
`BottomSheetService` / `app.bottomsheets.dart` are each owned collectively by
every dialog (or bottom sheet) that currently exists, not by whichever one
happened to create them first. Deleting counts how many builder-map entries
remain in the registry file *before* removing anything: if this is the last
entry, the whole registry file and its owning service are torn down as part
of the same deletion; if others remain, only this resource's own two import
lines and one builder entry are removed, and the registry file, the service,
and its locator registration are left completely untouched. `lib/app/
app.locator.dart` and `lib/app/app.router.dart` themselves are foundational
and are never deleted by any `delete` command -- only the entries a matching
`create` command had added to them.

## 10. Core foundations

`lib/core/config/` (not present in the base template)

Compile-time and runtime configuration helpers, added once a generated
application needs them (for example backend configuration after `cuboid
create database supabase`).

`lib/core/constants/`

Application constants, asset paths, and related static values.

Optional `lib/core/enums/`

Shared enums and wire/serialization helpers when the template or generated app
needs them.

`lib/core/errors/`

Typed failures and `Result<T>` primitives for explicit success/failure handling.

`lib/core/formatters/`

Shared formatting helpers for dates, times, and display text.

`lib/core/forms/` and `lib/core/validators/`

Reusable form and validation helpers.

`lib/core/models/`

Shared models that do not have a clear single feature owner.

`packages/cuboid_flutter/` (framework package, outside `lib/`)

`CuboidView` and `CuboidViewModel`, the base classes every View/ViewModel in
the template and every `cuboid create feature`/`view`/`widget`/
`bottomsheet`/`dialog` output extends. This is Cuboid's runtime/framework
layer, not application code: a separate Dart/Flutter package vendored into
the repository root and into every generated application, depended on via a
`path: packages/cuboid_flutter` entry in `pubspec.yaml` rather than shipping
framework source inside the application's own `lib/` tree. Generated code
imports it as `package:cuboid_flutter/cuboid_flutter.dart`. See
[6](#6-presentation-architecture).

`lib/core/network/` (not present in the base template)

Network/backend boundary helpers, added once a generated application
introduces a backend. A `SupabaseGuard` that handles missing Supabase
configuration and maps backend failures into application failures belongs
here; `cuboid create database supabase` requires it to already exist (see
[9](#9-cuboid-cli-command-contract)) rather than creating it.

`lib/core/services/`

Application-wide services with shared lifecycle or state. Ships
`NavigationService` in the base template (see
[8](#8-navigation-locator-and-routing-files)); `cuboid create service`
adds app-level services here.

`lib/core/storage/`

Local storage abstractions.

`lib/core/theme/`

Application theme, colors, and UI helpers.

## 11. Shared presentation

Reusable presentation code lives under:

```text
lib/shared/widgets/
```

Current examples include app bars, buttons, form controls, loading indicators,
empty states, and paginated list widgets.

Feature-specific widgets remain under:

```text
lib/features/<feature>/ui/widgets/
```

Do not duplicate a shared widget inside a feature when the widget has no
feature-specific responsibility.

## 12. Current data and backend boundary

The base template has no backend/storage technology, no production
repository/data layer, and no domain schema. It is technology-neutral: it does
not assume Supabase, Firebase, or any other backend/storage choice.

A generated application introduces a backend deliberately, through the CLI,
when it actually needs one -- for example `cuboid create database supabase`
(see [9](#9-cuboid-cli-command-contract)). Nothing in the base template
requires this step; an app with no persistent feature data never needs to take
it.

`cuboid create feature` generates an empty, technology-neutral repository
shell for every feature (see [4](#4-feature-structure)) so the persistent-data
boundary exists from the start; it does not, by itself, introduce a backend.
A feature's repository stays an empty shell -- and never imports a backend
SDK -- until the application wires it to a real data source.

When a generated application does introduce persistent feature data, use this
flow:

```text
View
  |
ViewModel
  |
Repository
  |
Backend SDK (e.g. Supabase) or another approved data source
  |
Application-specific backend schema and policies
```

Repositories should:

- own backend data access;
- map backend rows into application models;
- return `Result<T>` where the operation is fallible;
- prevent backend exceptions from crossing the repository boundary;
- never import UI code.

ViewModels consume repositories rather than calling backend SDKs directly for
feature data.

## 13. Supabase and database authority

Supabase is not part of the base template. It is available as an opt-in
backend choice, introduced only by running `cuboid create database supabase`,
which provisions the `supabase_flutter` dependency and
`lib/core/network/supabase_guard.dart` itself (idempotently, alongside any
already present) rather than requiring a developer to add them first. No
generated application is required to use Supabase, and none is assumed to.

Once a generated application has introduced Supabase:

- it starts with no domain schema and no active product migrations beyond the
  example the CLI generated;
- no application-specific RLS policy set or server-side business function
  exists until the application adds one;
- PostgreSQL schemas, RLS, authorization, privileged functions, and
  transactional rules become application-specific from that point on.

Server-side authority applies to application-specific financial, security, and
data-integrity rules. It does not imply the base template contains these
features.

Service-role credentials and backend secrets must never be embedded in Flutter
code, assets, logs, tests, screenshots, or committed environment files.

## 14. Testing architecture

The template contains focused tests for implemented foundations and UI.

Tests live under:

```text
test/app/       Composition-root tests (app bootstrap and locator wiring)
test/core/
test/features/
test/shared/
test/tool/
```

Generated applications should expand tests according to the boundaries they add.

Core tests cover result handling, failures, formatting, validation, storage
behavior, services, and shared models. Network guard tests become relevant
once a generated application introduces a backend (e.g. `lib/core/network/`
after `cuboid create database supabase`).

ViewModel tests cover state transitions, orchestration, navigation requests,
service interactions, and repository outcomes.

Widget tests cover rendering, user interaction, important states, and reusable
widgets.

Repository tests become relevant when repositories exist. They should cover row
mapping, typed failures, persistence behavior, and authorization boundaries.

Backend tests become application-specific when a backend schema exists.

## 15. Architecture decisions

### ADR-1: Feature-first Cuboid MVVM

Use feature-first folders with `CuboidView`/`CuboidViewModel` views and view
models (see [10](#10-core-foundations)).

This keeps screen ownership clear while allowing shared infrastructure under
`core/` and shared presentation under `shared/`.

### ADR-2: No mandatory UseCase layer

ViewModels may call repositories directly.

Do not add pass-through UseCases.

Introduce another application layer only when a real architectural boundary
requires it.

### ADR-3: Repositories are the persistent data boundary

When persistent feature data exists, repositories isolate UI code from backend
implementation details.

Every feature gets a repository -- `cuboid create feature` generates it
alongside the feature's UI (see [4](#4-feature-structure)) -- but it starts as
an empty, technology-neutral shell. A feature is never required to wire it to
a real data source; nothing about having the file assumes or requires
persistent data. Repositories are not a standalone CLI command: they belong to
the feature that owns them, not to a backend technology (there is no
`cuboid create repository`; see [9](#9-cuboid-cli-command-contract)).

### ADR-4: The base template is backend/storage-technology-neutral

Supabase, and any other backend/storage technology, is opt-in infrastructure
introduced deliberately through the CLI (`cuboid create database supabase`,
`cuboid create storage`), never pre-installed in the base template. The
base template does not assume or require any backend/storage choice.

### ADR-5: No custom API server by default

For applications using Supabase, prefer Supabase's backend boundary unless an
explicit product or infrastructure requirement justifies a custom server.

### ADR-6: Locator, router, and UI-registry files stay CLI-patched, not hand-authored business logic

`lib/app/app.locator.dart`, `app.router.dart`, `app.bottomsheets.dart`, and
`app.dialogs.dart` hold only registration/wiring, edited directly or patched
by the CLI (see [8](#8-navigation-locator-and-routing-files)).

Never place application business logic in these files.

## 16. Current template limitations

The current repository intentionally does not claim to contain:

- a complete authentication product flow;
- a production repository layer;
- a business domain;
- product database migrations;
- production reporting;
- production document generation;
- production offline synchronization;
- product-specific security, financial, or compliance rules.

Those concerns belong to applications generated from the template.

## 17. Reference files

Core architectural references:

- `README.md`
- `RULES.md`
- `doc/design/ios_polish_pattern.md`
