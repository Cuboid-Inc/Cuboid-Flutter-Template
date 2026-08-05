# FleetGo delivery phases

Working rule: every wave updates its entry here (scope, what shipped, verification) as part of the
wave itself. A wave is not complete while this file still describes it as pending.

## Phase 1, authentication and staff access

Status: Complete

Completed:

- Added local Supabase configuration and a versioned tenant-auth migration.
- Added tenants, user profiles, tenant members, and member access packs.
- Added RLS for tenant membership and owner-only staff visibility.
- Connected sign-in, session restore, password reset, invitation acceptance, sign-out, and blocked access.
- Stored mobile sessions in iOS Keychain and Android Keystore-backed storage.
- Connected Staff & access to Supabase and the protected invite-staff Edge Function.
- Added native iOS and Android auth callback handling.
- Added a local debug launcher and a release launcher using env/prod.json.
- Added a deterministic local owner fixture for password and invitation testing.

Verification:

- Flutter analysis passes.
- All Flutter tests pass.
- Local migration and seed reset pass.
- All pgTAP auth and RLS tests pass.
- Local password sign-in and staff invitation checks pass.
- Supabase database advisors report no issues.

## Phase 2, master data and work

Runs as sequential Codex waves per the DemoStore-purge plan.

### Wave 0, Period extraction and small fixes

Status: Complete

- Moved `DemoPeriod` out of `demo_store.dart` into `lib/core/models/period.dart` as `Period`.
- Removed the hardcoded fallback `Party` from `work_viewmodel.dart` in favor of a real error state.
- Added `member_access_packs` cross-tenant denial coverage to `auth_rls_test.sql`.
- Added the missing `user_profiles` insert on invitation accept in the invite-staff Edge Function.

### Wave 1, Parties

Status: Complete

- Migration `20260719122358_create_parties.sql`: `public.parties` plus the reusable
  `private.has_access_pack(tenant_id, pack)` RLS helper (Master Data pack gates writes, any active
  tenant member reads).
- `PartiesRepository` migrated off DemoStore; tenant context resolved via injected `AuthRepository`.
- Fixed the party form sheet fake-id bug; new rows insert with an empty id.
- `fetchBalances` deliberately still demo-backed until the Money wave delivers invoices/settlements.
- `parties_rls_test.sql` pgTAP coverage.

### Wave 2, Master data

Status: Complete

- Migration `20260719122400_create_master_data.sql`: `vehicles`, `drivers`, `agreements`,
  `route_rates` (Master Data pack gated), and `business_profiles` (one row per tenant, owner-only
  writes). DB check enforces external vehicles require a linked supplier.
- `MoreRepository` fully migrated off DemoStore for these domains.
- Fixed the same fake-id bug in vehicle, driver, agreement, and route-rate form sheets.
- Removed the direct DemoStore field from `new_trip_viewmodel.dart`.
- `master_data_rls_test.sql` pgTAP coverage.

Verification (Waves 0-2 baseline, re-confirmed before Wave 2.5):

- Flutter analysis passes.
- All 71 Flutter tests pass.
- All 25 pgTAP assertions pass across the three RLS test files.

### Wave 2.5a, shared list infrastructure

Status: Done (commit `c1804ad`)

- `PaginatedResult`, `PaginationController` (Result-based, page size 50), and `PaginatedListView`
  (controller-driven, pull-to-refresh, infinite scroll).
- `CacheEntry` TTL cache plus `RepositoryCacheMixin` for repository-level read caching.
- Shared snake_case enum wire codec (`toJson`/`fromJson`) in `enums_extentions.dart`, replacing
  per-repository enum string mappings.

### Wave 2.5b, retrofit parties and master data

Status: Done (commits `87cc8bf`, `93dfb91`)

- Serialization moves out of repositories into `<model>_extension.dart` files in the owning
  feature's `data/` folder.
- Parties and master-data list screens paginate through `fetchPage` + `PaginatedListView`.
- Repository reads cached with TTL entries, invalidated on every write.

### Wave 3, work orders, allocations, charge lines

