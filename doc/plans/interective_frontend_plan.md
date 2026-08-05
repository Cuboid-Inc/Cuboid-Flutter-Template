# FleetGo — Frontend-Only Interactive Demo (Client Approval Build)

## Context

The scaffold (Stacked MVVM, Result/guard, AppConfig/Formatters, theme, shell, parties slice) is committed. Next: build **every design screen as a fully interactive, frontend-only demo** for the client. **Zero Supabase calls** — all data lives in memory, seeded at startup, mutable during the session, reset on restart. Data models/enums are still churning, so backend wiring is deliberately deferred; once the frontend is approved, only repository bodies get swapped to Supabase — ViewModels and UI stay untouched.

Sources of truth: `doc/design/project/Al Masar Fleet App v3.dc.html` + 41 screenshots in `doc/design/screenshots/` (all inventoried — 23 core screens plus the full More section: master data, 8 reports, staff). Domain: `doc/Transport_Fleet_MVP_Blueprint.md`.

**Key insight**: the design's dataset is internally consistent (receivables 21,283.49 = 6,357.49 + 14,926.00; payables 22,500 = 10,500 + 12,000; cashbook net 16,087.47; invoice totals are literally blueprint acceptance scenarios A/B/C). So we seed the design's exact dataset — the app then matches the design pixel-for-pixel on first launch, while every number is **computed live** from the store, so demo mutations (add trip → issue invoice → record payment → mark cheque cleared) visibly ripple through Home, Money, Balances, and Reports. That's the wow-factor of the demo.

## Architecture (the one structural decision)

**Repository signatures stay identical; bodies read/write an in-memory store.**

- `lib/core/demo/demo_store.dart` — lazy-singleton `DemoStore` (locator-registered) holding `List<Party>`, `List<Vehicle>`, `List<Driver>`, `List<Agreement>`, `List<WorkOrder>`, `List<Invoice>`, `List<SupplierSettlement>`, `List<Expense>`, `List<Payment>`, `List<RouteRate>`, `BusinessProfile`, staff list, and sequence counters (`nextInvoiceNumber()` → INV-2026-003269, `nextWoNumber()` → WO-1043, `nextSettlementNumber()` → SET-2026-0043).
- `lib/core/demo/demo_seed.dart` — seeds the design dataset (below).
- Feature repositories keep returning `Future<Result<T>>` but delegate to `DemoStore` (wrapped in ~250ms artificial delay for realistic loading states). **No interfaces, no dual implementations** (ponytail) — backend swap later = replace bodies with `guard(() => supabase...)`.
- **Derived numbers are never stored**: dashboard totals, AR/AP balances, profit, and all report rows are computed getters on `DemoStore` (period-filtered via a small `Period` value: this/last month/year or specific date).
- **Money as `int` fils** (minor units). Blueprint forbids float money; int math makes half-up 2dp exact (VAT 5% of 1,081,666 fils etc.) and survives the backend swap (Postgres numeric ⇄ fils at the repo boundary). `Formatters` gains `String moneyFils(int fils)`; all display through it, never inline.
- Blueprint invariants still honored in the demo: issue locks a snapshot (issued invoices immutable; correction = void), sequential numbers never reused, only **cleared** allocations reduce balances, master data archives.

### Models — `lib/core/models/` (all are cross-feature: Home computes across everything)

`Party` (role customer/supplier/both, TRN, terms, contact), `Vehicle` (owned/external, supplier link, reg/insurance expiry), `Driver` (phone, licence/EID expiry), `Agreement` (rate model monthly|perTrip, base rate fils, duty, OT/extra-day rates, VAT rate, driver/fuel/maintenance responsibility, default vehicle), `WorkOrder` (status planned/completed/canceled/billed, date, pickup/destination, `List<VehicleAllocation>` (vehicle, driver, source, supplierPayableFils), `List<ChargeLine>` (name, qty, unitPriceFils, vatRate → net/vat/gross computed)), `Invoice` (status draft/issued/partPaid/paid/void, number, dates, buyer snapshot fields, `List<InvoiceLine>`, linked WO ids), `SupplierSettlement` (number, supplier, period, lines, status), `Expense` (category enum, payee, optional vehicle/driver/WO links, net/vat fils), `Payment` (direction, party, method cash/bank/cheque, chequeState received/cleared, `List<PaymentAllocation>`), `RouteRate` (appliesTo, pickup, destination, vehicle class, rateFils, default extras), `BusinessProfile`, enums file. Plain classes, no codegen; `fromJson`/`toJson` can wait for backend wiring (YAGNI in demo).

