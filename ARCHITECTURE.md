# Cuboid Flutter Template Architecture

Status: Current template architecture and production extension target

This document defines the architecture of the reusable Cuboid Flutter Template.

It distinguishes between:

* **Current template** — code and structure that actually exist in this repository.
* **Production target** — architecture an application generated from this template may grow into.

Development and AI-agent implementation rules live in `RULES.md`. Product behavior and business rules live in the documents under `doc/`.

---

## 1. Source-of-truth boundaries

Use repository documents for different concerns:

* `ARCHITECTURE.md` — code structure, dependency direction, state flow, and backend boundaries.
* `RULES.md` — development, implementation, review, and AI-agent standards.
* `doc/Transport_Fleet_MVP_Blueprint.md` — product/business rules, calculations, financial states, security, and acceptance scenarios.
* `doc/Transport_Fleet_MVP_Design_Brief.md` — screen behavior, wording, accessibility, and interaction details.

Existing implementation is evidence of the current state, not authority for changing product requirements.

When sources conflict, stop and resolve the conflict rather than silently changing one source to match another.

---

## 2. Current template architecture

The template uses Flutter with Stacked MVVM.

The current repository is intentionally small. It provides application bootstrap, shared foundations, a startup flow, and a minimal home/shell experience.

The current runtime flow is:

```text
main.dart
    |
AppRoot
    |
Stacked App registration
    |
StartupView
    |
StartupViewModel
    |
ShellView
```

### Current application structure

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
|           `-- views/
`-- shared/
    `-- widgets/
```

The exact contents of `core/`, `features/`, and `shared/` may grow as an application is built from the template. New code must follow the conventions in `RULES.md`.

### Current feature structure

Generated features use:

```text
lib/features/<feature>/
|-- data/                  Optional
`-- ui/
    |-- viewmodels/
    |-- views/
    `-- widgets/           Optional
```

The current `home` feature demonstrates the UI structure with views, view models, and feature-specific widgets.

`startup` is an intentional application-bootstrap exception. Its current structure is:

```text
lib/features/startup/ui/
|-- viewmodels/
`-- views/
```

Do not add domain, use-case, or other layer folders merely to make the feature appear more layered.

---

## 3. Dependency direction

The architecture follows a dependency direction toward shared code and infrastructure boundaries.

```text
Feature UI
    |
    v
Feature data/repositories      Production applications
    |
    v
