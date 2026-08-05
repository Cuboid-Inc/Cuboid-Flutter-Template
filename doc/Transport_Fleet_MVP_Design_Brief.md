# UAE Transport Fleet Management MVP

## Product Design Brief

Version: 1.0  
Status: Ready for client and design validation  
Market: United Arab Emirates  
Pilot: One transport operator, one location  
Platforms: Flutter mobile app for Android and iOS  
Primary source: `Transport_Fleet_MVP_Blueprint.md`  

## 1. Purpose of this brief

This brief translates the approved product and system blueprint into a complete mobile product design specification. It defines the user experience, information architecture, screen inventory, screen behavior, visual system, interaction rules, accessibility needs, document presentation, edge states, permissions, and design acceptance criteria for the MVP.

The brief is intended for:

- The client owner validating the workflow.
- Product and UX designers preparing wireframes and high-fidelity designs.
- Flutter engineers implementing the mobile experience.
- Backend engineers aligning permissions and financial transactions.
- QA staff preparing functional and visual acceptance tests.

The product blueprint remains the source of truth for business rules, calculations, security, data ownership, and technical architecture. This brief is the source of truth for the mobile experience.

## 2. Product summary

The product is a mobile operations and money app for a small UAE transport operator. It replaces paper records, Excel sheets, repeated totals, scattered payment notes, and repeated invoice preparation.

One work record must drive:

- Customer billing.
- External vehicle supplier payables.
- Owned-vehicle expenses.
- Incoming and outgoing payments.
- Customer and supplier balances.
- Operational profit.

The core promise is simple. Staff enter transport work once. The owner sees the operational and financial result without rebuilding the month in Excel.

## 3. Product goals

The app must help the owner answer six questions quickly:

1. What work did the business perform?
2. Which vehicle and driver performed each job?
3. Did the business use an owned or external vehicle?
4. What amount should each customer pay?
5. What amount does the business owe suppliers, drivers, and operating expenses?
6. What operational profit remains?

### 3.1 MVP success outcome

The owner completes month-end billing, supplier settlement, payment review, and operational profit review inside the app without recreating records in Excel.

### 3.2 Supporting outcomes

- Staff capture one trip once.
- Customer invoices use correct totals and stable document numbers.
- External vehicle costs flow into supplier settlements.
- Cleared payments update balances accurately.
- Issued documents remain unchanged after source data or branding changes.
- The owner spots unbilled work, unpaid balances, pending cheques, and expiring documents from the Home area.

## 4. MVP boundary

### 4.1 Included

- Business profile and fixed document branding.
- Owner and staff accounts.
- Staff access packs.
- Customers and suppliers.
- Owned and external vehicles.
- Managed driver profiles.
- Per-trip and monthly-hire agreements.
- Work orders with one or many vehicle allocations.
- Customer charge lines.
- External supplier payable amounts.
- Fuel, maintenance, driver, toll, parking, rent, supplier, and other expenses.
- Trip sheets, tax invoices, monthly statements, supplier settlements, balance statements, cashbook, and operational profit reports.
- Incoming and outgoing payments.
- Cash, bank transfer, and cheque methods.
- Partial payment allocation.
- Customer and supplier balances.
- Operational profit reporting.
- Vehicle and driver document-expiry dates.
- Opening-data import support.
- PDF generation on demand.
- Android and iOS native sharing.
- Read-only cached data while offline.

### 4.2 Excluded

- Driver accounts.
- Pickup, drop, or in-transit status tracking.
- Live location or GPS hardware.
- Offline record creation or editing.
- Payroll or WPS export.
- General ledger, bank reconciliation, formal profit-and-loss, or VAT return.
- Percentage commission rules.
- Receipt-image storage.
- Web dashboard.
- Multi-branch operation.
- Self-service tenant registration.
- Subscription billing.
- KSA or ZATCA support.
- UAE ASP electronic invoice exchange.
- Drag-and-drop document layout editing.
- WhatsApp Business API integration.
- Background creation of invoices or settlements.

Designs must not imply excluded features through controls, labels, navigation, empty states, or promotional copy.

## 5. Users and design priorities

### 5.1 Owner

The owner has full tenant access. The owner manages operations, money, reports, staff, business settings, document sequences, exports, void actions, and backup visibility.

Design priorities:

- Show business position within seconds.
- Make month preparation easy to review.
- Make financial consequences visible before issue, void, or allocation actions.
- Keep audit details accessible without crowding daily screens.
- Prevent accidental changes to issued financial records.

### 5.2 Operations staff

Operations staff create, edit, complete, cancel, and view work orders and vehicle allocations. They view required customer, agreement, vehicle, and driver details.

Design priorities:

- Fast work capture.
- Easy duplication of previous work.
- Efficient allocation of several vehicles.
- Clear separation between owned and external vehicles.
- Clear completion and cancellation rules.

### 5.3 Master Data staff

Master Data staff create, edit, archive, and view customers, suppliers, vehicles, drivers, and agreements.

Design priorities:

- Clear forms with conditional fields.
- Strong duplicate prevention cues.
- Archive controls to avoid accidental data loss.
- Expiry information visible where relevant.

### 5.4 Money staff

Money staff manage charge lines, invoices, expenses, payments, settlements, balances, and operational profit.

Design priorities:

- Exact financial values.
- Traceability from document to work.
- Clear status and remaining balance.
- Safe issue, payment, and allocation workflows.
- Strong handling of cheque clearance.

### 5.5 Reports staff

Reports staff view, generate, export, and share approved reports and documents.

Design priorities:

- Predictable filters.
- Useful totals and tables.
- Clear export and share actions.
- No edit controls.

### 5.6 Drivers

Drivers are managed records. They have no login, app access, or mobile workflow in the MVP.

## 6. Experience principles

### 6.1 Capture once

The work order is the operational source. Billing, supplier payables, expenses, balances, and profit link back to the same record.

### 6.2 Show money with context

Every financial value should show its label, currency, status, and relevant party or document. Never use color as the only meaning.

### 6.3 Make status obvious

Every work order, invoice, settlement, expense, payment, cheque, customer, supplier, vehicle, driver, and agreement must show its current state in list and detail views.

### 6.4 Protect final records

Draft records support editing. Issued financial records are read-only. Corrections use void and reissue. The interface must explain this rule before issue.

### 6.5 Prefer review over automation

The app preloads agreement defaults and eligible work. Staff review values before issue. No background process creates financial documents.

### 6.6 Design for real mobile work

Forms use large touch targets, clear sectioning, searchable selectors, saved drafts where allowed, and persistent totals. Long data tables adapt into readable mobile rows.

### 6.7 Keep the MVP small

Use one fixed document layout, four main navigation areas, a small component set, totals and tables instead of complex charts, and native sharing instead of custom integrations.

## 7. Operating context

- Primary use takes place on Android and iOS phones.
- Users work in an office, vehicle yard, or customer location.
- Network quality varies.
- All writes need an internet connection and confirmed server response.
- Users handle long business names, references, plate numbers, routes, and money values.
- The pilot currency is AED.
- The default VAT rate is 5 percent.
- English is the primary app language for the pilot.
- Arabic legal names and Arabic header artwork appear in business and document data where supplied.
- The app must remain usable at common mobile widths from 320 to 430 logical pixels.
- Tablet layouts should expand content naturally, without a separate tablet product.

## 8. Information architecture

The app uses four persistent top-level areas.

| Area | Primary purpose | Main destinations |
|---|---|---|
| Home | Business position and urgent work | KPIs, action items, quick actions, expiry alerts |
| Work | Capture and prepare transport work | Work list, work detail, create work, monthly preparation |
| Money | Bill, collect, pay, and review profit | Invoices, statements, payments, settlements, expenses, balances, profit |
| More | Manage records and administration | Parties, vehicles, drivers, agreements, reports, staff, business settings, opening data, exports |

### 8.1 Bottom navigation

