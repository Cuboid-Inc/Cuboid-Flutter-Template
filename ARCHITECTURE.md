# Cuboid Flutter Template Architecture

Status: Current repository architecture and production target

This document separates code present in the repository from the planned production system. Development and AI agent standards come from `RULES.md`.

## 1. Architecture labels

- Current means code exists in this repository.
- Production target means required behavior described in project documents but absent from the current backend.
- Implemented screen means a route and UI exist. The label does not mean production persistence, security, or audit support exists.

## 2. Current system at a glance

```text
Flutter views
    |
Stacked view models
    |
Feature repositories
    |
guard<Result<T>>
    |
Supabase (PostgreSQL + RLS + SECURITY DEFINER functions)

AuthRepository --------------------> Supabase Auth, when configured
Staff & access --------------------> Supabase tenant tables + invite-staff Edge Function
PDF builders ----------------------> pdf + printing
Letterhead store ------------------> local application documents
```

Every business domain — parties, vehicles, drivers, agreements, route rates, work orders, invoices, settlements, expenses, payments, balances, home/report aggregation, and the business profile — reads and writes tenant-scoped Supabase tables tracked in `supabase/migrations/`. Financial state transitions (issue, void, payment allocation, cheque state, document numbering, work-order lifecycle) run in SECURITY DEFINER Postgres functions; clients cannot write those columns directly.

### Runtime modes

| Build state                              | Authentication                      | Business data | Result                                                                       |
| ---------------------------------------- | ----------------------------------- | ------------- | ---------------------------------------------------------------------------- |
| Debug or profile without Supabase values | Local demo success for auth actions | None          | Shell opens, but every data call fails fast (`guard` returns a failure).     |
| Debug or profile with Supabase values    | Supabase Auth                       | Supabase      | Fully live against the configured project (normally local Supabase).         |
| Release without Supabase values          | App throws during startup           | None          | Release fails fast before `runApp`.                                          |
| Release with Supabase values             | Supabase Auth                       | Supabase      | Fully live.                                                                  |

`SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` come from compile-time values in `lib/core/supabase/env.dart`.

### Bootstrap flow

1. `lib/main.dart` initializes Flutter bindings.
2. Supabase initializes only when both environment values exist.
3. Stacked registers generated dependencies, bottom sheets, dialogs, and snackbars.
4. `StartupView` checks `AuthRepository.hasSession`.
5. A live session opens `ShellView`. Other states open `LoginView`.

In demo mode, `hasSession` stays false. Login accepts the submitted credentials through a local success path, then opens the shell.