### Seed dataset (`demo_seed.dart`) — reproduces the screenshots

- Business: Al Masar Transport LLC · TRN 100344820912003 · owner@almasar.ae.
- Customers: Gulf Star Contracting LLC (Net 30, TRN 100442810300003), Emirates Foodstuff Trading (Net 15), Al Noor Logistics (Net 30), Marina Build Co (On receipt). Suppliers: Khalid Transport Rentals, Desert Line Vehicles.
- Vehicles: DXB A 34521 (7-Ton, owned, reg to 12 Aug 2026), DXB B 88213 (3-Ton, owned, **insurance expires 28 Jul 2026**), SHJ C 55190 (30-seat bus, owned, reg to 02 Feb 2027), KTR — Flatbed (external via Khalid). Drivers: Rashid Ali (03 Sep 2026), Suneesh Kumar (**licence 19 Jul 2026**), Mohammed Irfan (11 Dec 2026).
- Agreements: AGR-012 Gulf Star monthly 9,500 (duty 6d/10h, OT 45/hr, extra day 316.66, default SHJ C 55190), AGR-015 Emirates monthly, AGR-021 Al Noor per-trip, AGR-023 Marina per-trip. Route rates: 4 lanes per screenshot (1,150 / 980 / 1,900 / 650) with default extras (Toll 50, Gate pass 150, Unloading 150, Waiting 100).
- July work: WO-1038 Marina billed 1,900; WO-1039 Gulf Star monthly-extra Sunday work billed 316.66; WO-1040 Al Noor completed-unbilled 2,850; WO-1041 Emirates planned 650; WO-1042 Gulf Star completed-unbilled 1,750 (2 allocations: DXB A 34521/Rashid owned + KTR external payable 500; charges: transport 2×800 + gate pass 150; scenario totals 1,750/87.50/1,837.50) + 1 canceled WO to fill the filter chip.
- Invoices: INV-2026-003265 Marina **Paid** 8,400 (paid in June → not in July cashbook); 003266 Al Noor **Issued** 14,926 (scenario C); 003267 Emirates **Paid** 17,937.47 (scenario B); 003268 Gulf Star **Part Paid** 11,357.49, balance 6,357.49 (scenario A: base 9,500 + Sunday 316.66 + parking 1,000, VAT 540.83).
- Settlements: SET-2026-0041 Khalid June 16,500 Part Paid (remaining 10,500), SET-2026-0042 Desert Line June 12,000 Issued.
- Payments: Emirates bank +17,937.47 (05 Jul, cleared); Gulf Star cheque +5,000 (08 Jul, **cleared** → explains Part Paid); Al Noor cheque +7,000 (10 Jul, **awaiting clearance** → balance untouched until "Mark cleared"); Khalid bank −6,000 (04 Jul, alloc to SET-0041); ENOC cash −850 (02 Jul, alloc to fuel expense); Marina +8,400 dated June.
- Expenses (July): fuel 850 (DXB A 34521), maintenance 1,200 (DXB B 88213), toll 240, driver pay 1,500 (Rashid advance), parking 400 (SHJ C 55190).
- History for statements/reports: generated June/May/April work rows per the Statements screenshot (Al Noor 14/10/9 rows, Marina 6, Gulf Star 3, …) with round amounts summing to the shown statement totals (14,926 / 8,400 / 11,357.49 / 11,200 / 9,850 / 9,800).
- **Reconciliation rule**: computed values win. Headline figures (receivables 21,283.49, payables 22,500, cashbook 16,087.47, expenses 4,190) reconcile exactly and are asserted in a seed test. Purely illustrative report numbers in the design (profit-by-customer split 19,340, owned-vs-external 52,620) derive from more history than shown — reports show live-computed values from our seed; tune expense/payable links toward ~19–20k July profit but don't chase exact fudged splits.

## Screens & file plan (feature-first; reuse AppButton/AppTextField/ListCard/SectionLabel/StatusChip, AppColors/AppTheme, Formatters)

New shared UI in `lib/ui/` (usable by all features):

- `widgets/demo_sheet.dart` (bottom-sheet scaffold: grab handle, title/subtitle, X), `widgets/chip_selector.dart` (single/multi chips — used by ~8 forms), `widgets/segmented_toggle.dart` (Owned/External, method, role, responsibilities…), `widgets/stat_card.dart`, `widgets/empty_state.dart`
- `pdf/fleet_pdf.dart` — **real PDF generation** (new deps: `pdf` + `printing`): A4 template per blueprint §12.5 (logo/brand color, seller & buyer identity, TRN, sequential number, lines table with qty/unit/VAT, totals, payment terms footer, multi-page + page numbers); `buildInvoicePdf(Invoice, BusinessProfile)` and `buildTripSheetPdf(WorkOrder, …)` returning bytes; one shared `PdfPreviewView` route using printing's `PdfPreview` with native share/print built in
- `sheets/` — cross-tab sheets (opened from Home _and_ Money): `payment_in_sheet.dart`, `payment_out_sheet.dart`, `add_expense_sheet.dart`, `record_payment_sheet.dart`, `period_sheet.dart`