Use a four-item bottom navigation bar:

- Home.
- Work.
- Money.
- More.

Each item uses an icon and visible text label. Preserve the selected tab and its navigation stack when users move between tabs.

### 8.2 Permission-aware navigation

- Show only areas and actions the signed-in user has permission to use.
- Keep Home visible to every authenticated member, with cards filtered by permission.
- Show Work to Operations users and the owner.
- Show Money to Money users and the owner.
- Show More to every user, with destinations filtered by access packs.
- Do not show disabled financial or owner-only controls to unauthorized staff.
- If a user opens an outdated deep link without permission, show an Access unavailable screen and a Back action.

### 8.3 Navigation behavior

- Use full-screen routes for create and multi-step flows.
- Use detail routes for records and documents.
- Use bottom sheets for short filters, selectors, and confirmations.
- Use dialogs only for destructive or legally important confirmation, such as voiding.
- Keep a visible Back action on every non-root screen.
- Warn before leaving a form with unsaved changes.

## 9. Global app shell

### 9.1 Launch

- Show a simple branded launch screen while restoring the secure session.
- Route authenticated users to Home.
- Route signed-out users to Sign in.
- Route a user with an expired invitation to Invitation expired.
- Route an authenticated account without active tenant membership to Access unavailable.

### 9.2 Top app bar

The top app bar contains:

- Screen title.
- Back action where needed.
- One primary contextual action where useful.
- Overflow menu for secondary actions.
- Offline indicator when cached data is shown.

Avoid placing more than two actions in the app bar.

### 9.3 Global offline banner

When offline, show a persistent banner below the app bar:

`Offline. Showing saved data. Editing is unavailable.`

Rules:

- Disable create, edit, issue, void, payment, export generation, and invitation actions.
- Keep cached Home totals, parties, vehicles, drivers, agreements, and recent work readable.
- Mark the last successful refresh time.
- Offer Retry.
- Never present an offline edit form as savable.

### 9.4 Global feedback

- Use inline validation for field errors.
- Use a short confirmation message after successful saves.
- Keep transaction progress visible for issue, void, payment allocation, PDF generation, and export actions.
- Prevent repeated taps while a transaction is processing.
- Return a specific recovery action after failure.

## 10. Screen inventory

### 10.1 Authentication and access

| ID | Screen | Purpose |
|---|---|---|
| AUTH-01 | Sign in | Email and password authentication |
| AUTH-02 | Forgot password | Request password reset email |
| AUTH-03 | Reset password | Set a new password from a valid link |
| AUTH-04 | Accept invitation | Confirm invited email and set password |
| AUTH-05 | Invitation expired | Explain failure and direct user to owner |
| AUTH-06 | Access unavailable | Handle removed, inactive, or unauthorized membership |

### 10.2 Home

| ID | Screen | Purpose |
|---|---|---|
| HOME-01 | Home dashboard | Show current position, alerts, and quick actions |
| HOME-02 | Dashboard metric detail | Show records behind a selected total |
| HOME-03 | Expiry alerts | List vehicle and driver documents nearing expiry |
| HOME-04 | Pending cheques | List received cheques awaiting clearance |

### 10.3 Work

| ID | Screen | Purpose |
|---|---|---|
| WORK-01 | Work list | Search, filter, and open work orders |
| WORK-02 | Work detail | Review work, allocations, charges, links, and activity |
| WORK-03 | Create work | Capture a per-trip or monthly-hire extra work order |
| WORK-04 | Edit work | Change an eligible draft or completed unbilled work order |
| WORK-05 | Vehicle allocations | Add and manage one or many vehicle allocations |
| WORK-06 | Allocation editor | Select vehicle, driver, source, supplier, and payable |
| WORK-07 | Bulk-copy allocations | Repeat common values for several external allocations |
| WORK-08 | Customer charge lines | Add and manage charge lines and totals |
| WORK-09 | Charge-line editor | Set quantity, price, discount, tax, and description |
| WORK-10 | Complete work | Review required values and mark work completed |
| WORK-11 | Cancel work | Record a cancellation confirmation |
| WORK-12 | Duplicate work | Review copied values before saving a new work order |
| WORK-13 | Prepare monthly invoice | Select customer and month |
| WORK-14 | Monthly preparation review | Review agreements, work, charges, allocations, VAT, and grouping |
| WORK-15 | Monthly issue review | Confirm final invoice or invoices before issue |
| WORK-16 | Preparation result | Open issued invoices, statement, and supplier follow-up |

### 10.4 Money

| ID | Screen | Purpose |
|---|---|---|
| MONEY-01 | Money hub | Open financial areas and see key totals |
| INV-01 | Invoice list | Search and filter customer invoices |
| INV-02 | Invoice detail | Review snapshot, balance, work, payments, and activity |
| INV-03 | Invoice draft | Review and edit a draft invoice |
| INV-04 | Issue invoice | Confirm immutable issue transaction |
| INV-05 | Void invoice | Owner records reason and confirms void |
| INV-06 | Invoice PDF preview | Preview, generate, and share invoice PDF |
| STMT-01 | Statement list | Find monthly and balance statements |
| STMT-02 | Statement setup | Choose party, period, and statement type |
| STMT-03 | Statement preview | Review rows and totals before PDF generation |
| SETTLE-01 | Settlement list | Search and filter supplier settlements |
| SETTLE-02 | Prepare settlement | Select supplier, period, and eligible allocations |
| SETTLE-03 | Settlement draft | Review payable lines and total |
| SETTLE-04 | Settlement detail | Review status, payments, source work, and activity |
| SETTLE-05 | Issue settlement | Confirm immutable issue transaction |
| SETTLE-06 | Void settlement | Owner records reason and confirms void |
| EXP-01 | Expense list | Search and filter expenses |
| EXP-02 | Expense detail | Review amount, links, status, payments, and activity |
| EXP-03 | Create expense | Capture an operating cost |
| EXP-04 | Edit expense | Change an eligible expense |
| PAY-01 | Payment list | Search incoming and outgoing payments |
| PAY-02 | Payment detail | Review method, state, allocations, and activity |
| PAY-03 | Record payment in | Capture money received |
| PAY-04 | Record payment out | Capture money paid |
| PAY-05 | Allocate payment | Apply a cleared amount to eligible documents |
| PAY-06 | Cheque state | Move cheque from received to cleared or bounced |
| BAL-01 | Customer balances | List customer receivables |
| BAL-02 | Customer balance detail | Show invoices, payments, and remaining balance |
| BAL-03 | Supplier balances | List supplier payables |
| BAL-04 | Supplier balance detail | Show settlements, expenses, payments, and remaining balance |
| PROFIT-01 | Profit overview | Show operational profit for a selected period |
| PROFIT-02 | Profit detail | Break profit down by customer, vehicle, or work |

### 10.5 Master data and administration

| ID | Screen | Purpose |
|---|---|---|
| PARTY-01 | Party list | Find customers, suppliers, or dual-role parties |
| PARTY-02 | Party detail | Review identity, contacts, terms, balances, and linked records |
| PARTY-03 | Create or edit party | Manage party details and roles |
| VEH-01 | Vehicle list | Find owned and external vehicles |
| VEH-02 | Vehicle detail | Review identity, supplier, expiry, work, expenses, and profit |
| VEH-03 | Create or edit vehicle | Manage vehicle fields and conditional supplier link |
| DRIVER-01 | Driver list | Find employed and external drivers |
| DRIVER-02 | Driver detail | Review identity, expiry, supplier, and work |
| DRIVER-03 | Create or edit driver | Manage driver fields and conditional supplier link |
| AGR-01 | Agreement list | Find active, future, expired, and archived agreements |
| AGR-02 | Agreement detail | Review rates, responsibilities, terms, and linked work |
| AGR-03 | Create or edit agreement | Manage per-trip or monthly-hire terms |
| STAFF-01 | Staff list | Owner reviews staff status and access packs |
| STAFF-02 | Invite staff | Owner sends a secure invitation |
| STAFF-03 | Staff detail | Owner changes access packs or deactivates access |
| BIZ-01 | Business profile | Owner manages business and tax identity |
| BRAND-01 | Document branding | Owner manages logo, color, artwork, footer, and payment text |
| SEQ-01 | Document sequence | Owner sets prefix and opening number before first issue |
| OPEN-01 | Opening data status | Owner reviews imported record counts and go-live date |
| EXPORT-01 | Owner export | Owner requests CSV exports for key records |
| BACKUP-01 | Backup status | Owner reviews latest verified export and restore drill status |
| REPORT-01 | Report catalog | Browse available reports |
| REPORT-02 | Report filters | Set report period and dimensions |
| REPORT-03 | Report result | Review totals and rows |
| REPORT-04 | Report export | Generate PDF or CSV where supported |

