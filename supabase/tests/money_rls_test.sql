begin;
select plan(16);

insert into auth.users (id, aud, role, email)
values
  ('33333333-3333-4333-8333-333333333333', 'authenticated', 'authenticated', 'money-staff@fleetgo.local'),
  ('44444444-4444-4444-8444-444444444444', 'authenticated', 'authenticated', 'money-other@fleetgo.local');

insert into public.tenants (id, name)
values ('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Money Other Tenant');

insert into public.tenant_members (
  id, tenant_id, user_id, display_name, email, role, status
) values
  ('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '33333333-3333-4333-8333-333333333333', 'Money Staff', 'money-staff@fleetgo.local', 'staff', 'active'),
  ('ffffffff-ffff-4fff-8fff-ffffffffffff', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', '44444444-4444-4444-8444-444444444444', 'Money Other', 'money-other@fleetgo.local', 'owner', 'active');

insert into public.parties (id, tenant_id, name, type)
values
  ('a1111111-1111-4111-8111-111111111111', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Money Customer', 'customer'),
  ('a2222222-2222-4222-8222-222222222222', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'Money Supplier', 'supplier'),
  ('b1111111-1111-4111-8111-111111111111', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'Other Customer', 'customer');

insert into public.agreements (id, tenant_id, reference, name, customer_id, rate_model)
values ('a3333333-3333-4333-8333-333333333333', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'MONEY-AGR', 'Money Agreement', 'a1111111-1111-4111-8111-111111111111', 'per_trip');

insert into public.vehicles (id, tenant_id, plate_number, label, vehicle_class, ownership)
values ('a4444444-4444-4444-8444-444444444444', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'MONEY-001', 'Money Vehicle', 'three_ton', 'owned');

insert into public.work_orders (
  id, tenant_id, number, customer_id, agreement_id, date, work_type, status, pickup, destination
) values
  ('a5555555-5555-4555-8555-555555555555', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'MONEY-WO-1', 'a1111111-1111-4111-8111-111111111111', 'a3333333-3333-4333-8333-333333333333', '2026-07-17', 'per_trip', 'completed', 'A', 'B'),
  ('a6666666-6666-4666-8666-666666666666', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'MONEY-WO-2', 'a1111111-1111-4111-8111-111111111111', 'a3333333-3333-4333-8333-333333333333', '2026-07-18', 'per_trip', 'planned', 'C', 'D'),
  ('a7777777-7777-4777-8777-777777777777', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'MONEY-WO-3', 'a1111111-1111-4111-8111-111111111111', 'a3333333-3333-4333-8333-333333333333', '2026-07-19', 'per_trip', 'completed', 'E', 'F');

insert into public.work_order_charge_lines (tenant_id, work_order_id, name, unit_price)
values
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a5555555-5555-4555-8555-555555555555', 'Trip', 100),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a6666666-6666-4666-8666-666666666666', 'Trip', 100),
  ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', 'a7777777-7777-4777-8777-777777777777', 'Trip', 100);

insert into public.invoices (
  id, tenant_id, number, buyer_id, buyer_name, payment_terms, issue_date,
  net, vat, gross, status
) values ('b2222222-2222-4222-8222-222222222222', 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb', 'OTHER-INV', 'b1111111-1111-4111-8111-111111111111', 'Other Customer', 'On receipt', '2026-07-17', 100, 5, 105, 'issued');

create temp table money_test_ids (kind text primary key, id uuid);
grant all on money_test_ids to authenticated;

select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);
set local role authenticated;

select has_table('public', 'invoices', 'invoices exists');
select has_table('public', 'payments', 'payments exists');
select has_function('public', 'issue_invoice', array['jsonb']);
select results_eq($$select count(*) from public.invoices$$, $$values (0::bigint)$$, 'Tenant isolation hides the other tenant invoice');

select set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
select throws_ok(
  $$insert into public.expenses (tenant_id, date, category, payee, net)
    values ('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa', '2026-07-17', 'fuel', 'Station', 10)$$,
  '42501', null, 'Staff without the money pack cannot insert an expense'
);
select set_config('request.jwt.claim.sub', '11111111-1111-4111-8111-111111111111', true);

insert into money_test_ids (kind, id)
select 'issued', public.issue_invoice(jsonb_build_object(
  'buyer_id', 'a1111111-1111-4111-8111-111111111111',
  'buyer_name', 'Money Customer', 'payment_terms', 'On receipt',
  'issue_date', '2026-07-17',
  'work_order_ids', jsonb_build_array('a5555555-5555-4555-8555-555555555555'),
  'lines', jsonb_build_array(jsonb_build_object('name', 'Trip', 'quantity', 1, 'unit_price', 100, 'vat_rate', 5))
));

select matches((select number from public.invoices where id = (select id from money_test_ids where kind = 'issued')), '^INV-\d{4}-001$', 'Issue assigns the next invoice number');
select results_eq($$select status from public.work_orders where id = 'a5555555-5555-4555-8555-555555555555'$$, $$values ('billed'::text)$$, 'Issue bills only completed work');

select throws_ok(
  $$update public.invoices set buyer_name = 'Changed' where id = (select id from money_test_ids where kind = 'issued')$$,
  '42501', null, 'Clients cannot update invoices directly'
);

select throws_ok(
  $$select public.issue_invoice(jsonb_build_object(
      'buyer_id', 'a1111111-1111-4111-8111-111111111111', 'buyer_name', 'Money Customer',
      'issue_date', '2026-07-17', 'work_order_ids', jsonb_build_array('a6666666-6666-4666-8666-666666666666'),
      'lines', jsonb_build_array(jsonb_build_object('name', 'Trip', 'unit_price', 100))
    ))$$,
  'P0001', null, 'Planned work cannot be issued'
);

select throws_ok(
  $$select public.record_payment_allocation(jsonb_build_object(
      'direction', 'incoming', 'party_id', 'a1111111-1111-4111-8111-111111111111',
      'method', 'cash', 'amount', 1, 'date', '2026-07-17',
      'allocations', jsonb_build_array(jsonb_build_object('document_type', 'invoice', 'document_id', (select id from money_test_ids where kind = 'issued'), 'amount', 2))
    ))$$,
  '22023', null, 'Allocation sum above payment amount is rejected'
);

insert into money_test_ids (kind, id)
select 'cheque', public.record_payment_allocation(jsonb_build_object(
  'direction', 'incoming', 'party_id', 'a1111111-1111-4111-8111-111111111111',
  'method', 'cheque', 'amount', 105, 'date', '2026-07-17',
  'allocations', jsonb_build_array(jsonb_build_object('document_type', 'invoice', 'document_id', (select id from money_test_ids where kind = 'issued'), 'amount', 105))
));

select results_eq($$select status from public.invoices where id = (select id from money_test_ids where kind = 'issued')$$, $$values ('issued'::text)$$, 'Received cheque does not reduce the invoice');
select public.transition_cheque_state((select id from money_test_ids where kind = 'cheque'), 'cleared');
select results_eq($$select status from public.invoices where id = (select id from money_test_ids where kind = 'issued')$$, $$values ('paid'::text)$$, 'Cleared cheque marks the invoice paid');
select throws_ok($$select public.transition_cheque_state((select id from money_test_ids where kind = 'cheque'), 'bounced')$$, 'P0001', null, 'Cleared cheques cannot bounce');

insert into money_test_ids (kind, id)
select 'voided', public.issue_invoice(jsonb_build_object(
  'buyer_id', 'a1111111-1111-4111-8111-111111111111', 'buyer_name', 'Money Customer',
  'issue_date', '2026-07-17', 'lines', jsonb_build_array(jsonb_build_object('name', 'Trip', 'unit_price', 100))
));
select public.void_invoice((select id from money_test_ids where kind = 'voided'), 'Correction');
insert into money_test_ids (kind, id)
select 'next', public.issue_invoice(jsonb_build_object(
  'buyer_id', 'a1111111-1111-4111-8111-111111111111', 'buyer_name', 'Money Customer',
  'issue_date', '2026-07-17', 'lines', jsonb_build_array(jsonb_build_object('name', 'Trip', 'unit_price', 100))
));
select matches((select number from public.invoices where id = (select id from money_test_ids where kind = 'next')), '^INV-\d{4}-003$', 'Voided numbers are not reused');

select results_eq($$select balance from public.invoice_balances where invoice_id = (select id from money_test_ids where kind = 'next')$$, $$values (105::numeric)$$, 'Invoice balance is gross minus cleared allocations');

select set_config('request.jwt.claim.sub', '33333333-3333-4333-8333-333333333333', true);
select throws_ok($$select public.void_invoice((select id from money_test_ids where kind = 'next'), 'Staff void')$$, '42501', null, 'Non-owners cannot void invoices');

select * from finish();
rollback;