Core infrastructure
```

The current template does not contain a feature repository/data layer.

When persistent business data is introduced, repositories become the data boundary between view models and backend or local data sources.

### Core dependency rule

Code under `lib/core/` must not import:

* `lib/features/`
* `lib/ui/`

Feature UI code may depend on core code.

One feature must not import another feature's UI.

Cross-feature models or data code must follow the ownership rules defined in `RULES.md`.

---

## 4. Presentation architecture

### Views

Views are responsible for:

* rendering state;
* forwarding user actions;
* composing widgets;
* connecting the screen to its Stacked view model.

Views must not:

* access repositories directly;
* access Supabase directly;
* contain business rules;
* own persistent application state.

### ViewModels

ViewModels own:

* screen state;
* asynchronous orchestration;
* user-action handling;
* navigation requests;
* interaction with repositories or shared services.

ViewModels must not hold `BuildContext`.

New ViewModels must not access Supabase directly. Production applications use repositories as the data boundary.

### Services

A shared reactive service is appropriate only when multiple features require the same live application state.

The template currently includes `ShellService` for shared shell/navigation state.

Do not create services simply to wrap one method or one repository call.

---

## 5. Navigation and generated Stacked code

`lib/app/app.dart` is the editable Stacked composition root.

It defines application registration such as:

* routes;
* services;
* repositories;
* bottom sheets;
* dialogs.

Generated Stacked files are outputs and must not receive manual edits.

Relevant generated files include:

```text
lib/app/app.router.dart
lib/app/app.locator.dart
lib/app/app.dialogs.dart
lib/app/app.bottomsheets.dart
```

When registration or route annotations change:

```bash
dart run build_runner build -d
```

Generated changes are committed when their editable source changed.

---

## 6. Current core foundations

The current template provides these shared foundations.

### Configuration

`lib/core/config/`

Compile-time or application configuration shared across the app.

### Constants

`lib/core/constants/`

Application constants, asset paths, storage keys, and related static values.

### Enums

`lib/core/enums/`

Shared enums and their wire/serialization helpers.

### Errors and results

`lib/core/errors/`

The template provides typed failures and `Result<T>` primitives for applications that need explicit success/failure handling.

### Formatters

`lib/core/formatters/`

Shared formatting helpers for values such as dates and display text.

### Forms and validators

`lib/core/forms/` and `lib/core/validators/`

Reusable validation rules and form-level helpers.

### Models

`lib/core/models/`

Shared models that do not have a clear single feature owner.

Do not move every feature model into `core/`. Promote a model when it is genuinely shared or promotion removes a real dependency problem.

### Network

`lib/core/network/`

Network/backend boundary helpers.

The current `SupabaseGuard` provides fail-fast handling when Supabase configuration is unavailable and maps backend failures into application failures.

The existence of this guard does not mean the template already contains a complete production repository layer.

### Services

`lib/core/services/`

Application-wide services that genuinely require shared lifecycle or state.

### Storage

`lib/core/storage/`

Local storage abstractions used by the template.

### Theme

`lib/core/theme/`

Application theme, colors, and UI helpers.

### Validators

Shared validation logic that does not belong to a single feature.

---

## 7. Shared presentation

Shared presentation code belongs outside feature folders.

The current repository uses:

```text
lib/shared/widgets/
```

for reusable widgets such as:

* loading indicators;
* empty states;
* shared iOS app bars;
* pagination widgets.

Feature-specific widgets remain under:

```text
lib/features/<feature>/ui/widgets/
```

Do not duplicate a shared widget inside a feature when the widget has no feature-specific responsibility.

---

## 8. Current data and backend boundary

The template contains Supabase configuration and a guard, but it does not currently contain the production application's full repository/data architecture.

The intended production flow is:

```text
View
  |
ViewModel
  |
Repository
  |
Supabase / local read-only cache
  |
PostgreSQL + RLS
```

Repositories should:

* own backend data access;
* map backend rows into application models;
* return `Result<T>` where the operation is fallible;
* prevent backend exceptions from crossing the repository boundary;
* never import UI code.

ViewModels should consume repositories rather than calling Supabase directly.

No UseCase layer is required.

---

## 9. Production Supabase target

Applications generated from this template may use Supabase as their production backend.

The target architecture is:

```text
Flutter
  |
Feature ViewModel
  |
Feature Repository
  |
Supabase SDK
  |
PostgreSQL + RLS
```

### Authentication

Supabase Auth handles application authentication and session management.

### Tenant isolation

Multi-tenant applications must enforce tenant isolation using PostgreSQL Row Level Security.

Client-side permission checks are UX only and are never the security boundary.

### Database authority

PostgreSQL owns authoritative:

* financial state;
* document numbering;
* balances;
* permissions;
* immutable issued-document state;
* transactional state changes.

The Flutter client must not independently assign authoritative financial numbers or bypass server-side invariants.

### Privileged operations

Sensitive operations should use the smallest appropriate server-side boundary:

* PostgreSQL functions for transactional database operations;
* Supabase Edge Functions only when privileged server-side application logic is required.

Service-role credentials must never be embedded in the Flutter application.

---

## 10. Production data architecture

When an application grows beyond the template's demonstration layer, feature data should follow:

```text
lib/features/<feature>/
|-- data/
|   |-- <model>_extension.dart
|   `-- <repository>.dart
`-- ui/
    |-- viewmodels/
    |-- views/
    `-- widgets/
```

Repositories own query and persistence logic.

Models remain pure when possible.

Row mapping belongs in feature data extensions when the database representation differs from the application model.

Do not introduce a DTO/entity/mapper stack without a real shape or boundary problem.