## 11. Authentication and invitation experience

### 11.1 Sign in

Fields:

- Email.
- Password.

Actions:

- Sign in.
- Forgot password.

Behavior:

- Use email keyboard and platform password autofill.
- Allow password visibility toggle.
- Show a generic invalid-credentials message.
- Keep the submit action disabled until both fields contain valid input.
- Store the authenticated session in operating-system secure credential storage.

### 11.2 Staff invitation

The owner enters:

- Staff email.
- Display name.
- One or more access packs.

The review step shows the resulting rights in plain language. The app sends the invitation through the secure staff-invitation backend function. Do not expose a service-role credential.

### 11.3 Accept invitation

The invited user sees:

- Business name.
- Invited email, locked.
- Assigned access packs.
- New password.
- Confirm password.
- Accept invitation action.

### 11.4 Removed or inactive access

If membership becomes inactive:

- End access to tenant data.
- Show Access unavailable.
- Offer Sign out.
- Do not expose cached business data after access removal is confirmed by the server.

## 12. Home design

### 12.1 Dashboard hierarchy

Use this order:

1. Greeting, business name, current month, and offline state.
2. Quick actions.
3. Revenue and money summary.
4. Balance and profit summary.
5. Work and cheque action items.
6. Expiry alerts.

### 12.2 Quick actions

Show permission-aware actions:

- Add Work.
- Payment In.
- Add Expense.
- Payment Out.

Use a two-by-two grid on phones. Each action needs an icon and label.

### 12.3 Dashboard metrics

Required current-month cards:

- Billed revenue.
- Money received.
- Money paid.
- Customer receivables.
- Supplier payables.
- Operational profit.

Each card shows:

- Metric name.
- AED amount.
- Period label.
- Supporting record count where useful.
- Tap action to filtered detail if permitted.

Do not use trend percentages in the MVP because the blueprint does not define comparative analytics.

### 12.4 Action items

Show count-based rows for:

- Completed work awaiting billing.
- Cheques awaiting clearance.
- Vehicle documents nearing expiry.
- Driver documents nearing expiry.

Use explicit labels such as `4 completed jobs need billing`. Do not rely on colored dots alone.

### 12.5 Dashboard permission behavior

- Operations-only users see work counts and expiry information relevant to operations.
- Money users see financial metrics.
- Reports users see report-supported totals where allowed.
- Users without Money permission do not see revenue, balances, or profit.
- The owner sees all cards.

## 13. Work experience

### 13.1 Work list

Default view:

- Current month.
- All non-canceled statuses.
- Newest work date first.

Search across:

- Customer.
- Work date.
- Driver.
- Vehicle.
- Pickup or destination.
- Invoice number.
- Status.

Filters:

- Date range.
- Customer.
- Agreement.
- Work type.
- Status.
- Vehicle source, owned or external.
- Vehicle.
- Driver.
- Billing state.

Each list row shows:

- Work date.
- Customer display name.
- Route or description.
- Work type.
- Vehicle count.
- Gross customer amount where the user has Money permission.
- Status badge.
- Billing reference when billed.

Primary action: Add Work.  
Secondary action: Prepare Month for Money users and the owner.

### 13.2 Work detail

Sections:

- Summary.
- Customer and agreement.
- Route and schedule.
- Vehicle allocations.
- Customer charges.
- Supplier payable total.
- Linked invoice or statement.
- Linked expenses.
- Notes.
- Created and updated metadata.

Actions depend on state:

| State | Available actions |
|---|---|
| Planned | Edit, Complete, Cancel, Duplicate, Delete if allowed |
| Completed and unbilled | Edit, Add to billing, Cancel if business rules permit, Duplicate |
| Billed | View invoice, View PDF, Duplicate |
| Canceled | Duplicate |

Once billed, source values shown on the issued invoice stay locked in the invoice snapshot even if an eligible non-financial source field later changes.

### 13.3 Create work structure

Use one full-screen form with progressive sections, not a long wizard. Keep section summaries collapsed after completion.

Sections:

1. Work type.
2. Customer and agreement.
3. Date, time, and route.
4. Vehicle allocations.
5. Customer charges.
6. References and notes.
7. Review and save.

Required base fields:

- Customer.
- Agreement.
- Work date.
- Work type.
- At least one vehicle allocation before completion.
- At least one valid customer charge before billing.

Optional base fields:

- Planned start.
- Planned end.
- Pickup place.
- Destination or service place.
- Customer job reference.
- Description.
- Notes.

### 13.4 Agreement selection

- Filter agreements by selected customer.
- Put active agreements first.
- Show rate model, date range, and reference in the selector.
- Warn when the work date falls outside the agreement date range.
- Load agreement defaults after selection.
- Tell the user which values were prefilled.
- Allow review and eligible edits before invoice issue.
- Auto-select only when a customer has exactly one matching agreement; require an explicit choice when there is more than one.

### 13.5 Work type behavior

Per trip:

- Emphasize pickup, destination, vehicle allocations, transport rate, and trip extras.
- Common charges include transport service, toll, unloading, parking, and gate pass.

Monthly-hire work:

- One screen records the base rate and any number of extra charges together, in a single submission.
- The base-rate line is prefilled from the agreement and can be removed if this month's base was already recorded elsewhere.
- Each extra charge has a type, quantity, and rate. Rate prefills from the agreement's defaults (overtime, extra day, extra trip, or a named preset extra such as parking) and stays editable.
- Common charge types include overtime, extra day, extra trip, night shift, parking, toll, gate pass, and other approved charge.

### 13.6 Vehicle allocations

Each allocation captures:

- Vehicle.
- Driver.
- Source, owned or external.
- Supplier for external source.
- Supplier payable amount for external source.
- Notes.

Behavior:

- Derive source from the selected vehicle where possible.
- Require supplier for every external allocation.
- Keep supplier payable hidden for owned allocations.
- Keep supplier payable visible only to users with Money permission.
- Allow the work creator to add several allocations without leaving the work form.
- Show a compact summary row for each allocation.
- Show allocation count and total external payable at the section header.

### 13.7 Bulk-copy allocations

For large requests:

- Start from an existing allocation.
- Ask how many copies to add.
- Copy supplier, vehicle class, driver classification, and default payable where relevant.
- Leave unique vehicle and driver selection empty unless the user explicitly chooses the same record.
- Show all new rows for review before save.

The ten-vehicle acceptance case must stay usable on a phone without ten separate navigation cycles.

### 13.8 Customer charge lines

Each line captures:

- Name.
- Description.
- Quantity.
- Unit of measure.
- Unit price.
- Discount, optional.
- Tax category.
- VAT rate.
- Calculated net.
- Calculated VAT.
- Calculated gross.

Behavior:

- Use common charge names as quick choices.
- Allow Other charge with a required custom name.
- Recalculate totals as inputs change.
- Present calculated fields as read-only.
- Keep a sticky order summary above the primary save action.
- Format values to two decimals.
- Use half-up rounding for displayed and stored financial results.

### 13.9 Complete work

Before completion, show a review checklist:

