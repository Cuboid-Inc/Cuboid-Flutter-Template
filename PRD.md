FLEETGO PRODUCT REQUIREMENTS DOCUMENT

DOCUMENT CONTROL

Product name: FleetGo
Document type: Product Requirements Document
Status: Draft for client validation
Version: 1.0
Date: 16 July 2026
Pilot market: United Arab Emirates
Pilot model: One transport operator, one location
Platforms: Android and iOS mobile app

1. PRODUCT SUMMARY

FleetGo is a mobile operations and money system for a small UAE transport operator.

The product replaces paper records, spreadsheets, repeated calculations, and scattered payment notes. Staff record transport work once. The same record feeds customer billing, supplier payouts, operating expenses, payments, balances, vehicle history, and operational profit.

The first release serves one pilot company. The pilot will validate daily use, month-end billing, payout control, report accuracy, and staff adoption before wider sales.

2. WHAT TO BUILD

Build one mobile app with four main areas named Home, Work, Money, and More.

Home shows the current business position and urgent actions.

Work records per-trip jobs, monthly-hire work, vehicles, drivers, routes, customer charges, and supplier costs.

Money handles invoices, statements, supplier settlements, expenses, incoming payments, outgoing payments, balances, and operational profit.

More manages customers, suppliers, vehicles, drivers, agreements, route rates, reports, staff access, and business settings.

The app must preserve a full history for monthly and yearly review. Users must find old work, invoices, payments, payouts, expenses, and vehicle activity without checking paper or separate spreadsheets.

3. PRODUCT VISION

The owner should finish each month from one trusted source of business records.

The owner should know what work happened, which vehicle and driver performed the work, what each customer owes, what the business owes suppliers, and what operational profit remains.

4. BUSINESS CONTEXT

The pilot client operates in the UAE from one location.

The client manages about 10 to 25 vehicles. The fleet includes owned vehicles and external vehicles supplied by rental owners, friends, or subcontractors.

The management team includes about 2 to 5 people. Team members handle operations, records, billing, collections, expenses, and supplier payouts. One person often performs several roles.

The business provides two main service types. The first service type is fixed monthly vehicle hire. The second service type is per-trip transport work.

Monthly hire includes a base rate and extras such as Sunday work, overtime, extra trips, night shifts, parking, tolls, and gate passes.

Per-trip work includes the customer, route, date, vehicle class, driver, transport rate, VAT, toll, unloading, gate pass, and other approved charges.

Large customer requests use a mix of owned and external vehicles. The client receives the customer payment and later pays each external vehicle supplier.

5. PROBLEM STATEMENT

The current process spreads information across paper, spreadsheets, invoices, chat messages, and personal calculations.

Staff repeat the same work details in operations records, customer invoices, supplier payout records, and reports.

Separate calculations create risks such as missed work, incorrect totals, duplicate entries, unpaid supplier amounts, unclear customer balances, and unreliable profit figures.

Historical review takes too long because records lack one searchable source.

The business needs fast monthly and yearly reports without rebuilding totals by hand.

6. TARGET AUDIENCE

PRIMARY USER, OWNER OR BUSINESS MANAGER

The owner needs a quick view of work, cash movement, money owed, supplier payouts, expenses, document expiry, and operational profit. The owner controls staff, settings, exports, financial voids, and business records.

SECONDARY USER, OPERATIONS WORKER

The operations worker records jobs, assigns vehicles and drivers, checks routes and agreements, adds customer charges, marks work complete, and finds past work.

SECONDARY USER, FINANCE OR ADMIN WORKER

The finance or admin worker prepares invoices and statements, records payments, tracks cheques, creates supplier settlements, records expenses, and checks balances.

SECONDARY USER, REPORT VIEWER

The report viewer reads and shares approved reports without changing operational or financial records.

DRIVER

Drivers remain managed profiles in the first release. Drivers receive no account or app access during the pilot.

7. USER EDUCATION AND DIGITAL EXPERIENCE

The average user has a high-school education.

Users have regular smartphone experience. They understand common mobile actions such as tapping, scrolling, searching, selecting dates, and sharing files.

English is not the first language for most users. Users have limited comfort with business and accounting terms in English.

The interface must use plain English, short labels, familiar words, visible icons with text, and consistent action names.

The product should reduce typing through saved routes, agreement defaults, quick charge choices, duplication of past work, and automatic totals.

The product should prepare all text for later translation. The client must confirm the preferred interface languages before production release.

