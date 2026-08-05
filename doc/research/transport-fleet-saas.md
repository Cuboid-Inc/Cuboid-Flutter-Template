# Transport & Fleet SaaS — Build Plan

**Type:** Product concept (v2, trimmed)
**Market:** UAE first, KSA next (not both at once — see below)
**Status:** Draft for discussion

---

## The reframe

The original plan treats this as a known product to be built in full: 13 modules, two countries, full HR/payroll and accounting, a GPS-vendor adapter framework — all in "v1."

But you don't have a proven product yet. You have a strong *hypothesis*: several of your clients run the same owned/rented/subcontracted fleet business and all hit the same wall (Excel + WhatsApp invoices + no margin visibility). That repetition is a good signal — it's not yet proof that they'll pay for a product.

So v1's job is **not** to build the platform. It's to validate the hypothesis with **one pilot client**, end to end, as cheaply as possible. Everything below is organised around that.

---

## The wedge

Generic fleet software already exists. The reason none of it fits is one specific thing: your clients run a **mixed fleet** — some vehicles owned, some rented-in, some subcontracted on commission — and they make their money on the **margin** between what they pay and what they bill. No off-the-shelf tool models that cleanly.

That's the wedge. Build the thing nobody else does well — *track sourcing type per job and calculate margin automatically* — and wrap just enough around it to be sellable. Don't lead with GPS or payroll; those are commodities you can add later.

---

## What v1 actually is

Five things. This is the smallest version a pilot client would pay for:

1. **Fleet registry** — one list of every vehicle, tagged owned / rented-in / subcontracted, with document-expiry alerts (Mulkiya, insurance, inspection).
2. **Drivers** — basic profiles, company-employed vs. client-managed flag, license/visa/ID expiry alerts.
3. **Jobs & dispatch** — assign a vehicle + driver to a job; the job knows its sourcing type.
4. **Commission & margin** — automatic margin per job (billed rate − rent/subcontractor cost), and a running statement of what's owed to each subcontracted vehicle owner. *This is the wedge — it's the one module that has to be excellent.*
5. **Invoicing** — replace letterhead-and-WhatsApp with generated invoices (VAT, tenant letterhead, delivered over WhatsApp), built on an e-invoice-ready data model (see below).

Plus a thin **driver mobile flow** — check in/out with odometer, log overtime, phone-GPS ping during a trip. No hardware integration.

That's it. A fleet owner can see his vehicles, dispatch jobs, know his margin, and bill clients with compliant-ready invoices. That's a real product.

## What's explicitly deferred (and why)

| Deferred | Why it waits |
|---|---|
| **GPS/telematics adapter framework** | Premature abstraction. Every client uses a different tracker; building an adapter layer before anyone's paying is speculative. Phone-GPS covers trip tracking in v1. Build a hardware adapter the day a paying client demands their specific tracker. |
| **HR & payroll + WPS/Mudad export** | Big, regulatory-heavy, and most operators already run payroll somewhere. High effort, not the wedge. |
| **Full accounting module** | Invoicing + margin reporting already answers the owner's real question ("am I making money per vehicle and per contract"). A full ledger can come later. |
| **Self-serve multi-tenant admin + subscription billing** | You don't need self-serve onboarding for your first 2–3 clients — onboard them by hand. Build the SaaS plumbing *after* you've proven people pay, not before. |
| **End-customer self-service portal** | Nice someday; irrelevant to validation. |

Naming 13 modules up front made the scope look complete; it mostly made it look big. The five above earn money. The rest get added when a paying client asks and pays for them.

---

## Two calls I'd make differently from the current plan

**1. One market for the pilot, not two.**
"UAE + KSA from launch" doubles your hardest surface — *compliance* — before the product is proven. KSA's ZATCA isn't a future deadline; it's mandatory now and requires real-time invoice clearance through ZATCA. That's a serious integration project on its own.