- Customer and agreement selected.
- Work date present.
- Route or description present where relevant.
- Every allocation has required vehicle, driver, source, and supplier data.
- External allocations have supplier payables.
- Customer charges are valid.

The confirmation action reads `Mark completed`. Completion makes the work eligible for billing. It does not issue an invoice.

### 13.10 Cancel work

- State canceled work is excluded from billing.
- Require confirmation.
- Capture a short reason if the client approves reason tracking during validation.
- Never show financial issue controls after cancellation.

### 13.11 Duplicate work

Copy:

- Customer.
- Agreement.
- Work type.
- Route.
- Description.
- Allocations.
- Charge-line structure and rates.
- Notes.

Reset:

- Work date to the selected new date.
- Status to Planned.
- Invoice links.
- Payment links.
- Audit metadata.

Show a review screen before save.

## 14. Prepare Month experience

Prepare Month is a single screen, not a multi-step wizard. The monthly-hire work it bills was already assembled in one submission by the Monthly Work screen, so this screen only needs to scope, review, and issue.

Inputs:

- Customer.
- Month.

The screen loads that period's eligible work for the customer, grouped into:

- Monthly-hire work.
- Per-trip work.

Every eligible item starts pre-selected; staff deselect anything that should not be billed yet. Canceled or already-billed work never appears.

A single "Issue invoice" confirmation replaces a multi-step review, with supporting text:

`Issued invoices receive final numbers and cannot be edited. Corrections use void and reissue.`

### Result

After a successful issue, show:

- Issued invoice numbers.
- Gross total.
- Statement generation action.
- PDF preview and share action.
- Prepare supplier settlements action for external allocations.
- Return to Work action.

If one transaction fails, do not show a partial success state unless the backend confirms separate completed transactions. Reflect the server result exactly.

## 15. Money hub

The Money root screen gives access to:

- Customer invoices.
- Monthly statements.
- Incoming payments.
- Supplier settlements.
- Expenses.
- Outgoing payments.
- Customer balances.
- Supplier balances.
- Operational profit.

The top summary shows:

- Receivables.
- Supplier payables.
- Received cheques awaiting clearance.
- Current-month money in.
- Current-month money out.

Use labeled rows or compact cards. Avoid charts.

## 16. Invoice experience

### 16.1 Invoice list

Search:

- Invoice number.
- Customer.
- Customer reference.
- Work reference.

Filters:

- Issue date range.
- Customer.
- Status.
- Due state.
- Payment state.

Each row shows:

- Invoice number or Draft.
- Customer.
- Issue date.
- Due date where available.
- Total.
- Remaining balance.
- Status.

### 16.2 Draft invoice

Sections:

- Seller and buyer preview.
- Dates and payment terms.
- Linked work.
- Charge lines.
- Net, VAT, and gross totals.
- Notes and footer preview.

Users with Money permission edit eligible draft values. Final document numbers do not exist in draft state.

### 16.3 Issue confirmation

Before issue, show:

- Customer.
- Document date.
- Number prefix and next-number explanation, without promising a number before the transaction completes.
- Net, VAT, and gross.
- Linked work count.
- Immutable-record message.

The server assigns the unique sequential number in the issue transaction.

### 16.4 Issued invoice detail

Header:

- Invoice number.
- Status.
- Customer.
- Gross total.
- Remaining balance.

Sections:

- Snapshot details.
- Charge lines.
- Linked work.
- Payment allocations.
- PDF and sharing.
- Financial activity.

Actions:

- Generate or view PDF.
- Share.
- Record payment in.
- View customer balance.
- Void, owner only.

No edit action appears.

### 16.5 Invoice status presentation

| Status | Meaning in UI | Main action |
|---|---|---|
| Draft | Editable, no final number | Review and issue |
| Issued | Final and unpaid | Record payment |
| Part Paid | Partially covered by cleared allocations | Record payment |
| Paid | Fully covered by cleared allocations | View receipt trail |
| Void | Canceled financial record, number retained | View void reason |

### 16.6 Void invoice

Owner-only flow:

1. Show invoice number, customer, issue date, and total.
2. State the number stays reserved.
3. Require a void reason.
4. Require final confirmation.
5. Show the void state and activity record.

Do not offer delete.

## 17. Statements and PDF documents

### 17.1 Statement types

- Monthly Statement.
- Customer Balance Statement.
- Supplier Balance Statement.

### 17.2 Statement setup

Inputs depend on type:

- Customer or supplier.
- Date range or month.
- Include work details where relevant.
- Include paid or closed items where relevant.

### 17.3 Statement preview

Show a mobile summary first:

- Party.
- Period.
- Opening balance where supported.
- Period activity.
- Payments.
- Closing balance.
- Row count.

Then show rows in a mobile list. The PDF remains the authoritative A4 table presentation.

### 17.4 PDF actions

- Generate PDF on demand.
- Show progress while generating.
- Preview PDF.
- Share through the native Android or iOS share sheet.
- Regenerate from snapshot data when requested.
- Do not store PDF binaries in the database.

## 18. Supplier settlement experience

### 18.1 Settlement list

Search:

- Settlement reference.
- Supplier.
- Work order.
- Vehicle.
- Driver.

Filters:

- Period.
- Supplier.
- Status.
- Remaining balance.

### 18.2 Prepare settlement

Inputs:

- Supplier.
- Period.

Eligible rows come from unpaid external vehicle allocations. Each row shows:

- Date.
- Work order.
- Customer.
- Vehicle.
- Driver.
- Route.
- Agreed payable.
- Prior payment.
- Remaining amount.

Users select eligible rows and review the total. Owned allocations never appear.

### 18.3 Settlement detail and lifecycle

Use Draft, Issued, Part Paid, Paid, and Void states. Issued settlement snapshots are read-only. Corrections use owner void and reissue.

Actions:

- Issue draft.
- Generate PDF.
- Share PDF.
- Record payment out.
- View supplier balance.
- Void, owner only.

### 18.4 Pass-through work

When customer net revenue and supplier payable are equal, show both values without warning. Operational profit for the allocation is AED 0.00 before linked expenses.

## 19. Expense experience

### 19.1 Expense list

Search:

- Payee.
- Description.
- Reference.
- Vehicle.
- Driver.
- Work order.

Filters:

- Date range.
- Category.
- Payee.
- Vehicle.
- Driver.
- Payment status.

Each row shows date, category, payee, linked vehicle or work where present, total, and status.

### 19.2 Expense form

Fields:

- Date.
- Category.
- Supplier or payee.
- Vehicle, optional.
- Driver, optional.
- Work order, optional.
- Description.
- Net amount.
- VAT amount, optional.
- Total amount.
- Due date, optional.
- Status.
- Reference.
- Notes.

Categories:

- Fuel.
- Maintenance.
- Driver pay.
- Toll.
- Parking.
- Gate pass.
- Vehicle rent.
- Supplier payout.
- Other.

Behavior:

- Show related vehicle, driver, and work selectors only where useful.
- Calculate total from net and VAT when both values are entered.
- Require description for Other.
- State only linked expense net amounts reduce work or vehicle operational profit.
- Do not offer receipt-image upload.

The blueprint does not define the full expense lifecycle. Final status labels and edit-lock rules need client validation before high-fidelity design.

## 20. Payment experience

### 20.1 Payment direction

Use separate entry points:

- Payment In.
- Payment Out.

Keep one shared form pattern after the direction is set.

### 20.2 Payment fields

- Direction, locked from entry point.
- Party.
- Date.
- Amount.
- Method, cash, bank transfer, or cheque.
- Bank or cheque reference.
- Cheque date.
- Cheque state, received, cleared, or bounced.
- Notes.
- Allocations.

### 20.3 Method behavior

Cash:

- Reference optional.
- Eligible for allocation after server confirmation.

Bank transfer:

- Bank reference visible and strongly recommended.
- Eligible for allocation after server confirmation.

Cheque:

