# Cuboid Flutter Template Architecture

Status: current reusable template architecture

This document describes the architecture that exists in this repository and the
boundaries a generated application should follow when it adds product-specific
features.

The repository is a generic Flutter + Stacked template. It does not currently
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

The template uses Flutter with Stacked MVVM.

The current runtime flow is:

```text
main.dart
    |
AppRoot
    |
Stacked app registration
    |
StartupView
    |
StartupViewModel
    |
ShellView
```

The current repository provides application bootstrap, shared foundations, a
startup flow, an app-level navigation shell, and a minimal Home feature.

## 3. Current application structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   |-- app_root.dart
|   |-- shell_view.dart
|   |-- shell_viewmodel.dart
|   |-- app.locator.dart       Generated
|   |-- app.logger.dart        Generated
|   `-- app.router.dart        Generated
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
test/        Unit, widget, and bootstrap tests
tool/        Template bootstrap tooling
doc/design/  Generic design guidance
```

`lib/core/config/` and `lib/core/network/` are not part of the base template.
They are reintroduced only when a generated application adds backend/storage
configuration or network guards (for example, after running `cuboid create
database supabase`) -- see [12](#12-current-data-and-backend-boundary).

Feature folders may grow as a generated application adds real product
requirements.

## 4. Feature structure

Features use a feature-first Stacked layout:

```text
lib/features/<feature>/
|-- ui/
|   |-- <name>_view.dart       View and ViewModel files, flat (no views/ or
|   |-- <name>_viewmodel.dart  viewmodels/ subdirectories)
|   `-- widgets/               Optional; feature-scoped widgets
`-- data/                      Optional; only when the feature owns
                                persistent data
```

For example, `cuboid create feature home` produces:

```text
lib/features/home/
`-- ui/
    |-- home_view.dart
    `-- home_viewmodel.dart
```

If the feature later owns persistent data, its repository belongs under
`lib/features/<feature>/data/` (for example `home_repository.dart`). `cuboid
create feature` does not generate a repository automatically -- add one only
when the feature actually owns persistent data, matching
[ADR-3](#adr-3-repositories-are-the-persistent-data-boundary).

Do not add domain, use-case, or other layer folders merely to make a feature
look more layered. No UseCase layer is required.

`startup` is an application-bootstrap feature and may stay narrower than a
fully built product feature.

### Application shell vs. features

`ShellView`/`ShellViewModel` (`lib/app/shell_view.dart`,
`lib/app/shell_viewmodel.dart`) are application-level root navigation, not a
feature. The shell owns tab/section switching for the whole app and is backed
by `ShellService` (`lib/core/services/shell_service.dart`, see
[7](#7-services)). It is registered as a normal Stacked route in
`lib/app/app.dart`, the same way a feature view would be, but its source lives
under `lib/app/` because it is composition-root infrastructure, not
product-feature UI.

`Home` (`lib/features/home/`) is an ordinary feature reachable through the
shell's first tab. It owns only Home-specific UI/model/data. Adding a new tab
to the shell means adding a new feature and wiring it into `ShellView`'s tab
list -- it does not mean adding UI to the `home` feature.

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

Shared reactive services are appropriate only when multiple features require the
same live application state.

The template currently includes `ShellService` (`lib/core/services/`) for
shared shell/navigation state. Its presentation layer, `ShellView`/
`ShellViewModel`, lives under `lib/app/` -- see
[Application shell vs. features](#application-shell-vs-features).

Do not create services simply to wrap one method or one repository call.

## 8. Navigation and generated Stacked code

`lib/app/app.dart` is the editable Stacked composition root. It defines
registration for routes, services, repositories, bottom sheets, and dialogs.

Generated Stacked files are outputs and must not receive manual edits:

```text
lib/app/app.router.dart
lib/app/app.locator.dart
lib/app/app.logger.dart
```

Depending on registered Stacked features, generated dialog or bottom-sheet files
may also exist.

Optional Stacked registration folders such as `lib/shared/dialogs/` and
`lib/shared/bottom_sheets/` should be added only when the generated application
registers dialogs or bottom sheets.

When registration or route annotations change, regenerate output:

```bash
dart run build_runner build -d
```

Generated changes are kept only when their editable source changed.

## 9. Cuboid CLI command contract

The public CLI is artifact-oriented under a canonical `create` namespace:

```text
cuboid create <artifact> [arguments] [options]
```

All 12 known artifact categories are implemented and shipped:

```text
app, feature, service, bottomsheet, dialog, storage, database, route, view,
repository, model, widget
```

None fall through to an unimplemented state; `cuboid create <artifact>` for any
of the twelve dispatches to a real generator or registration service. Adding a
13th artifact still requires explicit contract evidence before implementation —
that discipline is unchanged. What has changed is that the twelve above are no
longer speculative: they are implemented, tested (`packages/cuboid/test/`), and
live-smoke-tested against a real generated project as part of release
verification.

Shipped `create` command family:

| Command | Generates | Modifies | Registration | Requires build_runner |
| --- | --- | --- | --- | --- |
| `cuboid create app <display> <package>` | New Flutter project from the template payload | — | Bootstraps package identifiers, Dart project name, bundle IDs | Runs `flutter pub get`, `build_runner`, `dart format` as post-steps (skippable with `--no-post-steps`) |
| `cuboid create feature <name>` | `lib/features/<name>/ui/<name>_view.dart` + `.../ui/<name>_viewmodel.dart` | — | None | No |
| `cuboid create service <name>` | `lib/core/services/<name>_service.dart` | `lib/app/app.dart` | Registers the service as a `LazySingleton` | Yes |
| `cuboid create bottomsheet <name>` | `lib/shared/bottom_sheets/<name>/<name>_sheet.dart` + `_sheet_model.dart` | `lib/app/app.dart`, `lib/main.dart` | Registers the sheet + `setupBottomSheetUi()` call | Yes |
| `cuboid create dialog <name>` | `lib/shared/dialogs/<name>/<name>_dialog.dart` + `_dialog_model.dart` | `lib/app/app.dart`, `lib/main.dart` | Registers the dialog + `setupDialogUi()` call | Yes |
| `cuboid create storage <name>` | `lib/core/storage/<name>_storage.dart` | — | None | No |
| `cuboid create database <provider>` | `lib/supabase/example_model.dart`, `example_repository.dart`, a timestamped migration under `supabase/migrations/` (provider must be `supabase`; no other provider is currently supported) | `lib/app/app.dart` | Registers the example repository | Yes, plus `supabase db push` |
| `cuboid create route <feature>` | — (the feature's view must already exist) | `lib/app/app.dart` | Registers the existing view as a route | Yes |
| `cuboid create view <feature> <name>` | Additional `..._view.dart` + `..._viewmodel.dart` pair, flat inside the feature's `ui/` | — | None | No |
| `cuboid create repository <name>` | `lib/supabase/<name>_model.dart`, `<name>_repository.dart`, a timestamped migration (table name is naively pluralized from `<name>`) | `lib/app/app.dart` | Registers the repository | Yes, plus `supabase db push` |
| `cuboid create model <name>` | `lib/core/models/<name>.dart` | — | None | No |
| `cuboid create widget <name>` or `<feature> <name>` | `lib/shared/widgets/<name>.dart` (shared) or `lib/features/<feature>/ui/widgets/<name>.dart` (feature-scoped; the feature must already exist) | — | None | No |

`database`/`repository` require the Supabase foundation (the `supabase_flutter`
dependency and `lib/core/network/supabase_guard.dart`) to already be present in
the project; they refuse to run otherwise rather than silently scaffolding it.
The base template does not include this foundation by default -- see
[12](#12-current-data-and-backend-boundary). A developer who wants Supabase
adds the dependency and guard themselves before these commands become usable;
the commands do not provision Supabase from nothing.

Dual command surfaces exist for `feature`, `service`, `route`, and `view`:
each also has a legacy top-level form (`cuboid feature <name>`,
`cuboid service <name>`, `cuboid route <feature>`, `cuboid view <feature>
<name>`). For `service` specifically, the two surfaces are **not** aliases:
`cuboid create service <name>` generates the service file and registers it;
the legacy `cuboid service <name>` only registers an already-existing service
file. `feature`, `route`, and `view` behave identically under both surfaces.
The legacy top-level forms are retained implementation history, not deprecated
— no migration or removal has been decided.

Every command above supports `--dry-run`, which validates and reports the
plan without writing anything (verified: dry-run never creates files or
directories).

Safety guarantees enforced uniformly across all 12 generators (verified by
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
  already created, restores any registration file (`app.dart`/`main.dart`) to
  its original contents, and prunes any parent directories the operation
  itself created (empty-only; pre-existing directories are left alone).
- No generator runs `build_runner` automatically. Where regeneration is
  required, the CLI prints the exact next command instead.
- Generated Stacked files (`lib/app/app.router.dart`, `.locator.dart`,
  `.logger.dart`) are never hand-edited by a generator; only the editable
  source (`lib/app/app.dart`) is patched.

A new artifact command (a 13th category, or a new option on an existing one)
still requires: command syntax, required/optional arguments, normalized names,
generated files, modified files, registration/configuration side effects,
dependencies, dry-run behavior, no-overwrite behavior, failure conditions,
rollback/atomicity expectations, filesystem/path safety, package-name
resolution, and exit-code behavior — defined explicitly before implementation,
matching the standard the 12 shipped commands were held to.

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

`lib/core/network/` (not present in the base template)

Network/backend boundary helpers, added once a generated application
introduces a backend. A `SupabaseGuard` that handles missing Supabase
configuration and maps backend failures into application failures belongs
here; `cuboid create database supabase` requires it to already exist (see
[9](#9-cuboid-cli-command-contract)) rather than creating it.

`lib/core/services/`

Application-wide services with shared lifecycle or state.

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
backend choice, introduced only by running `cuboid create database supabase`
(or by a developer manually adding the `supabase_flutter` dependency and
`lib/core/network/supabase_guard.dart`). No generated application is required
to use Supabase, and none is assumed to.

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
test/app/       Composition-root tests (e.g. ShellViewModel)
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

### ADR-1: Feature-first Stacked MVVM

Use feature-first folders with Stacked views and view models.

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

The starter template does not require repositories until a feature actually owns
persistent data.

### ADR-4: The base template is backend/storage-technology-neutral

Supabase, and any other backend/storage technology, is opt-in infrastructure
introduced deliberately through the CLI (`cuboid create database supabase`,
`cuboid create storage <name>`), never pre-installed in the base template. The
base template does not assume or require any backend/storage choice.

### ADR-5: No custom API server by default

For applications using Supabase, prefer Supabase's backend boundary unless an
explicit product or infrastructure requirement justifies a custom server.

### ADR-6: Generated Stacked files remain generated

Registration sources are edited manually; generated route and locator files are
regenerated.

Never place custom logic in generated files.

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
