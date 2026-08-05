# Research Sources

These files record the first product discussion and real client examples. The final blueprint uses them as evidence. The original bytes remain unchanged.

Treat this folder as internal material. Several files contain real business names, phone numbers, tax numbers, vehicle numbers, and transaction details.

## Concept documents

| File | Purpose | SHA-256 |
|---|---|---|
| [Transport_Fleet_SaaS_Concept_Document.docx](Transport_Fleet_SaaS_Concept_Document.docx) | First broad concept. Includes UAE and KSA, thirteen modules, GPS, payroll, accounting, and platform administration. The MVP blueprint rejects most of this scope. | `0428f3f44010b3566a546f512d6bb7a111d687c0c253a0ccf5d975af39f4f5a7` |
| [transport-fleet-saas.md](transport-fleet-saas.md) | Second concept. Narrows the product but still includes driver GPS, expiry alerts, WhatsApp API work, and future-market structure. | `658fcb2442c19cbc739bf0279630936024b955f2edd12be5772f9b96f3477772` |

## Client workflow evidence

| File | Business evidence | SHA-256 |
|---|---|---|
| [Vehical_invoice_own_car_to_company_3.jpeg](Vehical_invoice_own_car_to_company_3.jpeg) | Fixed monthly vehicle hire invoice with one monthly rate. | `9f05bf370212ec11c505eb404b478be4911ae66bf530de2639ae1b58dcaaa0bc` |
| [Bus_invoice_own_car_to_company_1.jpeg](Bus_invoice_own_car_to_company_1.jpeg) | Monthly bus hire with Sunday work, parking, VAT, signatures, and letterhead. | `dda10d27f7a14c2a5bce03cbb7f13cc0fb9d25c2eb5bdecbfa910a8642590475` |
| [Bus_invoice_own_car_to_company_2.jpeg](Bus_invoice_own_car_to_company_2.jpeg) | Monthly bus hire with night shift, extra trips, Sundays, parking, and VAT. | `1ccf41edba81a4a727cba06cdf7bdb2ed6b325feab287b3f84e003f21d5a4534` |
| [Own_records.jpeg](Own_records.jpeg) | Excel work register with date, company, customer, place, invoice number, vehicle requirement, amount, VAT, toll, total, and drivers. | `a11f13d20133ee671d1f02882f4af71950a88d333667a8c71ae0e40b363fd7e4` |
| [01.pdf](01.pdf) | Two-page monthly customer statement. It groups many dated jobs and individual invoice numbers into AED 85,635.25. | `7058c38c4bdcbd01505208b451bc8776ffac94ff4010e449ddae658589bc308a` |
| [0111.pdf](0111.pdf) | Two-page trip register with route, rate, unloading, gate pass, sales work, purchase work, and AED 14,926 total. | `9ae160ba8d49b890fc0bfb911c58d1dcc24398665cd221f161d2f99122555e9a` |

## Findings used by the blueprint

- The client uses fixed monthly hire and per-trip billing.
- Monthly contracts include extra days, overtime, extra trips, parking, and night shifts.
- Per-trip work includes vehicle class, route, driver, VAT, toll, unloading, and gate-pass charges.
- One customer request often needs owned and outside vehicles together.
- The client receives customer money, then pays drivers, outside vehicle owners, fuel, maintenance, and other expenses.
- Customer balances, supplier balances, and operational profit need one shared source of truth.
- Generated documents need business letterhead, VAT details, sequential numbers, multi-page tables, and native sharing.