- Cheque reference and cheque date required.
- Initial state defaults to Received.
- Received cheques do not reduce balances.
- Cleared cheques become eligible for allocation.
- Bounced cheques do not reduce balances.

### 20.4 Payment allocation

The allocation screen shows:

- Payment amount.
- Cleared amount available.
- Allocated amount.
- Unallocated amount.
- Eligible documents for the selected party and direction.

Incoming payments allocate to customer invoices. Outgoing payments allocate to supplier settlements or eligible expenses.

Each document row shows:

- Number or reference.
- Date.
- Original total.
- Remaining balance.
- Allocation input.

Validation:

- Total allocations must not exceed the cleared payment amount.
- A single allocation must not exceed the document remaining balance.
- The payment party must match the document party.
- Received or bounced cheques cannot be allocated.
- Server validation remains authoritative.

### 20.5 Cheque state change

Show a focused action sheet:

- Mark Cleared.
- Mark Bounced.

After clearance, offer Allocate payment. Record every cheque-state change in financial activity.

## 21. Balances and operational profit

### 21.1 Customer balances

List rows show:

- Customer.
- Issued non-void invoice total.
- Cleared incoming allocations.
- Remaining balance.
- Oldest unpaid date where available.

Detail shows invoice and payment activity with a running balance.

### 21.2 Supplier balances

List rows show:

- Supplier.
- Issued non-void settlement total.
- Unpaid expense total.
- Cleared outgoing allocations.
- Remaining balance.

Detail shows settlements, expenses, and payments with a running balance.

### 21.3 Operational profit

Formula:

`Issued customer net revenue - external vehicle payables - linked operating expense net amounts`

Rules:

- Exclude VAT collected.
- Exclude recoverable VAT.
- Do not label the result as accounting profit or formal profit-and-loss.
- Label the metric `Operational profit` everywhere.

Views:

- Period total.
- By customer.
- By vehicle.
- By work order.
- Owned versus external vehicle revenue.

Each breakdown row shows revenue, supplier payable, linked expenses, and operational profit. Use tables and totals, not charts.

## 22. Parties

### 22.1 Party model

One party record supports:

- Customer.
- Supplier.
- Both customer and supplier.

### 22.2 Party form

Fields:

- Role, customer, supplier, or both.
- Legal name.
- Display name.
- Address.
- City.
- Emirate.
- Country.
- TRN or TIN.
- Trade licence.
- Contact person.
- Phone.
- Email.
- Payment terms.
- Active state.
- Notes.

Behavior:

- Use role chips or a segmented control for customer and supplier roles.
- Search for similar legal or display names before save.
- Show related balances only to Money-authorized users.
- Archive rather than delete.
- Keep archived parties visible through a filter and unavailable for new work by default.

### 22.3 Party detail

Sections:

- Identity.
- Contact.
- Payment terms.
- Active agreements.
- Recent work.
- Invoices and customer balance, when a customer.
- Settlements and supplier balance, when a supplier.
- Activity metadata.

## 23. Vehicles

### 23.1 Vehicle form

Fields:

- Plate number.
- Internal label.
- Vehicle class.
- Capacity.
- Make.
- Model.
- Year.
- Source, owned or external.
- Linked supplier for external source.
- Registration expiry.
- Insurance expiry.
- Inspection expiry.
- Active state.
- Notes.

Rules:

- Require a supplier for external vehicles.
- Keep plate number optional for an external temporary vehicle.
- Require plate number or internal label for record identification.
- Hide linked supplier for owned vehicles.
- Archive rather than delete.

### 23.2 Vehicle detail

Sections:

- Vehicle identity.
- Ownership source and supplier.
- Document-expiry dates.
- Recent allocations.
- Linked expenses.
- Revenue and operational profit for Money-authorized users.
- Activity metadata.

Expiry rows must show exact date and state, such as `Expires in 14 days`, `Expired 3 days ago`, or `No date recorded`.

## 24. Drivers

### 24.1 Driver form

Fields:

- Name.
- Phone.
- Licence number.
- Licence expiry.
- Emirates ID or other identity reference.
- Identity expiry.
- Classification, employed or external.
- Linked supplier where relevant.
- Active state.
- Notes.

Rules:

- A driver remains a managed record without login access.
- Show linked supplier for an external driver where relevant.
- Archive rather than delete.
- Keep identity references masked in list views.

### 24.2 Driver detail

Sections:

- Contact and classification.
- Licence and identity expiry.
- Supplier link.
- Recent work.
- Activity metadata.

Do not show invite or app-access actions.

## 25. Agreements

### 25.1 Agreement list

Filters:

- Customer.
- Rate model.
- Active, future, expired, or archived.

Each row shows agreement name, customer, rate model, date range, and status.

### 25.2 Agreement form

Common fields:

- Name.
- Reference.
- Customer.
- Start date.
- End date.
- Rate model, per trip or monthly hire.
- Invoice grouping, per work or monthly consolidated.
- Default VAT rate.
- Driver responsibility, operator or customer.
- Fuel responsibility, operator or customer.
- Maintenance responsibility, operator or customer.
- Default vehicle, optional.
- Customer purchase-order reference, optional.
- Payment terms.
- Notes.

Monthly-hire fields:

- Base monthly rate.
- Duty days per week.
- Included hours per day.
- Overtime rate and unit.
- Extra-day rate.
- Extra-trip rate.
- Default extra charges, repeatable name and amount (for example, parking, toll).

Behavior:

- Reveal monthly fields only for the monthly-hire model.
- Show a readable agreement summary before save.
- Treat rates as defaults for review, not automatic final invoice values.
- Warn before changing an agreement used by existing work.
- State issued invoice snapshots do not change.
- Archive rather than delete.

## 26. Reports

### 26.1 Report catalog

Required reports:

- Monthly operations summary.
- Customer work statement.
- Customer invoice and payment balance.
- Supplier work and payment balance.
- Owned versus external vehicle revenue.
- Vehicle operational profit.
- Customer operational profit.
- Expense summary by category.
- Cashbook of cleared incoming and outgoing payments.
- Unbilled completed work.
- Unpaid invoices.
- Unpaid supplier settlements.
- Expiring vehicle and driver documents.

Group reports into:

- Operations.
- Customers.
- Suppliers.
- Expenses and cash.
- Profit.
- Compliance and expiry.

### 26.2 Shared report pattern

Each report uses:

1. Title and short purpose.
2. Date filter.
3. Relevant party, vehicle, driver, status, or category filters.
4. Summary totals.
5. Sortable or grouped rows where useful.
6. PDF or CSV export action where useful.

### 26.3 Mobile table behavior

- Show the two most important values in each row.
- Put secondary values on a second line or detail screen.
- Keep column headers in PDFs and CSV exports.
- Use horizontal scrolling only when comparison across columns is essential.
- Repeat table headers on each PDF page.
- Keep totals together and avoid split total blocks.

## 27. Staff and access packs

### 27.1 Staff list

Each row shows:

- Name or email.
- Invitation or membership status.
- Access packs.
- Last access time where available and approved.

Owner actions:

- Invite staff.
- Resend invitation where supported.
- Change access packs.
- Deactivate access.

### 27.2 Access-pack selector

Show four checkable packs with rights summaries:

- Operations.
- Master Data.
- Money.
- Reports.

Explain combined access before save. Settings and staff control remain owner-only and are never selectable packs.

### 27.3 Permission enforcement

The interface reflects permission, but the database remains authoritative. Row Level Security and transaction functions enforce tenant membership and access packs for every protected action.

## 28. Business profile and document branding

### 28.1 Business profile fields

- English legal name.
- Arabic legal name, optional.
- Trade licence number.
- Trade licence type.
- TRN or TIN where applicable.
- Address.
- City.
- Emirate.
- Country.
- Phone.
- Email.
- Default currency, fixed to AED for pilot.
- Default VAT rate, 5 percent.