Do not introduce a UseCase layer merely to add another abstraction.

---

## 11. Production financial architecture

Financial applications require server-owned truth.

Production systems should ensure:

* authoritative amounts use PostgreSQL `numeric`;
* document numbers are assigned by PostgreSQL;
* financial state transitions execute transactionally;
* issued documents are immutable;
* corrections use void-and-reissue workflows;
* permissions are enforced by RLS and server-side functions;
* balances are derived from authoritative persisted state;
* audit records exist for material financial state transitions.

Flutter may perform UI validation and display calculations, but it must not become the final authority for financial state.

---

## 12. Offline and local storage target

The template does not currently provide a full offline database.

If an application requires offline support, follow the product-approved scope.

The preferred initial target is read-only caching:

```text
Supabase
    |
Repository
    |
Read-only local cache
    |
ViewModel
```

Offline writes should not be introduced without explicit product and architectural approval.

Do not add a local database merely because the application may need one in the future.

---

## 13. Testing architecture

The template currently contains focused unit and widget tests covering its implemented foundations and UI.

Tests live under:

```text
test/core/
test/features/
test/shared/
test/tool/
```

Production applications should expand testing according to the boundaries they introduce.

### Core tests

Test:

* result handling;
* failures;
* formatting;
* validation;
* storage behavior;
* network guards;
* shared models.

### ViewModel tests

Test:

* state transitions;
* orchestration;
* navigation requests;
* service interactions;
* repository outcomes.

### Widget tests

Test:

* rendering;
* user interaction;
* important states;
* reusable widgets.

### Repository tests

When repositories exist, test:

* row mapping;
* typed failures;
* persistence behavior;
* tenant behavior;
* important query boundaries.

### Backend tests

Supabase applications should test:

* RLS;
* tenant isolation;
* privileged functions;
* financial invariants;
* document numbering;
* immutable issued state.

---

## 14. Architecture decisions

### ADR-1: Feature-first Stacked MVVM

Use feature-first folders with Stacked views and view models.

This keeps screen ownership clear while allowing shared infrastructure under `core/` and shared presentation outside features.

### ADR-2: No mandatory UseCase layer

ViewModels may call repositories directly.

Do not add pass-through UseCases.

Introduce another application layer only when a real architectural boundary requires it.

### ADR-3: Repositories are the production data boundary

When persistent backend data exists, repositories isolate the UI from backend implementation details.

The starter template does not require repositories until a feature actually owns persistent data.

### ADR-4: Server-owned financial truth

For financial applications, the server owns authoritative numbering, balances, permissions, state transitions, and immutable document state.

### ADR-5: No custom API server by default

Supabase provides the backend boundary for applications using Supabase.

Add a custom API server only when an explicit product or infrastructure requirement justifies it.

### ADR-6: Generated Stacked files remain generated

Registration sources are edited manually; generated route and locator files are regenerated.

Never place custom logic in generated files.

---

## 15. Current template limitations

The current repository intentionally does not claim to contain:

* a complete authentication feature;
* a production repository layer;
* a complete business domain;
* production financial workflows;
* a production reporting system;
* a production PDF/document system;
* production offline synchronization;
* complete tenant/business functionality.

The supporting MVP documents describe a transport-fleet product target. They are product references, not evidence that those features already exist in this reusable template.

---

## 16. Reference files

Core architectural references:

* `RULES.md` — development and AI-agent standards.
* `lib/app/app.dart` — Stacked composition root.
* `lib/main.dart` — application bootstrap.
* `tool/bootstrap.dart` — application identity/bootstrap transformation.
* `supabase/` — backend configuration and future/application database boundary.
* `test/` — current automated tests.

Product references:

* `doc/Transport_Fleet_MVP_Blueprint.md`
* `doc/Transport_Fleet_MVP_Design_Brief.md`
* `doc/Transport_Fleet_MVP_Flow.svg`

The reusable template identity is established by `tool/bootstrap.dart`; product-specific identity must not be hard-coded into the template.