Status: Done (commit `2ed975c`; hardened in the migration-consolidation pass, commit `11d0d6f`)

- `work_orders` with tenant-scoped composite FKs to customer and agreement; charge-line
  net/VAT/gross derived in views; completion rule enforced server-side.
- Create/complete/cancel run as SECURITY DEFINER functions with server-managed status,
  numbering, and invoice linkage; clients keep only delete-while-planned.
- `WorkRepository` off DemoStore; work list paginated.

## Phase 3, money and reports

### Wave 4, money

Status: Done (commit `3a67866`; hardened in `11d0d6f`)

- Invoices, settlements, expenses, payments, balances on Supabase.
- Financial state changes in transactional privileged PostgreSQL functions; document sequences
  row-locked; issued documents immutable via trigger and by revoked client update grants.
- `party_balances`, `invoice_balances`, `settlement_balances`, `unbilled_work`,
  `statement_rows` views; money lists paginated.
- Resolved: cheque transitions via `transition_cheque_state`; paid documents cannot be voided.
- Deferred: durable audit rows for issue/void/allocation/cheque changes (see ARCHITECTURE.md §10).

### Wave 5, home and reports

Status: Done (commit `8133125`)

- Home and Reports fold period-filtered Supabase reads plus the Wave 4 views; the DemoStore
  aggregation formulas ported verbatim as pure statics; direct DemoStore ViewModel reads removed.
- Period sheet derives available years from work-order data; hardcoded 2026-07 periods removed.
- Deferred: PDF seller-side data still renders the live business profile (open product question).

### Wave 6, delete the demo store

Status: Done

- Deleted `lib/core/demo/*` and `test/demo_seed_test.dart`; removed the vestigial `DemoStore?`
  constructor param from `MoreRepository`.
- Documentation pass: ARCHITECTURE.md, PRD.md, and RULES.md no longer describe DemoStore as the
  operative backend.

## Phase 4, code audit remediation

Source: a whole-repository read-only audit (kept untracked at the repo root per the user's
instruction, not committed). Fresh per-phase wave numbering, unrelated to Phase 2/3's Wave 0-6.
Runs as sequential Codex waves (`gpt-5.6-terra`, high reasoning effort); each wave is reviewed and
verified independently before the next starts. Waves 4 and 5 split into parallel per-feature
sub-agents once their file scopes are genuinely disjoint, per the established parallel-wave rule.

### Wave 1, foundation — cache mixin, dead code, guard/startup logging

Status: Done

- Extract the repeated cache-read pattern into one `RepositoryCacheMixin` method; refactor all six
  repositories to call it.
- Delete unused `CacheEntry` flexibility (`withValue`, `withValueRefreshed`, `age`, `isExpired`,
  `invalidateByPrefix`) and their tests.
- Delete unused model aliases (`Invoice.workOrderIds`, `WorkOrder.vehicleAllocations`/`charges`).
- Single `AppLogger` in `SupabaseGuard`, one log line per failure branch, structured (no string
  interpolation of backend errors into the message).
- Startup milestone logging in `lib/main.dart`.
- Files: `lib/core/cache/cache_entry.dart`, `lib/core/models/invoice.dart`,
  `lib/core/models/work_order.dart`, `lib/core/supabase/supabase_guard.dart`, `lib/main.dart`, and
  the existing cache-read blocks inside `home_repository.dart`, `money_repository.dart`,
  `more_repository.dart`, `parties_repository.dart`, `reports_repository.dart`,
  `work_repository.dart`.

### Wave 2, SQL summary layer for Home / Reports / More

Status: Done. Verified for real against local Supabase: `supabase db reset` applies the new
migration cleanly, `supabase test db` passes (74 pgTAP assertions across 6 files, 13 new). Known
follow-up for Wave 3: `more_menu_counts.staff` filters `status = 'active'`, but
`MoreRepository.fetchStaff()` (the list this count is meant to summarize) has no status filter —
fix via a new migration, not by editing this one.