### 28.2 Branding fields

- Logo.
- Header artwork, optional.
- Brand color.
- Footer.
- Payment instructions.
- Invoice prefix.
- Opening sequence.

### 28.3 Branding preview

Show a scaled A4 invoice preview using sample labels and non-sensitive sample values. Update the preview after save or through an explicit Preview action.

Rules:

- One fixed layout only.
- No freeform placement controls.
- Validate logo and artwork file type, dimensions, and size before upload.
- Check readable contrast when the owner selects a brand color.
- Create a new branding version when saved.
- State old issued documents retain their original branding version.

### 28.4 Document sequence

- Set prefix and opening number during onboarding.
- Lock unsafe sequence changes after the first issued invoice.
- Show a formatted example, such as `INV-2026-003268`.
- State issued and void numbers never return to the sequence.
- Never display an uncommitted next number as guaranteed.

## 29. Opening data, exports, and backup status

### 29.1 Opening data

The developer imports:

- Customers.
- Suppliers.
- Vehicles.
- Drivers.
- Active agreements.
- Opening customer balances.
- Opening supplier balances.

The owner-facing status screen shows:

- Agreed go-live date.
- Imported count by record type.
- Import completion state.
- Validation owner.
- Exceptions needing review.

Opening balances must appear as adjustment records. Never present fake invoices or payments.

### 29.2 Owner export

The owner selects a record type and date range where relevant, then requests CSV generation. Show progress, completion, share, and failure states.

### 29.3 Backup status

Show operational status only:

- Last weekly encrypted database export date.
- Verification result.
- Last restore drill date and result.
- Current hosting plan state where useful.

Do not build a database administration interface inside the mobile app.

## 30. Financial calculations and display rules

### 30.1 Stored values

- Use decimal numeric values, never floating-point values.
- Store and show money to two decimal places.
- Use half-up rounding.

### 30.2 Invoice calculations

- Line net = quantity × unit price − discount.
- Line VAT = line net × VAT rate.
- Invoice net = sum of line net values.
- Invoice VAT = sum of line VAT values.
- Invoice total = invoice net + invoice VAT.

### 30.3 Balance calculations

- Customer balance = issued non-void invoice totals − cleared incoming allocations.
- Supplier balance = issued non-void settlements and unpaid expenses − cleared outgoing allocations.

### 30.4 Display format

- Primary format: `AED 11,357.49`.
- Negative example: `−AED 250.00`.
- Zero: `AED 0.00`.
- Align money values by decimal in document tables where practical.
- Use tabular numerals for totals.
- Never abbreviate financial values to `11.3K` in final totals.
- Labels must distinguish Net, VAT, Gross, Paid, and Remaining.

## 31. Record lifecycle and destructive actions

### 31.1 Master data

- Active records are available for new work.
- Archived records remain visible through filters and historical links.
- Use Archive, never Delete.

### 31.2 Work

- Planned.
- Completed.
- Canceled.
- Billed.

Draft work deletion is available only where the backend allows it and no protected links exist.

### 31.3 Financial records

- Draft financial records remain editable.
- Issued records are locked.
- Part Paid and Paid come from cleared allocations.
- Void requires owner permission and a reason.
- Issued and void records never delete.

### 31.4 Confirmation hierarchy

No confirmation needed:

- Search.
- Filter.
- Open record.
- Preview PDF.

Simple confirmation:

- Archive master record.
- Cancel work.
- Mark work completed.

Strong confirmation with consequence text:

- Issue invoice.
- Issue settlement.
- Void invoice.
- Void settlement.
- Mark cheque bounced.
- Deactivate staff access.

## 32. Search, filters, and selectors

### 32.1 Search behavior

- Start search after a short input delay or explicit keyboard search.
- Keep recent results while refining a query.
- Highlight the matching field where useful.
- Show a clear no-results message and Reset filters action.

### 32.2 Filter behavior

- Show active-filter count on the filter action.
- Preserve filters while opening a record and returning.
- Provide Clear all.
- Use sensible screen-specific defaults.
- State the applied date period above results.

### 32.3 Record selectors

Party, vehicle, driver, and agreement selectors should:

- Open as searchable full-height sheets.
- Show identifying secondary text.
- Put active records first.
- Hide archived records by default.
- Offer a permission-aware Add new action where safe.
- Return the user to the original form after adding a record.

## 33. Forms and validation

### 33.1 Form structure

- Put required fields first.
- Mark optional fields with `Optional`.
- Use section headings for long forms.
- Keep labels visible above entered values.
- Use the correct keyboard for phone, email, number, decimal, and date fields.
- Keep one primary action at the bottom.
- Keep destructive actions outside the main form action area.

### 33.2 Validation timing

- Validate formatting after the user leaves a field.
- Validate required fields on submit.
- Validate cross-record business rules on the server.
- Place an error summary above the submit action when several sections fail.
- Focus the first invalid field after submit.

### 33.3 Important validation rules

- Customer must match the agreement.
- Work date should fall within the agreement period or require review.
- External vehicle requires supplier.
- External allocation requires a payable amount before settlement eligibility.
- Quantity and price must produce valid non-negative totals unless the client approves credit behavior.
- VAT rate must be valid for the selected tax category.
- Payment allocations cannot exceed cleared amount or document balance.
- Cheque reference and date are required for cheque method.
- Void reason is required.
- Invoice issue requires valid seller, buyer, lines, tax values, totals, and sequence configuration.

## 34. Loading, empty, error, and success states

Every designed screen needs these applicable variants.

### 34.1 Loading

- Use skeleton rows for lists and dashboard cards.
- Use a progress indicator for single transactions.
- Keep transaction copy specific, such as `Issuing invoice` or `Generating PDF`.

### 34.2 First-use empty

Explain what belongs on the screen and offer one permission-aware primary action.

Examples:

- `No work recorded. Add the first transport job.`
- `No invoices issued. Complete work before preparing billing.`
- `No suppliers added. Add a supplier before assigning an external vehicle.`

### 34.3 Filtered empty

State no records match the current search or filters. Offer Clear filters.

### 34.4 Error

Show:

- What failed.
- Whether any data was saved.
- A safe recovery action.
- A support reference for unexpected transaction failures where available.

Never show raw database, policy, or backend stack messages.

### 34.5 Success

Use brief confirmation for ordinary saves. Use a dedicated result screen for issued invoices, issued settlements, completed exports, and other actions with follow-up tasks.

## 35. Visual design direction

### 35.1 Character

The interface should feel dependable, compact, and financial. It should support daily operational speed without looking like a consumer delivery app or a complex accounting suite.

### 35.2 Color roles

Use semantic roles rather than hard-coded colors in screens.

| Role | Suggested direction | Use |
|---|---|---|
| Primary | Deep blue | Main actions, selected navigation, links |
| Neutral | Slate and white | Surfaces, text, dividers, page background |
| Success | Green | Paid, completed, cleared, positive confirmation |
| Warning | Amber | Due soon, pending cheque, review needed |
| Danger | Red | Expired, bounced, void, destructive confirmation |
| Information | Cyan or blue tint | Offline cache, helper information |

The owner-selected brand color applies to generated documents and limited branded surfaces. It must not replace semantic status colors.

### 35.3 Typography

- Use the platform-compatible Flutter text system with a clean sans-serif family.
- Use at least 16 logical pixels for body text.
- Use 14 logical pixels for supporting labels when contrast remains strong.
- Use 20 to 28 logical pixels for screen and metric headings.
- Use medium or semibold weight for labels and totals.
- Use tabular numerals for money tables where the selected font supports them.
- Keep line height between 1.35 and 1.5 for body text.

### 35.4 Spacing and layout

- Use an 8-point spacing system.
- Use 16-pixel phone page margins.
- Use 12 to 16 pixels between related controls.
- Use 24 to 32 pixels between form sections.
- Keep touch targets at least 48 by 48 logical pixels.
- Use cards only when grouping adds meaning. Prefer simple sections and list rows for dense screens.

