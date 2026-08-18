# Cuboid Flutter Template

Reusable Flutter starter template for Cuboid applications, built on Cuboid's
own MVVM, dependency injection, and routing.

This repository is infrastructure for starting a new app. It is not a production
domain application and does not contain application-specific business workflows,
database schema, or repository/data layers.

## Technology

- Flutter and Dart
- Cuboid's own in-house MVVM, routing, service locator (get_it-based),
  dialogs, and bottom sheets -- no third-party MVVM framework
- Technology-neutral base: no backend or storage technology is pre-installed;
  add one explicitly via the Cuboid CLI (e.g. `cuboid create database
  supabase`, `cuboid create storage`) when a project actually needs one
- Focused unit and widget tests
- Bootstrap tooling for renaming a generated app from the template

## Directory structure

```text
lib/
|-- app/                  Locator, router, app root (CLI-patched, hand-editable)
|-- core/                 Constants, errors, formatters, forms, models, mvvm,
|                         services, storage, theme, and validators
|-- features/
|   |-- startup/          Startup view and view model
|   `-- home/             Home feature
`-- shared/
    `-- widgets/          Reusable UI widgets

test/                     Unit, widget, and bootstrap tests
tool/                     Template bootstrap tooling
doc/design/               Generic design guidance
```

`lib/core/config/` and `lib/core/network/` are not part of the base
template -- they're added once a generated app needs backend configuration or
network guards. See [ARCHITECTURE.md §10](ARCHITECTURE.md#10-core-foundations).

`lib/app/app.locator.dart` and `lib/app/app.router.dart` are plain,
hand-maintained Dart -- not code-generated output. Edit them directly, or let
`cuboid create <artifact>` patch them idempotently.

## Bootstrap a new application

Use the bootstrap tool before product-specific development:

```bash
dart run tool/bootstrap.dart --help
```

The bootstrap updates the template identity for a new application. Review the
resulting diff before adding product code.

## Cuboid CLI

`packages/cuboid` is a Dart CLI (`cuboid`) that stamps out new projects from
this template and scaffolds artifacts inside a generated project. It is not
published to pub.dev; install it locally from a checkout of this repository:

```bash
dart pub global activate --source path packages/cuboid
```

Create a new project (an alternative to `tool/bootstrap.dart` for starting a
brand-new project directory, rather than renaming this checkout in place):

```bash
cuboid create app "My App" com.example.myapp
```

Package identifiers (`com.example.myapp`) may use letters and numbers, each
dot-separated segment must start with a letter.

Inside a generated project, scaffold artifacts with `cuboid create <artifact>`:

```text
cuboid create feature <name>           # also creates its repository and route
cuboid create service <name>
cuboid create bottomsheet <name>       # patches app.bottomsheets.dart itself
cuboid create dialog <name>            # patches app.dialogs.dart itself
cuboid create storage
cuboid create database supabase
cuboid create view <name> <feature>    # also registers the view's route
cuboid create model <name>
cuboid create widget <name>            # shared, under lib/shared/widgets/<name>/
cuboid create widget <name> <feature>  # feature-scoped
```

There is no separate `route` or `repository` command: creating a feature
generates and registers its repository, and creating a feature or view
registers its route, automatically.

Every command supports `--dry-run` to preview the plan without writing
anything. No command needs a code-generation step afterward: `lib/app/
app.locator.dart`, `app.router.dart`, `app.bottomsheets.dart`, and
`app.dialogs.dart` are plain Dart files each command patches directly. Full
per-command contracts (generated files, registration behavior, safety
guarantees) live in
[ARCHITECTURE.md §9](ARCHITECTURE.md#9-cuboid-cli-command-contract).

## Local development

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run
```

## Optional backend/storage setup

The base template has no backend or storage technology installed. Add one
explicitly when a project actually needs it:

```bash
cuboid create database supabase   # Supabase example model, repository, migration
cuboid create storage              # A local key-value/secure storage wrapper
```

`cuboid create database supabase` provisions its own Supabase foundation: it
adds the `supabase_flutter` dependency to `pubspec.yaml` and creates
`lib/core/network/supabase_guard.dart` when either is missing, so it does not
require a developer to add them first. See
[ARCHITECTURE.md §12-13](ARCHITECTURE.md#12-current-data-and-backend-boundary)
for the full contract.

Once a project has persistent feature data:

- repositories own backend access and row/model mapping;
- ViewModels consume repositories instead of calling a backend SDK directly;
- PostgreSQL schemas, RLS policies, privileged functions, and server authority
  are application-specific and must be documented with that app's product rules;
- service-role keys and secrets must never be embedded in the Flutter app.

## Validation

For documentation-only changes, review paths, links, and diffs. For code changes,
run the relevant checks:

```bash
dart format <changed Dart files>
flutter analyze
flutter test
git diff --check
```

## Start a product from the template

1. Run the bootstrap tool to rename package and app identity.
2. Keep the template infrastructure generic until the product boundary is clear.
3. Add feature folders under `lib/features/<feature>/`.
4. Add repositories only when a feature introduces persistent data.
5. Define application-specific backend schema, RLS, and server-side rules in the
   generated application, not in the starter template.

Architecture and engineering rules:

- [ARCHITECTURE.md](ARCHITECTURE.md)
- [RULES.md](RULES.md)
- [doc/design/ios_polish_pattern.md](doc/design/ios_polish_pattern.md)
