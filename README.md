# Cuboid Flutter Template

Reusable Flutter + Stacked starter template for Cuboid applications.

This repository is infrastructure for starting a new app. It is not a production
domain application and does not contain application-specific business workflows,
database schema, or repository/data layers.

## Technology

- Flutter and Dart
- Stacked MVVM, routing, service locator, dialogs, and bottom sheets
- Optional Supabase client configuration for auth/backend use
- Focused unit and widget tests
- Bootstrap tooling for renaming a generated app from the template

## Directory structure

```text
lib/
|-- app/                  Stacked registration, router, locator, app root
|-- core/                 Config, constants, errors, formatters, forms,
|                         models, network guards, services, storage, theme,
|                         and validators
|-- features/
|   |-- startup/          Startup view and view model
|   `-- home/             Minimal shell/home experience
`-- shared/
    `-- widgets/          Reusable UI widgets

test/                     Unit, widget, and bootstrap tests
tool/                     Template bootstrap tooling
supabase/                 Optional Supabase local configuration boundary
doc/design/               Generic design guidance
```

Generated Stacked files live under `lib/app/` and should be regenerated from
their editable sources, not edited by hand.

## Bootstrap a new application

Use the bootstrap tool before product-specific development:

```bash
dart run tool/bootstrap.dart --help
```

The bootstrap updates the template identity for a new application. Review the
resulting diff before adding product code.

## Local development

Install dependencies:

```bash
flutter pub get
```

Run the app:

```bash
flutter run --dart-define-from-file=env/dev.json
```

Regenerate Stacked output after changing Stacked registration or route
annotations:

```bash
dart run build_runner build -d
```

## Optional Supabase setup

Supabase is retained as an optional infrastructure/auth/backend choice. The
template currently has no domain schema, no active product migrations, and no
production repository layer.

When an app introduces persistent feature data:

- repositories own backend access and row/model mapping;
- ViewModels consume repositories instead of calling Supabase directly;
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