### 35.5 Shape and elevation

- Use moderate 8 to 12 pixel corner radii.
- Use borders and background contrast before shadows.
- Reserve elevation for navigation, sheets, menus, and sticky action regions.
- Avoid decorative gradients.

### 35.6 Icons

- Use one consistent platform-neutral icon set already available in Flutter.
- Pair important icons with text labels.
- Use familiar icons for search, filter, add, share, download, more, calendar, vehicle, person, document, and payment.
- Never use an icon alone for financial state or destructive actions.

## 36. Core component inventory

Design and document these reusable components:

- App bar.
- Bottom navigation.
- Offline banner.
- Primary, secondary, text, and destructive buttons.
- Icon button with accessible label.
- Text, email, phone, number, money, date, and multiline fields.
- Searchable selector.
- Segmented control.
- Checkbox and radio row.
- Status badge.
- Metric card.
- Action-item row.
- Record list row.
- Financial total block.
- Charge-line row.
- Vehicle-allocation row.
- Payment-allocation row.
- Filter chip and filter sheet.
- Empty state.
- Inline error.
- Loading skeleton.
- Confirmation sheet.
- Strong confirmation dialog.
- Sticky bottom action area.
- PDF preview toolbar.
- Report summary and mobile table row.
- Activity timeline row.

Each component specification needs default, pressed, focused, disabled, loading, error, selected, and high-text-scale variants where applicable.

## 37. Status language and semantic mapping

| Entity | States | Presentation rule |
|---|---|---|
| Work | Planned, Completed, Canceled, Billed | Badge plus text on every row and detail header |
| Invoice | Draft, Issued, Part Paid, Paid, Void | Badge, remaining amount, and available action |
| Settlement | Draft, Issued, Part Paid, Paid, Void | Same pattern as invoice |
| Cheque | Received, Cleared, Bounced | Badge plus balance effect explanation |
| Master data | Active, Archived | Text label and availability for new selection |
| Invitation | Pending, Accepted, Expired | Staff list badge and recovery action |
| Document expiry | Valid, Due soon, Expired, Unknown | Exact date, relative text, and icon |
| Connectivity | Online, Offline, Reconnecting | Persistent banner when not online |

Use consistent words across screens, PDFs, exports, tests, and support material.

## 38. Accessibility requirements

### 38.1 Visual

- Meet WCAG 2.2 AA contrast for text, icons, controls, and states.
- Do not use color alone to communicate status.
- Support platform text scaling to at least 200 percent without losing content or actions.
- Keep focus and error states visible.
- Avoid text embedded in raster assets, except client-supplied Arabic header artwork in documents.

### 38.2 Motor

- Use touch targets of at least 48 by 48 logical pixels.
- Keep destructive actions separated from primary actions.
- Avoid swipe-only actions.
- Provide visible alternatives for row actions.

### 38.3 Screen reader

- Give every icon action a meaningful label.
- Announce status with the record, such as `Invoice INV-2026-003268, part paid`.
- Group financial label and value pairs.
- Announce form errors and focus the invalid field.
- Provide a useful reading order for totals and line items.
- Mark decorative images as excluded from accessibility traversal.

### 38.4 Cognitive

- Use plain business language.
- Keep one main action per screen.
- Explain irreversible financial actions before confirmation.
- Keep field order consistent across create, edit, detail, PDF, and report experiences.

## 39. Language, dates, and content

### 39.1 Language scope

- English app interface for the pilot.
- Arabic legal name is optional business data.
- Arabic header artwork is optional document branding.
- Full Arabic app localization and right-to-left layout need separate client validation and sizing.

### 39.2 Date and time

- Display dates as `12 Jul 2026` to avoid day and month ambiguity.
- Use platform date pickers.
- Use 24-hour time where time is shown.
- Store and process timestamps consistently with the tenant context.
- Show the UAE operating date clearly on work and financial documents.

### 39.3 Content style

- Use direct labels, such as `Add work`, `Issue invoice`, and `Record payment`.
- Avoid accounting terms outside the defined business vocabulary.
- Use `Customer`, `Supplier`, `Agreement`, `Work order`, `Vehicle allocation`, `Operational profit`, and other blueprint terms consistently.
- Put consequences in confirmation text, not vague labels.
- Avoid labels such as Submit, Process, or Done when a precise action exists.

## 40. Responsive behavior

### 40.1 Phones

- Use one-column forms.
- Stack metric cards in two columns where labels fit, then one column at large text sizes.
- Convert tables into summary rows with detail screens.
- Keep primary form action in a sticky bottom area without covering content.

### 40.2 Large phones and tablets

- Constrain reading width for forms.
- Use two-column detail sections where space supports clear scanning.
- Use a master-detail layout for lists only if Flutter implementation stays simple and behavior remains consistent.
- Do not create tablet-only workflows.

### 40.3 Orientation

- Support portrait across all screens.
- Support wide orientation for PDF preview and dense report review.
- Preserve unsaved form values through orientation changes.

## 41. Security and privacy in the interface

- Require authenticated tenant membership for business data.
- Never expose tenant identifiers, policies, or internal database errors in the interface.
- Hide actions outside the user’s access packs.
- Keep owner-only settings, exports, staff, sequences, and void controls owner-only.
- Mask sensitive identity references in lists.
- Avoid sensitive business values in push notifications. Push notifications are not required for MVP.
- Clear tenant cache after confirmed sign-out or membership removal.
- Record issue, void, allocation, and cheque-state changes in financial activity.
- Show user, action, record, timestamp, and void reason where relevant.
- Keep service-role credentials outside the app.

## 42. Connectivity and transaction design

All writes require internet access and server confirmation.

### 42.1 Ordinary saves

- Disable save while offline.
- Show saving progress.
- Update the local view only after confirmed success.
- Keep entered values if the request fails and retry is safe.

### 42.2 Financial transactions

Issue, void, settlement, and payment-allocation actions must:

- Show a review step.
- Prevent double submission.
- Wait for the authoritative server result.
- Show the final assigned number or updated balance only after success.
- Refresh linked work, balance, and activity data after success.
- Avoid optimistic financial totals.

### 42.3 Cached reads

Cache only:

- Last dashboard totals.
- Customer and supplier list.
- Vehicle and driver list.
- Agreement list.
- Recent work list.

Show last refresh time. Do not imply live values while offline.

## 43. Document design specification

### 43.1 Supported outputs

- Trip Sheet.
- Tax Invoice.
- Monthly Statement.
- Supplier Settlement.
- Customer Balance Statement.
- Supplier Balance Statement.
- Cashbook Report.
- Operational Profit Report.

### 43.2 Fixed A4 template structure

1. Logo and optional header artwork.
2. Seller legal identity and contact details.
3. Document title, number, issue date, and supply date.
4. Buyer or supplier identity.
5. Reference and payment terms.
6. Line-item table.
7. Net, VAT, and gross totals.
8. Payment instructions and footer.
9. Page number.

### 43.3 Invoice table

Support:

- Description.
- Quantity.
- Unit.
- Unit price.
- Discount where used.
- Net.
- VAT rate.
- VAT.
- Gross where space permits.

### 43.4 Multi-page behavior

- Repeat document identity and column headers on later pages.
- Keep totals together.
- Avoid splitting a single short line across pages.
- Show `Page X of Y`.
- Keep customer and invoice reference readable on every page.
- Support the large monthly statement acceptance case of AED 85,635.25.

### 43.5 Issued-document stability

Generate issued PDFs from invoice or settlement snapshots and the saved branding version. Later edits to party, agreement, work, logo, color, or address must not change issued documents.

### 43.6 Compliance boundary

The PDF must contain the required seller, buyer, invoice, line, tax, and total data defined by the validated blueprint. The product must not label PDF output as UAE electronic-invoice exchange. ASP exchange, PINT-AE XML, and FTA reporting are outside MVP.

