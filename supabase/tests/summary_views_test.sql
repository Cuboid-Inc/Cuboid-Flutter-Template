begin;
select plan(13);

insert into auth.users (id, aud, role, email)
values
  ('c1111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'summary-owner@fleetgo.local'),
  ('d1111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'summary-other@fleetgo.local'),
  ('e1111111-1111-4111-8111-111111111111', 'authenticated', 'authenticated', 'summary-invited@fleetgo.local');

insert into public.tenants (id, name)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Summary Tenant'),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Summary Other Tenant');

insert into public.tenant_members (id, tenant_id, user_id, display_name, email, role, status)
values
  ('a1011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'c1111111-1111-4111-8111-111111111111', 'Summary Owner', 'summary-owner@fleetgo.local', 'owner', 'active'),
  ('b1011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'd1111111-1111-4111-8111-111111111111', 'Summary Other', 'summary-other@fleetgo.local', 'owner', 'active'),
  ('a1021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'e1111111-1111-4111-8111-111111111111', 'Summary Invited', 'summary-invited@fleetgo.local', 'staff', 'invited');

insert into public.parties (id, tenant_id, name, type)
values
  ('a2011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Summary Customer', 'customer'),
  ('a2021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Summary Supplier', 'supplier'),
  ('b2011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Customer', 'customer'),
  ('b2021111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Supplier', 'supplier');

insert into public.agreements (id, tenant_id, reference, name, customer_id, rate_model)
values
  ('a3011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUMMARY-AGR', 'Summary Agreement', 'a2011111-1111-4111-8111-111111111111', 'per_trip'),
  ('b3011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTHER-AGR', 'Other Agreement', 'b2011111-1111-4111-8111-111111111111', 'per_trip');

insert into public.vehicles (
  id, tenant_id, plate_number, label, vehicle_class, ownership, supplier_id
)
values
  ('a4011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-1', 'Summary 1', 'three_ton', 'owned', null),
  ('a4021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-2', 'Summary 2', 'three_ton', 'owned', null),
  ('a4031111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-3', 'Summary 3', 'three_ton', 'owned', null),
  ('a4041111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-4', 'Summary 4', 'three_ton', 'external', 'a2021111-1111-4111-8111-111111111111'),
  ('b4011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTH-1', 'Other 1', 'three_ton', 'owned', null);

insert into public.drivers (id, tenant_id, name)
values
  ('a5011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Summary Driver'),
  ('b5011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Driver');

insert into public.route_rates (id, tenant_id, applies_to, pickup, destination, vehicle_class, rate)
values
  ('a6011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Summary', 'A', 'B', 'three_ton', 100),
  ('b6011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other', 'A', 'B', 'three_ton', 999);

insert into public.work_orders (id, tenant_id, number, customer_id, agreement_id, date, work_type, status, pickup, destination)
values
  ('a7011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-WO-1', 'a2011111-1111-4111-8111-111111111111', 'a3011111-1111-4111-8111-111111111111', '2026-07-17', 'per_trip', 'planned', 'A', 'B'),
  ('a7021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-WO-2', 'a2011111-1111-4111-8111-111111111111', 'a3011111-1111-4111-8111-111111111111', '2026-07-17', 'per_trip', 'planned', 'A', 'B'),
  ('a7031111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-WO-3', 'a2011111-1111-4111-8111-111111111111', 'a3011111-1111-4111-8111-111111111111', '2026-07-17', 'per_trip', 'planned', 'A', 'B'),
  ('b7011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTH-WO-1', 'b2011111-1111-4111-8111-111111111111', 'b3011111-1111-4111-8111-111111111111', '2026-07-17', 'per_trip', 'planned', 'A', 'B');

insert into public.work_order_charge_lines (tenant_id, work_order_id, name, unit_price)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7011111-1111-4111-8111-111111111111', 'Trip', 100),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7021111-1111-4111-8111-111111111111', 'Trip', 40),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7031111-1111-4111-8111-111111111111', 'Trip', 60),
  ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'b7011111-1111-4111-8111-111111111111', 'Trip', 999);

insert into public.work_order_allocations (id, tenant_id, work_order_id, vehicle_id, source, supplier_payable)
values
  ('a8011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7011111-1111-4111-8111-111111111111', 'a4011111-1111-4111-8111-111111111111', 'supplier', 10),
  ('a8021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7011111-1111-4111-8111-111111111111', 'a4021111-1111-4111-8111-111111111111', 'owned', 20),
  ('a8031111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7011111-1111-4111-8111-111111111111', 'a4031111-1111-4111-8111-111111111111', 'owned', 30),
  ('a8041111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7021111-1111-4111-8111-111111111111', 'a4041111-1111-4111-8111-111111111111', 'owned', 0),
  ('b8011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'b7011111-1111-4111-8111-111111111111', 'b4011111-1111-4111-8111-111111111111', 'supplier', 999);

insert into public.invoices (id, tenant_id, number, buyer_id, buyer_name, payment_terms, issue_date, net, vat, gross, status)
values
  ('a9011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-INV-1', 'a2011111-1111-4111-8111-111111111111', 'Summary Customer', 'On receipt', '2026-07-17', 100, 5, 105, 'issued'),
  ('a9021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-INV-VOID', 'a2011111-1111-4111-8111-111111111111', 'Summary Customer', 'On receipt', '2026-07-17', 10, 0.5, 10.5, 'voided'),
  ('b9011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTH-INV-1', 'b2011111-1111-4111-8111-111111111111', 'Other Customer', 'On receipt', '2026-07-17', 999, 0, 999, 'issued');

insert into public.settlements (id, tenant_id, number, supplier_id, period_start, period_end, total, status)
values
  ('aa011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'SUM-SET-1', 'a2021111-1111-4111-8111-111111111111', '2026-07-01', '2026-07-17', 30, 'issued'),
  ('bb011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTH-SET-1', 'b2021111-1111-4111-8111-111111111111', '2026-07-01', '2026-07-17', 999, 'issued');

insert into public.expenses (id, tenant_id, date, category, payee, net, vehicle_id)
values
  ('ab011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-17', 'fuel', 'Summary Fuel', 20, 'a4011111-1111-4111-8111-111111111111'),
  ('bc011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '2026-07-17', 'fuel', 'Other Fuel', 999, 'b4011111-1111-4111-8111-111111111111');

insert into public.payments (id, tenant_id, direction, party_id, method, amount, date, cheque_state)
values
  ('ac011111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'incoming', 'a2011111-1111-4111-8111-111111111111', 'cash', 50, '2026-07-17', null),
  ('ac021111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'incoming', 'a2011111-1111-4111-8111-111111111111', 'cheque', 25, '2026-07-17', 'received'),
  ('ac031111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'outgoing', 'a2021111-1111-4111-8111-111111111111', 'cash', 20, '2026-07-17', null),
  ('bd011111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'incoming', 'b2011111-1111-4111-8111-111111111111', 'cash', 999, '2026-07-17', null);

insert into public.payment_allocations (tenant_id, payment_id, document_type, document_id, amount)
values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'ac031111-1111-4111-8111-111111111111', 'expense', 'ab011111-1111-4111-8111-111111111111', 20);

select set_config('request.jwt.claim.sub', 'c1111111-1111-4111-8111-111111111111', true);
set local role authenticated;

select has_view('public', 'work_order_totals', 'work order totals view exists');

select results_eq(
  $$select * from public.home_totals('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (105::numeric, 100::numeric, 50::numeric, 50::numeric, 20::numeric, 30::numeric, 50::numeric, 105::numeric, 30::numeric, 1::integer, 1::integer, 0::integer, 1::integer)$$,
  'home totals separate invoicing, profit, cash movement, and open balances'
);
select results_eq(
  $$select billed from public.home_totals('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (105::numeric)$$,
  'home totals exclude the other tenant invoice'
);

select results_eq(
  $$select * from public.period_ownership_split('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (100::numeric, 100::numeric)$$,
  'ownership counts zero-allocation work as owned'
);
select results_eq(
  $$select external from public.period_ownership_split('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (100::numeric)$$,
  'ownership excludes the other tenant work order'
);

select results_eq(
  $$select vehicle_id::text, revenue, payable, expense from public.vehicle_profit('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31') order by vehicle_id$$,
  $$values
    ('a4011111-1111-4111-8111-111111111111'::text, 33.34::numeric, 10::numeric, 20::numeric),
    ('a4021111-1111-4111-8111-111111111111'::text, 33.33::numeric, 20::numeric, 0::numeric),
    ('a4031111-1111-4111-8111-111111111111'::text, 33.33::numeric, 30::numeric, 0::numeric),
    ('a4041111-1111-4111-8111-111111111111'::text, 40::numeric, 0::numeric, 0::numeric)$$,
  'vehicle profit gives the 0.01 remainder to the lowest allocation id'
);
select results_eq(
  $$select count(*) from public.vehicle_profit('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (4::bigint)$$,
  'vehicle profit excludes the other tenant vehicle'
);

select results_eq(
  $$select * from public.expense_summary('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values ('fuel'::text, 20::numeric)$$,
  'expense summary groups exact category totals'
);
select results_eq(
  $$select total from public.expense_summary('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31') where category = 'fuel'$$,
  $$values (20::numeric)$$,
  'expense summary excludes the other tenant expense'
);

select results_eq(
  $$select * from public.cashbook_totals('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (50::numeric, 20::numeric)$$,
  'cashbook excludes received cheques'
);
select results_eq(
  $$select in_amount from public.cashbook_totals('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-01', '2026-07-31')$$,
  $$values (50::numeric)$$,
  'cashbook excludes the other tenant payment'
);

select results_eq(
  $$select * from public.more_menu_counts('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')$$,
  $$values (1::integer, 1::integer, 4::integer, 1::integer, 1::integer, 1::integer, 1::integer, 2::integer)$$,
  'more menu counts split customer, supplier, vehicle, and invited staff records'
);
select results_eq(
  $$select vehicles_active from public.more_menu_counts('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')$$,
  $$values (4::integer)$$,
  'more menu counts exclude the other tenant records'
);

select * from finish();
rollback;