UAE is the easier on-ramp: structured e-invoicing is still *voluntary* through 2026 and only phases in for SMEs by mid-2027. So in the UAE you can ship a PDF invoice today that's *built on* a structured, compliant-ready data model — fully legitimate now, and a short hop to full compliance later.

**Recommendation:** keep the data model country-aware from day one (that part of the original plan is right), but *operate* in UAE only for the pilot. Onboard your first KSA tenant once the product is proven and you've scoped the ZATCA clearance integration as its own piece of work — not as a line item buried in v1.

**2. Pick the boring, fast stack: .NET 8, not Rust.**
The hard part of this product is invoicing and compliance XML, and time-to-market matters because of the e-invoicing timelines. .NET 8 wins on both: mature PDF and XML/Peppol tooling, and a far larger hiring pool. "Reuse my Rust catalog backend" is a sunk-cost-shaped reason — a real benefit, but not enough to outweigh slower invoicing work and a thin talent pool. **Lean .NET 8, ship faster.** (Mobile stays Flutter — that call in the original is fine.)

---

## The one piece of future-proofing worth doing now

Design the **invoice data model** from day one to carry every field a structured e-invoice needs — TRN/VAT numbers, line-item detail, buyer/seller identifiers, country-specific tax treatment — even while the actual output is still a PDF over WhatsApp.

This is the rare case where building for the future pays off, because rewriting an invoice schema *after* you have live data is genuinely painful. Everything else, build for today. This one thing, build for tomorrow.

---

## Architecture (deliberately plain)

- **Mobile app** (Flutter, iOS + Android) — primary client for owners, dispatchers, drivers.
- **Backend API** — .NET 8.
- **PostgreSQL**, one shared schema with `tenant_id` row isolation, RBAC-enforced, audit-logged. (Separate databases per client cost more and buy you nothing at this size.)
- **Web dashboard** — later, once the mobile core is proven.
- **WhatsApp Business API** for invoice delivery — *start the approval process early*, it has a lead time.

No adapter framework, no microservices, no Kubernetes. One service, one database, one mobile app. Add structure when scale forces it, not before.

---

## Roadmap

**Pilot MVP — roughly 6–8 weeks.** Fleet registry, drivers, jobs/dispatch, commission/margin, invoicing (e-invoice-ready schema, PDF + WhatsApp output), driver mobile flow with phone-GPS. UAE only. One pilot client, onboarded by hand.

**Then: expand by demand.** Once the pilot proves people will pay, add the deferred modules *in the order clients actually ask and pay for them* — likely GPS hardware integration or HR/payroll next, depending on the pilot. Build the self-serve SaaS layer (tenant onboarding, subscriptions) once you're signing client #4 or #5 and manual onboarding starts to hurt.

The original's 4 waves × 3–4 weeks assumed all 13 modules ship as "v1." Cutting to the wedge makes the first sellable version land in roughly half that — which means you learn whether this is real *months* sooner.

---

## Pricing (a starting point, to test — not lock)

- **Starter** — small fleet, core ops (fleet, jobs, invoicing).
- **Growth** — adds commission tracking, GPS integration, more vehicles.
- **Enterprise** — adds e-invoicing/ASP integration, multi-branch, dedicated support.

Flat-per-tenant, per-vehicle, or hybrid — don't decide yet. Test it against your first 2–3 clients before committing.

---

## Decisions that actually matter

1. **Pilot market** — confirm UAE-first for validation (recommended), or accept the extra cost and timeline of KSA/ZATCA from day one.
2. **Stack** — confirm .NET 8 (recommended), or Rust if extending your existing backend matters more than speed.
3. **Pilot client** — pick one client from your roster to validate end to end. This choice shapes which deferred module comes first.
4. **GPS audit** — list which trackers your clients actually use, so the *eventual* integration list is grounded in reality (informs later scope, not v1).
5. **WhatsApp Business API** — start approval now, regardless of the above, because of the lead time.