## 3. Current application structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart                 Stacked routes, services, sheets, dialogs
|   |-- app.locator.dart         Generated dependency registration
|   |-- app.router.dart          Generated route code
|   |-- app.bottomsheets.dart    Generated sheet code
|   `-- app.dialogs.dart         Generated dialog code
|-- core/
|   |-- config/                  App constants and display formatters
|   |-- cache/                   Repository TTL cache entries
|   |-- enums/                   Shared business enums and labels
|   |-- models/                  Shared business models
|   |-- pdf/                     Local custom-letterhead file handling
|   |-- supabase/                Compile-time environment and exception guard
|   |-- failures.dart
|   `-- result.dart
|-- features/
|   |-- auth/
|   |-- home/
|   |-- money/
|   |-- more/
|   |-- parties/
|   |-- reports/
|   |-- shell/
|   |-- startup/
|   `-- work/
`-- ui/
    |-- bottom_sheets/
    |-- common/
    |-- dialogs/
    |-- pdf/
    `-- widgets/

supabase/
|-- migrations/                  Versioned schema, RLS, and function migrations
|-- functions/invite-staff/      Privileged staff-invitation Edge Function
|-- tests/                       pgTAP auth and RLS tests
`-- seed.sql                     Local owner fixture and seed data
```

Tests live under `test/core/` and `test/features/`. Shared business models live under `lib/core/models/`, not inside each feature. `lib/features/parties/data/party.dart` only re-exports the shared party model and enum.

### Presentation pattern

- Stacked MVVM drives routed screens and the four shell tabs.
- `BaseViewModel` owns most screen state and asynchronous orchestration.
- `ReactiveViewModel` listens to `ShellService` for tab, money-segment, and work-filter state.
- Views render state and forward actions.
- View models request navigation, snackbars, registered bottom sheets, and registered dialogs through Stacked services.
- No separate domain or UseCase layer exists.

Dependency direction stays toward shared code and data boundaries. `core/` does not import feature or UI code. Feature data files do not import UI code. Two composition roots intentionally import feature UI:

- `lib/app/app.dart` imports every registered route, sheet, and dialog.
- `lib/features/shell/shell_view.dart` imports the four root tab views.

Generated router, locator, sheet, and dialog files repeat those composition imports.

### Navigation and registration

`lib/app/app.dart` is the editable registration source. Generated files must not receive manual edits.

Current registration includes:

- 30 routes.
- 10 bottom-sheet variants.
- 2 dialog variants.
- 7 feature repositories.
- `ShellService` plus Stacked navigation, dialog, bottom-sheet, and snackbar services.

The root `ShellView` holds four tabs in an `IndexedStack` so tab state survives tab changes:

1. Home
2. Work
3. Money
4. More

## 4. Current feature inventory

All rows below describe existing UI backed by tenant-scoped Supabase data.

| Area                    | Implemented routes and flows                                                                                                                                   | Current boundary                                                                                                                                                                                                                       |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Startup and auth        | Startup, sign in, forgot password, reset password, accept invitation                                                                                           | Supabase Auth runs only with configuration. Unconfigured auth returns local success. Invitations run through the `invite-staff` Edge Function; acceptance activates the membership through `accept_invitation`.                        |
| Home                    | Monthly billed, received, paid out, profit, balances, attention items, expiries, quick actions                                                                 | Totals fold period-filtered Supabase reads client-side; permission flags come from `AuthRepository.currentAccess`. Period sheets derive year choices from work-order data.                                                             |
| Work                    | Search and status filters, new trip wizard, work detail, completion, cancellation, duplication, trip-sheet preview, monthly-extra sheet                        | Create, complete, and cancel run through SECURITY DEFINER Postgres functions with server-managed status and numbering. New trip saves one allocation; the model supports several, but the create UI does not.                          |
| Monthly preparation     | Select customer and unbilled work, calculate invoice lines, issue invoice                                                                                      | The flow has no month selector, agreement-base lines, invoice-grouping choice, or supplier-settlement preparation. Issue runs in the `issue_invoice` Postgres function.                                                                |
| Money                   | Invoice, statement, settlement, payment, expense, and balance lists and details. Payment entry, cheque clearance, invoice void, and document PDF routes exist. | State transitions run in SECURITY DEFINER Postgres functions; issued documents are immutable server-side. Payment entry links at most one invoice, settlement, or expense. No settlement creation or void flow exists in the UI.       |
| Parties                 | Customer and supplier lists, details, form, archive, payment entry                                                                                             | Supabase CRUD with master-data pack RLS; archive, never delete.                                                                                                                                                                        |
| Master data             | Vehicle, driver, agreement, route-rate lists, detail routes, forms, archive actions                                                                            | Supabase CRUD with master-data pack RLS; archive, never delete.                                                                                                                                                                        |
| Staff and access        | Staff list, access-pack labels, invite form                                                                                                                    | Backed by Supabase tenant members, access packs, and RLS. Invitations go through the protected `invite-staff` Edge Function.                                                                                                           |
| Business and branding   | Business profile editor, brand color, custom letterhead selection and preview                                                                                  | Profile persists in `business_profiles` (owner-only RLS). Letterhead PNG files live in the local app documents directory.                                                                                                             |
| Reports                 | Operational profit, owned versus external, vehicle profit, expense summary, cashbook, unbilled work, unpaid invoices, expiring documents                       | Rows and totals fold period-filtered Supabase reads and views. Export still shows an unavailable message. Monthly operations, customer profit, supplier balance, and unpaid-settlement report routes are absent.                       |
| PDFs                    | Invoice, trip sheet, statement, supplier settlement, letterhead preview                                                                                        | Generated on demand with `pdf` and shown through `printing`. Current business-profile data supplies document branding.                                                                                                                 |
| Opening data and backup | Menu entry only                                                                                                                                                | The screen reports availability after backend connection.                                                                                                                                                                              |

Implemented sub-screens must not return to a future-screen roadmap. Remaining work concerns production data, security, missing exports, and incomplete product behavior.

## 5. Current data layer

### Repository flow

```text
View -> ViewModel -> Repository -> guard -> Supabase
```

Every repository resolves tenant context through an injected `AuthRepository` and wraps every data call in `guard`, which short-circuits when Supabase is unconfigured and maps thrown exceptions to app failures.

| Repository                  | Current source                     | Main responsibility                                                    |
| ---------------------------- | ---------------------------------- | ---------------------------------------------------------------------- |
| `AuthRepository`             | Supabase Auth or local demo branch | Session, sign in, sign out, password reset, invitation password update |
| `HomeRepository`             | Supabase                           | Dashboard summary, balances, alerts, profit                            |
| `WorkRepository`             | Supabase                           | Work list, create, complete, cancel, duplicate                         |
| `MoneyRepository`            | Supabase                           | Invoices, settlements, payments, expenses, balances, statements        |
| `PartiesRepository`          | Supabase                           | Parties, balances, archive                                             |
| `MoreRepository`             | Supabase                           | More screen menu badge counts only                                     |
| `VehicleRepository`          | Supabase                           | Vehicles: list, page, add, archive                                     |
| `DriverRepository`           | Supabase                           | Drivers: list, page, add, archive                                      |
| `AgreementRepository`        | Supabase                           | Agreements: list, page, add, archive                                   |
| `RouteRateRepository`        | Supabase                           | Route rates: list, page, add, archive                                  |
| `StaffRepository`            | Supabase                           | Staff list, invite                                                     |
| `BusinessProfileRepository`  | Supabase                           | Business profile fetch/update                                          |
| `ReportsRepository`          | Supabase                           | Period report totals and rows                                          |

Vehicles, drivers, agreements, route rates, staff and the business profile each have their own repository even though their screens live under the `more` feature's `ui/` — one entity, one repository, matching the `parties` shape. `VehicleRepository`/`DriverRepository`/`AgreementRepository`/`RouteRateRepository` mutations also invalidate `MoreRepository`'s cache so the More screen's badge counts stay in sync.

### Models and calculations

- Shared models cover party, vehicle, driver, agreement, route rate, work order, invoice, supplier settlement, expense, payment, business profile, and staff.
- Amounts use num AED in Flutter, rounded half-up to two decimals at every money operation via `lib/core/money.dart` (`roundMoney`, `vatAmount`).
- Charge and invoice VAT use half-up rounding to two decimals.
- Invoice, settlement, and work-order statuses are server-managed; issued documents are immutable in the database (corrections = void + reissue).
- Row mapping lives in per-model `*_extension.dart` files in each feature's `data/` folder; models themselves stay pure.
- Aggregate report row types (`HomeTotals`, `VehicleProfit`, `StatementRow`, …) and `Period` live in `lib/core/models/`.
- Period choices follow the device date; report year choices derive from the earliest work-order date.

The app routes display formatting through `AppConfig` and `Formatters`. The configured display currency is AED. Dates use explicit English patterns.

### Data-layer conventions (adopted Wave 2.5, retrofitted onto parties and master data first)

- **Row mapping in model extensions.** Models stay pure in `lib/core/models/`. Each feature's
  `data/` folder holds one `<model>_extension.dart` per persisted model exposing
  `toRow(String tenantId)` and a static `fromRow(Map<String, dynamic>)`. Repositories contain query
  logic only — no private row mappers. Cross-feature imports of another feature's `data/` extensions
  are allowed; promote to core only to break a real cycle.
- **Shared enum wire codec.** Enum↔database strings go through the generic snake_case
  `toJson()`/`fromJson()` on `Enum` in `lib/core/enums/enums_extentions.dart`
  (`perTrip` ↔ `per_trip`, `net7` ↔ `net_7`). No per-enum string switch functions.
- **Paginated lists.** List screens read through
  `fetchPage({required int pageNumber, int pageSize = 50, String? search})` returning
  `Result<PaginatedResult<T>>` (Supabase `.range()` + exact count). ViewModels hold a
  `PaginationController`; views render a `PaginatedListView`
  (`lib/ui/widgets/paginated_list/`). `fetchAll` remains only for pickers and selectors.
- **Summary views.** Aggregate badge/KPI numbers come from small `security_invoker` SQL views, one
  `fetchSummary()` repository method each. Aggregation never happens client-side.
- **Repository TTL cache.** Reads cache in `CacheEntry` maps (`lib/core/cache/cache_entry.dart`,
  default TTL one minute). Every write clears the owning repository's whole cache.

### Error handling

`lib/core/result.dart` defines sealed `Success<T>` and `Failure<T>` results. `lib/core/failures.dart` defines network, auth, server, validation, and unknown failures.

- Every repository data call goes through `guard` from `lib/core/supabase/supabase_guard.dart`.
- `guard` maps Auth, PostgREST, socket, and unknown exceptions into app failures.
- PDF and local-file helpers do not use `Result<T>`. Their file, raster, font, and rendering errors still cross their helper boundary.

## 6. Current PDF and branding flow

```text
ViewModel -> PDF builder -> Uint8List -> PdfPreview -> native print/share actions
                         -> current BusinessProfile
                         -> optional local letterhead PNG