- Replace every client-side dashboard/report/menu-count fold with a security-invoker SQL view or
  function, per RULES.md DATA-16 (explicit product decision: implement in full, superseding Wave
  5's earlier client-fold call).
- Covers: Home totals + profit + receivables/payables + expiring-document counts; Reports profit,
  ownership split, per-vehicle profit (including the proportional-remainder allocation), expense
  summary by category, cashbook totals; More menu counts (vehicles/drivers/agreements/route
  rates/parties/staff).
- Safety net: keep each old Dart fold alongside its new SQL-backed method behind one temporary
  parity test (old fold output vs. new SQL output on identical seeded rows) before deleting the
  fold. Delete the fold and the parity test together once green.
- Files: new `supabase/migrations/*.sql`, new `supabase/tests/*.sql`,
  `lib/features/home/data/home_repository.dart`, `lib/features/reports/data/reports_repository.dart`,
  `lib/features/more/data/more_repository.dart`, `lib/features/more/ui/more_viewmodel.dart` (menu
  counts only).

### Wave 3, repository mapping and lifecycle logging

Status: Pending (sequential after Wave 2 — shares repository files)

- Move Supabase row mapping still living inside repositories into owning `*_extension.dart` files;
  replace the hand-rolled auth enum switch with the shared `enumFromJson` codec.
- Auth, financial (issue/void/settlement/payment/cheque), and More lifecycle logging.
- Remove the noisy per-access-pack debug log from `MoreViewModel.init()`.
- Files: `lib/features/auth/data/auth_repository.dart` (+ new `auth_access_extension.dart`),
  `lib/features/more/data/more_repository.dart` (+ new `staff_member_extension.dart`),
  `lib/features/parties/data/parties_repository.dart` (+ new `party_balance_extension.dart`),
  `lib/features/money/data/money_repository.dart`, `lib/features/more/ui/more_viewmodel.dart`.

### Wave 4, ViewModel and sheet-model consistency

Status: Done (ran as two parallel sub-agents, 4A money/reports/parties/home, 4B more/work; both
disjoint from Wave 1 and Wave 2's data-layer files)

- Exhaustive `Result` failure handling everywhere; every snackbar through the approved
  `showSuccess`/`showError`/`showWarning`/`showInfo` helpers; `Formatters` instead of hand-built
  money/time strings; drop the unused `BuildContext` param from `NewTripViewModel.next()`; surface
  form validation instead of silent/coerced values (model side); one guarded busy state per
  mutating action (model side); delete the dead `mockSaveRouteDecision` test control and the
  `demoWhenUnconfigured` test flag.
- Runs as parallel sub-agents by feature once Wave 3 lands: 4A money + reports, 4B more + parties,
  4C work + shared bottom-sheet/dialog models. Disjoint files, independently verified.

### Wave 5, shared widgets and presentation

Status: Pending (sequential after Wave 4 — view layer consumes Wave 4's model-side error states)

- New `DetailRow` and `FinancialLineTile` shared widgets; extend `EmptyState` (action + compact
  layout), `AppTextField` (`errorText`/`enabled`), `AppOutlineButton` (`loading`),
  `PaginatedListView`/`PaginationController` (surface load-more failures with retry).
- Replace Material icons with Cupertino equivalents; replace the hardcoded muted-color literal with
  `AppColors.mutedLight`; consistent `AppLoadingIndicator` variant usage; wire the new form-error
  and busy-state widgets through every view.
- 5A (solo, first): the shared widget library. 5B (parallel by feature, after 5A lands): per-feature
  view files consuming the extended widgets.

### Wave 6, test consolidation and money coverage

Status: Pending (last — depends on every prior wave's code shape)

- Shared Stacked service-mock helpers under `test/helpers/`; focused tests for `lib/core/money.dart`
  and the money-model accumulation paths; focused validation and duplicate-submit tests for every
  branch Wave 4 added.
- Update tests for removed constructor flags, removed context params, changed snackbar variants,
  and deleted dead members.
- Run the full Flutter suite, analyzer, and (if Wave 2's migration is still pending re-verification)
  `supabase test db` before sign-off.