8. USER NEEDS

UN-01. Record each transport job once.

UN-02. Separate owned vehicles from external vehicles on every job.

UN-03. See the amount billed to the customer and the amount owed to each supplier.

UN-04. Find work by date, customer, vehicle, driver, route, invoice, and status.

UN-05. Prepare monthly customer billing from completed work without re-entry.

UN-06. Record all money received and paid, including partial payments and cheques.

UN-07. Track fuel, maintenance, driver, toll, parking, rent, gate pass, and other expenses.

UN-08. Review monthly and yearly operational history.

UN-09. Produce readable invoices, statements, settlements, and reports for sharing.

UN-10. See customer balances, supplier balances, and operational profit from the same records.

9. PRODUCT GOALS

PG-01. Replace paper and spreadsheet calculations for current work and month-end processing.

PG-02. Keep one source of truth for work, billing, payouts, payments, expenses, and history.

PG-03. Make mixed-fleet margin visible for owned and external vehicle work.

PG-04. Reduce missed billing and missed supplier payouts.

PG-05. Give the owner monthly and yearly reports without manual rebuilding.

PG-06. Support users with limited English through simple mobile workflows.

PG-07. Protect issued financial records and keep an audit trail.

10. PRODUCT PRINCIPLES

PP-01. Enter work once and reuse the same record everywhere.

PP-02. Keep owned and external vehicle costs visible.

PP-03. Prefer totals and readable tables over complex charts.

PP-04. Show direct action labels such as Add work, Issue invoice, Record payment, and Pay supplier.

PP-05. Keep common actions short and keep financial actions safe.

PP-06. Preserve issued documents. Corrections use void and reissue.

PP-07. Build for one pilot operator before adding broad SaaS features.

11. MVP FEATURES

FR-01. AUTHENTICATION AND ACCESS

The product must support owner and staff sign-in by email and password.

The owner assigns access packs for Operations, Master Data, Money, and Reports.

Owner-only actions include staff management, business settings, document sequences, exports, void actions, and backup visibility.

FR-02. BUSINESS PROFILE

The owner records legal name, optional Arabic legal name, trade licence details, TRN or TIN, address, phone, email, logo, brand color, invoice prefix, opening sequence, payment instructions, and document footer.

The pilot currency is AED. The default VAT rate is 5 percent.

FR-03. CUSTOMERS AND SUPPLIERS

Staff create, edit, search, view, and archive customers and suppliers.

A single party record supports customer, supplier, or both roles.

Each record stores identity, tax, contact, payment terms, and notes.

FR-04. VEHICLES

Staff manage owned and external vehicles.

Each vehicle stores plate number, internal label, class, capacity, make, model, year, source, linked supplier, and document-expiry dates.

Every external vehicle requires a linked supplier.

FR-05. DRIVERS

Staff manage driver profiles, contact details, employment type, linked supplier where relevant, and document-expiry dates.

Drivers have no login during the MVP.

FR-06. CUSTOMER AGREEMENTS AND ROUTE RATES

Staff record per-trip and monthly-hire agreements.

Agreements store customer terms, rate model, dates, billing grouping, default charges, VAT, and responsibility for driver, fuel, and maintenance.

Saved route rates prefill common trip details. Staff review all values before completion or invoice issue.

FR-07. WORK ORDERS

Staff create per-trip work and monthly-hire extra work.

Each work order links to a customer and agreement. Each record stores date, route, customer reference, notes, status, vehicle allocations, and charge lines.

One work order supports several vehicle allocations for large customer requests.

FR-08. VEHICLE ALLOCATIONS AND SUPPLIER PAYOUTS

Each allocation records vehicle, driver, owned or external source, supplier, supplier payable amount, and notes.

External allocations require a supplier and payable amount before settlement.

The product must support pass-through work where customer net revenue equals supplier payable and operational profit equals AED 0.00 before linked expenses.

FR-09. CUSTOMER CHARGES

Staff add transport, toll, unloading, parking, gate pass, overtime, extra day, extra trip, night shift, and other approved charges.

Each charge stores quantity, unit, unit price, discount, VAT rate, net, VAT, and gross amount.

Calculated values remain read-only.

FR-10. WORK STATUS AND HISTORY

Work uses Planned, Completed, Billed, and Canceled states.

Completed work becomes eligible for billing. Billed work links to its invoice or statement.

Users search and filter current and historical work. Users duplicate past work into a new planned record.

FR-11. PREPARE MONTH

Money staff select a customer and month.