```

`lib/ui/pdf/fleet_pdf.dart` builds invoice, trip sheet, statement, supplier settlement, and letterhead-preview documents. `lib/core/pdf/letterhead_store.dart` accepts PNG, JPG, JPEG, or PDF input. PDF input is rasterized to PNG. The stored file uses a unique local filename to avoid stale image-cache entries.

This is a working demo document pipeline. Two production rules remain unmet:

- Issued PDFs use the current business profile instead of a stored branding snapshot.
- Uploaded branding lives on one device instead of Supabase Storage.

Generated PDF binaries should remain on demand. The production database does not need to store them.

## 7. Current dependencies

| Purpose                            | Package                             |
| ---------------------------------- | ----------------------------------- |
| UI framework                       | Flutter                             |
| MVVM and services                  | `stacked`, `stacked_services`       |
| Backend SDK and auth               | `supabase_flutter`                  |
| Formatting                         | `intl`                              |
| PDF creation and preview           | `pdf`, `printing`                   |
| Letterhead import and storage path | `file_picker`, `path_provider`      |
| Fonts and icons                    | `google_fonts`, `cupertino_icons`   |
| Code generation                    | `build_runner`, `stacked_generator` |
| Tests                              | `flutter_test`, `mocktail`          |

No local database or cache package is installed. No REST client or custom API client exists.

## 8. Current tests

The repository contains 22 test files.

Verification on 16 July 2026: `flutter test` reaches the full suite but reports two failures in `test/features/auth/auth_viewmodels_test.dart`. Both failing checks expect the old snackbar call. `ForgotPasswordViewModel` now uses warning and success variants, which call `showCustomSnackBar`. The remaining reported tests pass.

Current coverage includes:

- `Result<T>`, money parsing, money formatting, date formatting, and Supabase guard behavior.
- Demo seed totals, document sequences, and VAT rounding.
- Auth, home, work, party, money, master-data, detail-screen, and form/sheet view models.
- A minimal widget smoke test.

Current gaps include:

- No Supabase integration tests.
- No migration, RLS, tenant-isolation, or database-function tests.
- No full navigation or end-to-end workflow tests.
- No PDF content, layout, or snapshot-stability tests.
- No persistence, restart, offline-cache, or concurrency tests.

## 9. Production target

The production system keeps the current Flutter feature and MVVM structure. Repositories change from the in-memory store to Supabase and a read-only local cache.

```text
Flutter View
    |