Features (each `data/` repo delegating to DemoStore + `ui/` screens):

- **auth**: restyle login to design (navy gradient, logo, prefilled owner@almasar.ae, any password → shell)
- **home**: dashboard (period selector, profit hero, quick actions, owe-cards, needs-attention) — quick actions open the shared sheets / New-trip route
- **work**: list (search + status chips), `new_trip/` 3-step wizard (customer & route w/ route-rate autofill → allocations w/ bulk copy → charge lines w/ live VAT totals), `monthly_extra` sheet, `work_detail/` (allocations, charges, Add to invoice / Duplicate / Trip sheet preview), `prepare_month/` (customer chips, checkable base + unbilled lines, live totals, Issue invoice → assigns number, snapshots, marks WOs billed), trip-sheet A4 preview
- **money**: 6-sub-tab hub (Invoices/Statements/Settlements/Payments/Expenses/Balances), `invoice_detail/` + invoice A4 preview, `settlement_detail/`, `statement_view/`, payments row "Mark cleared" (cheque → cleared, balances update)
- **more**: hub (counts live from store, TRN footer), vehicles/drivers/agreements/route-rates lists + add sheets, `agreement_detail/`, `party_detail/` (balance hero, statement history, open invoices, record payment), staff & access packs (seeded list, Invite → toast), business & branding + opening data rows → toast
- **reports**: hub (month picker) + 8 report screens (operational profit, owned vs external, vehicle profit, expense summary, cashbook, unbilled work, unpaid invoices, expiring docs) — all computed from DemoStore for the selected period; CSV button → "Available after backend connect" toast
- **parties** (exists): rewrite repo body onto DemoStore; upgrade list to design (customer/supplier sections, balances) + add-party sheet

PDF screens (Invoice PDF, Trip sheet PDF): **real high-quality PDFs** (user decision) — generated from demo data via `lib/ui/pdf/fleet_pdf.dart`, shown in `PdfPreviewView`, shared/printed through the native share sheet. Invoice PDFs render from the issued snapshot (blueprint §12.3/§12.5).

## Execution: parallel Sonnet subagents (lead supervises)

- **Wave 0 (lead, sequential)**: core models + enums, DemoStore + computed getters + mutations (`issueInvoice`, `markChequeCleared`, `recordPayment`, `duplicateWorkOrder`, `archiveParty`…), demo_seed, seed reconciliation test, shared widgets/sheets contracts (files stubbed with real APIs), repo skeletons. This freezes every interface the wave-1 agents consume.
- **Wave 1 (5 Sonnet agents in parallel, disjoint file ownership, nobody touches `app/app.dart`)**:
  A: auth restyle + home. B: work (biggest flows). C: money + shared money sheets in `lib/ui/sheets/` + `lib/ui/pdf/` (both PDF builders + `PdfPreviewView`; B/D navigate to it via route contract frozen in wave 0). D: more + master data + party detail. E: reports (hub + 8 screens).
- **Wave 2 (lead integration)**: register all routes in `app/app.dart`, `dart run build_runner build -d`, wire Home quick actions to B/C deliverables, cross-screen navigation, analyze/test, visual pass against screenshots, fix-ups.

## Verification

- `flutter analyze` clean; `flutter test` green — including the new seed reconciliation test (asserts receivables 21,283.49, payables 22,500, invoice A/B/C totals, cashbook 16,087.47, expense total 4,190) and invoice-math tests (half-up 2dp per blueprint §15).
- `flutter run` demo walkthrough: login → populated dashboard → Mark Al Noor cheque cleared → INV-003266 flips to Part Paid, receivables drop on Home → New trip via route-rate autofill → complete → Prepare monthly invoice → Issue invoice INV-2026-003269 → open its PDF preview + native share sheet → record payment → balances/profit update → reports reflect it all.
- Side-by-side visual pass vs `doc/design/screenshots/` for every screen.

## Explicitly out (until client approval)

Supabase wiring, real auth, CSV export, staff invite flow, persistence of any kind, `fromJson`/`toJson` on models.