The product loads active monthly agreements and completed unbilled work, adds monthly base charges, includes extras and per-trip work, reviews supplier payables, calculates VAT, and issues one or more invoices.

The same flow prepares related supplier settlements from unpaid external allocations.

FR-12. CUSTOMER INVOICES AND STATEMENTS

The product creates trip sheets, tax invoices, monthly statements, and customer balance statements.

Issued invoices receive a unique sequential number and an immutable snapshot.

Invoice states are Draft, Issued, Part Paid, Paid, and Void.

FR-13. SUPPLIER SETTLEMENTS

The product groups unpaid external vehicle allocations by supplier and period.

Each settlement shows work date, customer, vehicle, driver, route, payable, prior payment, and remaining amount.

Settlement states are Draft, Issued, Part Paid, Paid, and Void.

FR-14. EXPENSES

Staff record fuel, maintenance, driver pay, toll, parking, gate pass, vehicle rent, supplier payout, and other costs.

An expense links to a vehicle, driver, work order, or supplier where relevant.

FR-15. PAYMENTS

Staff record incoming and outgoing payments by cash, bank transfer, or cheque.

One payment supports allocation across several invoices, settlements, or expenses.

Only cleared payments reduce balances. A received cheque stays pending until staff mark clearance or bounce.

FR-16. BALANCES AND OPERATIONAL PROFIT

The product shows customer receivables, supplier payables, vehicle costs, and operational profit.

Operational profit equals issued customer net revenue minus external vehicle payables minus linked operating expense net amounts.

VAT stays outside operational profit.

FR-17. HOME DASHBOARD

Home shows billed revenue, received money, paid money, receivables, payables, operational profit, unbilled work, pending cheques, and expiring documents for the selected period.

Quick actions include Add work, Payment in, Add expense, and Payment out.

FR-18. REPORTS AND HISTORY

The product must support monthly and yearly periods.

Required reports include monthly operations summary, customer work statement, customer invoice and payment balance, supplier work and payment balance, owned versus external vehicle revenue, vehicle operational profit, customer operational profit, expense summary, cashbook, unbilled completed work, unpaid invoices, unpaid supplier settlements, and expiring documents.

Users filter reports by date and relevant customer, supplier, vehicle, driver, status, or category.

Reports use readable totals and tables. PDF or CSV export is available where useful.

FR-19. DOCUMENTS AND SHARING

The product generates A4 PDFs for trip sheets, invoices, statements, supplier settlements, balance statements, cashbook, and operational profit.

Documents include business branding, seller and buyer details, tax fields, line items, totals, payment terms, page numbers, and stable multi-page headers.

Users share files through the native Android or iOS share menu.

FR-20. DOCUMENT EXPIRY

The product tracks vehicle registration, insurance, inspection, driver licence, visa, and identity expiry dates where relevant.

Home and reports show due-soon, expired, and missing dates.

FR-21. OWNER EXPORT AND BACKUP

The owner exports key records by date range in CSV format.

Pilot operations include weekly encrypted database exports, export verification, and a restore drill before go-live.

12. CORE WORKFLOWS

WF-01. DAILY TRIP

Staff select a customer and agreement, enter date and route, assign one or more vehicles and drivers, enter external supplier payables, add customer charges, review totals, and mark work complete.

WF-02. MONTHLY HIRE

Staff record extra work during the month. At month end, Money staff select the customer and month, load the base agreement and extras, review totals, issue the invoice, and share the PDF.

WF-03. EXTERNAL VEHICLE PAYOUT

Staff allocate an external vehicle and payable amount to completed work. Money staff group unpaid allocations into a supplier settlement, issue the settlement, record payment out, and allocate the cleared payment.

WF-04. CUSTOMER COLLECTION

Money staff record cash, bank, or cheque payment. Cleared money is allocated to one or more invoices. The customer balance and invoice state update after valid allocation.

WF-05. MONTHLY OR YEARLY REVIEW

The owner selects a month or year, reviews work, billed revenue, collections, payouts, expenses, balances, and operational profit, then exports the needed report.

13. BUSINESS RULES

BR-01. Every work order must link to one customer and one agreement.

BR-02. Every completed work order must include at least one vehicle allocation.

BR-03. Every external allocation must include a supplier and payable amount.

BR-04. Money values use exact decimal storage and half-up rounding to two decimal places.

BR-05. A line net amount equals quantity multiplied by unit price minus discount.

BR-06. A line VAT amount equals line net multiplied by the VAT rate.