Stacked ViewModel
    |
Feature Repository
    |------------------------|
Supabase SDK           Read-only local cache
    |
PostgreSQL + RLS
    |
Transactional database functions
```

### Mobile target

- Keep feature-first folders and Stacked view/view-model pairs.
- Keep repositories as the data boundary.
- Keep `Result<T>` and typed failures.
- Add row mapping to shared models or repository-local records when database shapes differ.
- Keep one source for currency and date formatting.
- Keep cross-tab state in `ShellService` until more shared live state exists.
- Add no UseCase layer unless an operation gains reusable business logic outside the database transaction.

### Supabase target

- Supabase Auth handles email and password sessions.
- PostgreSQL stores operational and financial records.
- Row Level Security enforces tenant membership on every business table.
- Access-pack policies enforce Operations, Master Data, Money, and Reports rights.
- Supabase Storage stores logo and header artwork only.
- One Edge Function handles staff invitations without exposing service-role credentials.
- The Flutter app holds only the public Supabase key.
- No custom API server sits between Flutter and Supabase.

### Identifier and numbering conventions

Primary keys:

- Every table uses `id uuid primary key default gen_random_uuid()`. PostgreSQL generates the id.
- The client never generates or sends an `id` on insert. It reads the generated row back with `.insert(...).select()`.
- No shared client-side uuid helper exists or should be added. Client-side id generation is only justified by offline-first queued writes, which are out of scope.

Human-facing document numbers (`AGR-012`, `INV-2026-003268`):

- Assigned by PostgreSQL, never by the client. Two clients computing "next number" locally would collide (see MONEY-15, blueprint §12.4).
- One per-tenant counter table, `document_sequences (tenant_id, doc_type, prefix, last_no)`, keyed by document type (`AGR`, `INV`, ...). A `private.next_doc_no(tenant_id, doc_type)` function increments the counter with an upsert and returns the formatted number. The row lock makes it gap-free and race-safe.
- The issuing database function (or a `before insert` trigger for non-financial records such as agreements) calls `next_doc_no` inside the same transaction as the insert.
- Do not use PostgreSQL sequences for document numbers. Sequences are not per-tenant and leave gaps on rollback.
- The owner sets prefix and opening number during onboarding. Issued and void numbers never return to the sequence.

### Target tables

Identity and tenant:

- `tenants`
- `user_profiles`
- `tenant_members`
- `member_access_packs`

Master and operations:

- `parties`
- `vehicles`
- `drivers`
- `agreements`
- `route_rates`
- `work_orders`
- `vehicle_allocations`
- `work_charge_lines`

Money and documents:

- `document_sequences`
- `invoices`
- `invoice_lines`
- `invoice_work_links`
- `supplier_settlements`
- `supplier_settlement_lines`
- `expenses`
- `payments`
- `payment_allocations`
- `branding_templates`
- `financial_activity`

Every business row needs `tenant_id`, timestamps, and responsible-user fields where relevant.

`route_rates` is required by the implemented trip-entry flow. The blueprint data-model list does not name this table, so its production ownership, uniqueness rules, and relationship to agreements still need product confirmation.

### Transaction boundary

PostgreSQL functions own privileged financial state changes:

- `issue_invoice`
- `void_invoice`
- `issue_supplier_settlement`
- `void_supplier_settlement`
- `record_payment_allocation`

Each function validates tenant membership, access pack, document state, amounts, remaining balance, and sequence inside one transaction. The invitation Edge Function owns `invite_staff`.

The client must not assign final document numbers, lock issued records, enforce allocations, or treat local permission checks as security.

### Financial and document invariants

- PostgreSQL stores authoritative money as `numeric`, never floating point.
- Flutter uses num AED at its UI and model boundary, rounded to two decimals at every operation.
- The server applies two-decimal half-up rounding.
- Only cleared payment allocations change balances.
- Issued invoices and settlements are immutable snapshots.
- Corrections use void with a reason, then reissue.
- Issued and void numbers never return to a sequence.
- Master records use archive instead of hard delete.
- Generated PDFs read issued seller, buyer, branding, lines, tax, totals, and work links from snapshots.

### Connectivity target

- Every write needs connectivity and server confirmation.
- A read-only local cache stores recent dashboard totals, parties, vehicles, drivers, agreements, and work.
- Cached screens show an offline state.
- Cached records do not expose edit actions.

## 10. Production gaps

| Gap                     | Current state                                                                                                  | Required production change                                                                                                                        |
| ----------------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| Database                | Done. Five final-shape migrations cover auth, parties, master data, work, and money with composite tenant-scoped foreign keys | None.                                                                                                                              |
| Business repositories   | Done. Every repository reads tenant-scoped Supabase through `guard`                                            | None.                                                                                                                                             |
| Tenant isolation        | Done. Every business table carries `tenant_id`, RLS, and composite tenant foreign keys                        | None.                                                                                                                                             |
| Permissions             | Done. ViewModels read `AuthRepository.currentAccess`; RLS and Postgres functions enforce server-side           | None.                                                                                                                                             |
| Work allocations        | The model supports many allocations. New trip saves one with an explicit supplier payable.                     | Add multi-allocation entry.                                                                                                                       |
| Monthly preparation     | Current UI selects a customer and any unbilled work, then issues locally                                       | Add month, active agreements, base monthly lines, extra work, VAT review, grouping, and supplier-settlement preparation.                          |
| Payment allocations     | A payment model accepts many allocations. The form links at most one document.                                 | Support reviewed multi-document allocation and validate payment and document limits on the server.                                                |
| Supplier settlements    | Seeded settlement list, detail, payment, and PDF flows exist. No preparation or void UI exists.                | Add period preparation, issue, void-reason, and reissue workflows through database functions.                                                     |
| Financial transactions  | Done. Issue, void, allocation, cheque state, and numbering run in SECURITY DEFINER PostgreSQL functions        | None.                                                                                                                                             |
| Audit                   | No durable financial activity log exists                                                                       | Record issue, void, allocation, cheque-state, actor, timestamp, and reason.                                                                       |
| Issued snapshots        | Invoice stores buyer fields and lines, but PDF branding comes from the current profile                         | Store full seller, buyer, branding, line, tax, total, and work-link snapshots at issue time.                                                      |
| Branding storage        | Letterheads use an absolute device path                                                                        | Upload logo and header artwork to tenant-scoped Supabase Storage and cache safe local copies for display.                                         |
| Staff invitation        | Done. The `invite-staff` Edge Function, membership activation, and access-pack assignment are live             | None.                                                                                                                                             |
| Reports and exports     | Eight report screens work. Export actions are placeholders. Several blueprint reports have no dedicated route. | Add server-backed period queries, monthly operations, customer profit, supplier balance, unpaid settlements, and approved PDF or CSV exports.     |
| Opening data and backup | More-menu placeholder only                                                                                     | Add controlled opening imports, owner exports, encrypted database exports, verification, and restore drills.                                      |
| Offline reads           | No local database or cache dependency exists                                                                   | Add the smallest read-only cache meeting the blueprint list and a visible offline state.                                                          |
| Backend tests           | pgTAP covers RLS, tenant isolation, functions, and issued-snapshot immutability; Flutter tests cover view models and money folds | Add repository-integration tests against local Supabase.                                                                        |

## 11. Delivery order for the architecture transition

1. Done. Supabase migrations, constraints, RLS, seed roles, and database-function tests exist for auth and tenancy.
2. Done. Tenant membership and access-pack loading run after authentication.
3. Done. Master-data and work repositories converted to Supabase.
4. Done. Invoice, settlement, expense, payment, balance, and report repositories converted.
5. Done. Issue, void, allocation, cheque, and sequence rules live in database functions.
6. Store branding assets and issued branding snapshots.
7. Add report exports, opening data, backup operations, and the read-only cache.
8. Run the blueprint acceptance scenarios against the production backend.

## 12. Architecture decisions

### ADR-1: Feature-first Stacked MVVM

Keep feature folders, Stacked views, view models, generated routes, and generated dependency registration. This structure already supports the implemented screen set.

### ADR-2: Sealed `Result<T>` without `dartz`

Dart sealed classes provide exhaustive result handling without another functional dependency. Repositories return `Result<T>`. Backend exceptions do not cross the repository boundary.

### ADR-3: No default DTO, mapper, entity trio

Use one model when the database row and app concept match. Add a separate transport record only for a real shape mismatch or issued snapshot boundary.

### ADR-4: No pass-through UseCases

View models call repositories directly. Add a UseCase only for reusable logic spanning repositories. Financial authority belongs in PostgreSQL functions.

### ADR-5: No custom API server

Flutter talks to Supabase through repositories. Privileged staff invitation uses one Edge Function. Privileged financial changes use PostgreSQL functions.

### ADR-6: Server-owned financial truth

The current client-side demo money logic supports UI validation and test scenarios. Production sequences, balances, snapshots, permissions, rounding, and state changes remain server-owned.

### ADR-7: Read-only offline support

Cache only the records listed in the blueprint. Offline writes stay outside the MVP.

## 13. Reference files

- Development and AI agent standards: `RULES.md`
- Stacked registration: `lib/app/app.dart`
- Bootstrap: `lib/main.dart`
- Database schema, RLS, and functions: `supabase/migrations/`
- Feature repositories: `lib/features/*/data/*_repository.dart`
- Supabase adapter: `lib/core/supabase/`
- Shared models: `lib/core/models/`
- PDF builders: `lib/ui/pdf/fleet_pdf.dart`
- Current tests: `test/`

Framework: Flutter 3.x, Stacked MVVM, Supabase target
