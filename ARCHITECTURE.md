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
startup flow, and a minimal shell/home experience.

## 3. Current application structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   |-- app_root.dart
|   |-- app.locator.dart       Generated
|   |-- app.logger.dart        Generated
|   `-- app.router.dart        Generated
|-- core/
|   |-- config/
|   |-- constants/
|   |-- enums/
|   |-- errors/
|   |-- formatters/
|   |-- forms/
|   |-- models/
|   |-- network/
|   |-- services/
|   |-- storage/
|   |-- theme/
|   `-- validators/
|-- features/
|   |-- home/
|   |   `-- ui/
|   |       |-- viewmodels/
|   |       |-- views/
|   |       `-- widgets/
|   `-- startup/
|       `-- ui/
|           |-- viewmodels/
|           |-- views/
|           `-- widgets/
`-- shared/
    |-- bottom_sheets/
    |-- dialogs/
    `-- widgets/
```

Supporting folders:

```text
test/        Unit, widget, and bootstrap tests
tool/        Template bootstrap tooling
supabase/    Optional Supabase configuration boundary
doc/design/  Generic design guidance
```

Feature folders may grow as a generated application adds real product
requirements.

## 4. Feature structure

Features use a feature-first Stacked layout:

```text
lib/features/<feature>/
|-- data/                  Optional; only when the feature owns persistent data
`-- ui/
    |-- viewmodels/
    |-- views/
    `-- widgets/           Optional
```

Do not add domain, use-case, or other layer folders merely to make a feature
look more layered. No UseCase layer is required.

`startup` is an application-bootstrap feature and may stay narrower than a
fully built product feature.

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
- access Supabase directly;
- contain application business rules;
- own persistent application state.

ViewModels own screen state, asynchronous orchestration, user-action handling,
navigation requests, and interaction with repositories or shared services.

ViewModels must not hold `BuildContext`.

ViewModels must not call Supabase directly for feature data. When persistent
feature data is added, repositories own backend access.

## 7. Services

Shared reactive services are appropriate only when multiple features require the
same live application state.

The template currently includes `ShellService` for shared shell/navigation
state.

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

When registration or route annotations change, regenerate output:

```bash
dart run build_runner build -d
```

Generated changes are kept only when their editable source changed.

## 9. Core foundations

`lib/core/config/`

Compile-time and runtime configuration helpers.

`lib/core/constants/`

Application constants, asset paths, storage keys, and related static values.

`lib/core/enums/`

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

`lib/core/network/`

Network/backend boundary helpers. The current `SupabaseGuard` handles missing
Supabase configuration and maps backend failures into application failures.

`lib/core/services/`

Application-wide services with shared lifecycle or state.

`lib/core/storage/`

Local storage abstractions.

`lib/core/theme/`

Application theme, colors, and UI helpers.

## 10. Shared presentation

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

## 11. Current data and backend boundary

The template currently has no production repository/data layer and no domain
schema.

Supabase is retained as an optional infrastructure/auth/backend choice. The
presence of `supabase/config.toml` and `SupabaseGuard` does not mean the
template contains active product migrations or a complete backend.

When a generated application introduces persistent feature data, use this flow:

```text
View
  |
ViewModel
  |
Repository
  |
Supabase SDK or another approved data source
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

## 12. Supabase and database authority

Supabase may be used by applications generated from this template for auth,
database, storage, functions, and local development.

Current template state:

- no domain schema;
- no active product migrations;
- no production feature repositories;
- no application-specific RLS policy set;
- no server-side business functions.

PostgreSQL schemas, RLS, authorization, privileged functions, and transactional
rules become application-specific once a generated app introduces persistent
domain data.

Server-side authority applies to application-specific financial, security, and
data-integrity rules. It does not imply nonexistent template features.

Service-role credentials and backend secrets must never be embedded in Flutter
code, assets, logs, tests, screenshots, or committed environment files.

## 13. Testing architecture

The template contains focused tests for implemented foundations and UI.

Tests live under:

```text
test/core/
test/features/
test/shared/
test/tool/
```

Generated applications should expand tests according to the boundaries they add.

Core tests cover result handling, failures, formatting, validation, storage
behavior, network guards, services, and shared models.

ViewModel tests cover state transitions, orchestration, navigation requests,
service interactions, and repository outcomes.

Widget tests cover rendering, user interaction, important states, and reusable
widgets.

Repository tests become relevant when repositories exist. They should cover row
mapping, typed failures, persistence behavior, and authorization boundaries.

Backend tests become application-specific when a backend schema exists.

## 14. Architecture decisions

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

### ADR-4: Supabase remains optional infrastructure

Supabase is an available auth/backend option, not proof that the template has a
domain schema or active product backend.

### ADR-5: No custom API server by default

For applications using Supabase, prefer Supabase's backend boundary unless an
explicit product or infrastructure requirement justifies a custom server.

### ADR-6: Generated Stacked files remain generated

Registration sources are edited manually; generated route and locator files are
regenerated.

Never place custom logic in generated files.

## 15. Current template limitations

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

## 16. Reference files

Core architectural references:

- `README.md`
- `RULES.md`
- `doc/design/ios_polish_pattern.md`