BR-07. Invoice total equals invoice net plus invoice VAT.

BR-08. Customer balance equals issued non-void invoice totals minus cleared incoming allocations.

BR-09. Supplier balance equals issued non-void settlements and unpaid expenses minus cleared outgoing allocations.

BR-10. Payment allocation must not exceed the cleared payment amount or remaining document balance.

BR-11. Issued financial documents remain unchanged. Corrections require void with a reason and reissue.

BR-12. Issued and void document numbers never return to the sequence.

BR-13. Master records use archive instead of hard delete.

BR-14. Financial actions require server confirmation before the interface shows success.

14. USER EXPERIENCE REQUIREMENTS

UX-01. Use plain English and avoid accounting terms outside the approved product vocabulary.

UX-02. Keep labels short and consistent across screens.

UX-03. Pair icons with visible text. Color must never carry status meaning by itself.

UX-04. Use direct dates such as 12 Jul 2026.

UX-05. Use AED formatting and show money to two decimal places.

UX-06. Use platform date pickers and numeric keyboards for amounts.

UX-07. Keep the most common action visible on each screen.

UX-08. Use saved routes, defaults, quick choices, and duplication to reduce typing.

UX-09. Explain the result before invoice issue, settlement issue, void, and payment allocation.

UX-10. Keep entered form values after a safe retryable network failure.

UX-11. Show loading, empty, error, offline, and success states with a clear next action.

UX-12. Keep touch targets, text, contrast, focus, and validation messages readable on common phones.

15. SECURITY AND DATA REQUIREMENTS

SD-01. Every business record belongs to one tenant.

SD-02. Every business query requires an authenticated active tenant member.

SD-03. Database Row Level Security enforces tenant boundaries and access packs.

SD-04. The mobile app never stores a service-role key.

SD-05. Privileged financial operations run inside database transactions.

SD-06. Issue, void, payment allocation, and cheque-state changes produce audit records.

SD-07. Issued documents use saved snapshots of business, customer, branding, line, tax, and total data.

SD-08. Offline access is read-only for saved dashboard totals, master data, and recent work. Writes require an internet connection.

SD-09. Sign-out or membership removal clears saved tenant data from the device.

16. MVP EXCLUSIONS

The first release excludes driver login, trip status actions, live location, GPS hardware integration, full offline editing, payroll, WPS export, formal accounting, bank reconciliation, percentage commission rules, receipt-image storage, web dashboard, multi-branch operation, self-service tenant signup, SaaS billing, KSA support, and structured UAE electronic-invoice exchange through an accredited service provider.

17. SUCCESS MEASURES

SM-01. Every completed pilot work record links to its customer, vehicle, driver, charges, and owned or external source.

SM-02. Customer invoices, supplier payouts, payments, expenses, and reports reuse the original work record without duplicate job entry.

SM-03. The owner completes month-end billing and payout review without rebuilding totals in a spreadsheet.

SM-04. Monthly and yearly reports match source records to AED 0.01.

SM-05. A trained staff member records a common one-vehicle trip in under three minutes.

SM-06. A ten-vehicle job supports four owned and six external allocations from one phone workflow.

SM-07. Partial cheque payment changes an invoice balance only after cheque clearance.

SM-08. Issued invoice content and branding stay unchanged after later master-data edits.

SM-09. Staff without Money access do not see profit or protected financial actions.

SM-10. Every assigned pilot user completes the main role workflow after one guided training session.

18. ACCEPTANCE SCENARIOS

AS-01. Monthly hire produces the agreed base charge, extras, 5 percent VAT, final total, customer balance, and matching PDF.

AS-02. Per-trip work produces a multi-page monthly statement where every row links to one work order.

AS-03. A large statement keeps page headers, invoice references, and totals readable across pages.

AS-04. External allocations appear in supplier settlements. Owned allocations stay outside supplier settlements.

AS-05. Pass-through work shows AED 0.00 operational profit before linked expenses.

AS-06. Payment allocation above the cleared payment or document balance fails without partial data loss.

AS-07. Operations staff cannot view profit. A member from another tenant cannot read pilot data.

AS-08. Voided document numbers remain reserved.

19. DELIVERY PHASES

PHASE 1, FOUNDATION

Deliver tenant setup, authentication, access packs, customers, suppliers, vehicles, drivers, agreements, route rates, business profile, and opening data.

PHASE 2, WORK AND SUPPLIER COST