Current official UAE requirements need legal and tax review before production release.

## 44. Audit and activity presentation

Use one shared activity pattern on protected record details.

Show:

- Action.
- User.
- Date and time.
- Resulting state.
- Reason where required.

Required financial events:

- Invoice issue.
- Invoice void.
- Settlement issue.
- Settlement void.
- Payment allocation.
- Payment allocation change where supported.
- Cheque received, cleared, or bounced state change.

Activity is read-only. Put recent events first. Do not expose internal payloads.

## 45. Design acceptance scenarios

### 45.1 Monthly bus hire

Inputs:

- Base monthly hire: AED 9,500.00.
- Sunday work: AED 316.66.
- Parking: AED 1,000.00.
- Net: AED 10,816.66.
- VAT: AED 540.83.
- Total: AED 11,357.49.

Design acceptance:

- The prepare flow shows each source line.
- The review shows exact net, VAT, and gross totals.
- Issue confirmation explains immutability.
- The result shows a stable number.
- Customer balance updates after issue.
- PDF values match the mobile detail.

### 45.2 Monthly hire with extras

Inputs total AED 17,937.47, including base rate, night shift, extra trips, Sunday work, parking, and VAT.

Design acceptance:

- Users review all extras without opening separate screens.
- The invoice preview fits on one readable PDF page for the supplied case.

### 45.3 Per-trip monthly statement

Expected total: AED 14,926.00.

Design acceptance:

- Each statement row opens or identifies its source work order.
- Mobile summary and PDF totals match.

### 45.4 Large work register

Expected total: AED 85,635.25.

Design acceptance:

- PDF headers repeat.
- Totals do not split across pages.
- Invoice references remain clear.

### 45.5 Ten vehicles

Four owned and six external vehicle allocations.

Design acceptance:

- Users add and review all allocations efficiently.
- Source type remains obvious.
- Supplier payable appears only for external allocations.
- Customer billing includes all work.
- Supplier preparation includes only external allocations.

### 45.6 Pass-through work

Customer net revenue and supplier payable both equal AED 500.00.

Design acceptance:

- Both values remain visible.
- Operational profit shows AED 0.00 before linked expenses.
- The UI does not mislabel zero profit as an error.

### 45.7 Partial cheque

Design acceptance:

- Received state shows no balance reduction.
- Allocation stays unavailable until clearance.
- Cleared state enables allocation.
- Partial allocation changes the invoice to Part Paid.

### 45.8 Permissions and tenant isolation

Design acceptance:

- Operations staff do not see profit navigation or values.
- Unauthorized deep links show Access unavailable.
- Another tenant’s data never appears in results, counts, search, selectors, cache, or error copy.

### 45.9 Issued-document stability

Design acceptance:

- Issued invoice detail has no edit action.
- Customer and branding changes do not alter regenerated PDF values.
- The activity view shows issue history.

## 46. Prototype flows

The clickable prototype should cover these complete paths:

1. Owner sign in to Home, review alerts, and open unbilled work.
2. Operations staff create a per-trip work order with one owned vehicle.
3. Operations staff create a ten-vehicle work order with owned and external allocations.
4. Money staff prepare a monthly-hire invoice with extras and issue it.
5. Money staff generate and share an invoice PDF.
6. Money staff prepare and issue a supplier settlement.
7. Money staff record a received cheque, mark it cleared, and allocate a partial amount.
8. Owner record an expense linked to a vehicle and review operational profit.
9. Owner invite a staff member and assign access packs.
10. Owner update branding and verify an old issued invoice stays unchanged.
11. Staff browse cached records offline and see write controls unavailable.
12. Owner void an issued invoice with a required reason.

## 47. Figma delivery structure

Organize the design file into these pages:

1. Cover and decisions.
2. Foundations.
3. Components.
4. Authentication.
5. Home.
6. Work.
7. Prepare Month.
8. Money and invoices.
9. Settlements and expenses.
10. Payments and balances.
11. Master data.
12. Reports.
13. Settings and staff.
14. Documents.
15. Edge states.
16. Prototype flows.
17. Handoff and acceptance.

Each high-fidelity screen should include:

- Screen ID from this brief.
- User role.
- Record state.
- Connectivity state.
- Key interaction annotations.
- Validation and error variants.
- Component references.

## 48. Handoff requirements

Design handoff should provide:

- Mobile frames at a common Android width and iPhone width.
- Large-text variants for dense and financial screens.
- Component properties and state variants.
- Color, typography, spacing, radius, and elevation tokens.
- Icon mapping.
- Form field rules.
- Status mapping.
- Empty, loading, error, offline, and permission states.
- PDF page designs for every supported document type.
- Prototype links for the required flows.
- Exportable logo and placeholder asset specifications.
- Clear distinction between source requirements and client-approved design assumptions.

## 49. Delivery priorities

### Phase 1. Foundation

- Authentication and invitation.
- App shell and permission-aware navigation.
- Parties.
- Vehicles.
- Drivers.
- Agreements.
- Business profile.
- Opening data status.

### Phase 2. Work and supplier cost

- Work list and detail.
- Work create and edit.
- Vehicle allocations.
- Charge lines.
- Complete, cancel, and duplicate actions.
- External supplier payable review.

### Phase 3. Documents and money

- Prepare Month.
- Invoices and statements.
- Supplier settlements.
- Expenses.
- Payments and allocations.
- PDF preview and native sharing.

### Phase 4. Reports and pilot hardening

- Dashboard totals.
- Balances and operational profit.
- Reports and exports.
- Expiry alerts.
- Offline cached states.
- Backup status.
- Accessibility review.
- Acceptance prototypes and release assets.

## 50. Decisions requiring client validation

Resolve these items before final high-fidelity design or implementation:

1. Confirm the exact expense statuses and when an expense becomes read-only.
2. Confirm whether canceled work needs a mandatory cancellation reason.
3. Confirm whether completed unbilled work remains editable by Operations staff.
4. Confirm whether Money staff receive permission to cancel completed unbilled work.
5. Confirm the exact due-date calculation from payment terms.
6. Confirm whether invoice grouping is changeable during Prepare Month when an agreement has a default.
7. Confirm whether a customer needs separate monthly statements for work and invoices.
8. Confirm the required fields for UAE tax invoices with the client’s tax adviser before production.
9. Confirm whether app-level Arabic localization belongs in the pilot. The current scope supports Arabic business data and artwork only.
10. Confirm the document-expiry warning windows, such as 30, 14, and 7 days.
11. Confirm whether staff invitation resend and last-access time are required.
12. Confirm which exports each Reports user receives and which remain owner-only.
13. Confirm whether supplier payouts should use expenses, settlements, or both in each client workflow to avoid duplicate payable records.
14. Confirm whether external drivers always require a linked supplier.
15. Confirm whether negative charge lines or credit notes are excluded. The current blueprint defines void and reissue, not credit notes.
16. Confirm whether user-entered discounts are amount-based, percentage-based, or both. The blueprint defines a discount value but not its input type.
17. Confirm whether payment allocations are editable or reversed after posting.
18. Confirm whether the owner needs an in-app backup status screen or an operational report outside the app.

## 51. Final MVP design test

The design is ready for implementation when the client completes these tasks in the prototype without explanation:

- Add a customer, supplier, external vehicle, driver, and agreement.
- Record a trip once with owned and external vehicle allocations.
- Complete the work and prepare customer billing.
- Issue a stable invoice with exact AED and VAT totals.
- Generate and share a readable PDF.
- Prepare the related external supplier settlement.
- Record cash, bank, and cheque payments.
- Allocate a cleared partial payment without exceeding the available amount.
- Review customer balance, supplier balance, vehicle cost, and operational profit.
- Find unbilled work, pending cheques, and expiring documents.
- Perform owner-only staff, branding, sequence, export, and void actions.
- Understand what is unavailable offline.
- Complete the month without rebuilding data in Excel.