Deliver work orders, multiple vehicle allocations, per-trip charges, monthly-hire extras, completion states, duplication, and external supplier payables.

PHASE 3, DOCUMENTS AND MONEY

Deliver invoices, statements, supplier settlements, expenses, payments, balances, PDF generation, and native sharing.

PHASE 4, REPORTS AND PILOT HARDENING

Deliver monthly and yearly reports, expiry lists, exports, backups, acceptance testing, staff training, and Android and iOS pilot releases.

20. CURRENT REPOSITORY STATUS

The repository contains a Flutter mobile prototype with Stacked MVVM structure and four main tabs.

The prototype includes routes and screens for authentication, dashboard, work entry, work detail, monthly preparation, invoices, statements, settlements, payments, expenses, balances, reports, parties, vehicles, drivers, agreements, route rates, staff access, business profile, and PDF preview.

The current report interface includes operational profit, owned versus external revenue, vehicle profit, expense summary, cashbook, unbilled work, unpaid invoices, and expiring documents.

Every operational and financial repository reads and writes tenant-scoped Supabase tables; financial state transitions run in privileged Postgres functions.

Supabase authentication runs when environment credentials exist. A release build stops when Supabase credentials are missing.

The repository includes the production Supabase schema as versioned migrations with Row Level Security policies and privileged financial database functions, plus pgTAP tests for them.

The current period picker uses fixed 2025 and 2026 values. Production work must replace fixed dates with current and historical periods from saved data.

PDF generation code exists. Production validation must confirm tax fields, immutable snapshots, long tables, file sharing, and exact totals.

Automated tests cover demo data and several ViewModels. Production readiness still needs repository integration tests, security policy tests, financial transaction tests, and end-to-end acceptance runs.

21. FUTURE GOALS

Add future work only after pilot usage and paid demand support the effort.

NEAR TERM AFTER PILOT

Add the confirmed interface languages, receipt images, stronger offline reading, full opening-data import, and report refinements requested by pilot users.

OPERATIONS EXPANSION

Add driver login, pickup and delivery states, odometer capture, overtime entry, phone location during active work, and selected GPS hardware integrations.

FINANCE EXPANSION

Add percentage or fixed commission rules, payroll and WPS exports, formal accounting integration, bank reconciliation, and structured UAE electronic-invoice exchange.

BUSINESS EXPANSION

Add a web back-office dashboard, multi-branch records, self-service onboarding, subscription billing, and support for more operators.

MARKET EXPANSION

Add KSA support and ZATCA integration only after the UAE product proves paid demand and compliance work receives a separate scope.

22. INFORMATION NEEDED FROM THE CLIENT

IN-01. Confirm the legal business name, trade licence details, TRN, address, logo, invoice prefix, opening invoice number, and payment instructions.

IN-02. Confirm each pilot user, role, email, and access level.

IN-03. Confirm the languages spoken by the 2 to 5 users and the preferred interface language order.

IN-04. Provide the exact monthly and yearly reports used today, including required columns and sample outputs.

IN-05. Confirm customer billing terms, VAT exceptions, supplier payout rules, cheque handling, and approval steps.

IN-06. Confirm which historical records need import, the earliest required date, and the agreed go-live date.

IN-07. Confirm supported phones, Android and iOS priorities, and expected internet quality during work.

IN-08. Confirm whether cancellation reasons are required and whether completed unbilled work stays editable.

IN-09. Confirm backup ownership, support hours, and the production Supabase plan.

23. REPOSITORY SOURCES REVIEWED

README.md defines the current product summary and run setup.

ARCHITECTURE.md defines the Flutter structure, money rules, backend direction, security direction, and delivery phases.

DESIGN.md defines color tokens, spacing, typography, and shared UI primitives.

RULES.md defines development and AI agent standards, source-of-truth order, and definition of done.

doc/Transport_Fleet_MVP_Blueprint.md defines the validated business flow, MVP boundary, records, calculations, reports, security model, and acceptance scenarios.

doc/Transport_Fleet_MVP_Design_Brief.md defines users, screens, interaction rules, accessibility, reports, and mobile behavior.

doc/Transport_Fleet_MVP_Flow.svg shows the end-to-end work, billing, payout, payment, and profit flow.

doc/research/README.md and the linked client samples provide evidence for monthly hire, per-trip work, multi-page statements, mixed fleets, VAT, extras, and supplier payouts.

lib/features shows the current interactive feature coverage; supabase/migrations holds the schema, RLS, and financial functions.
