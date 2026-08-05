create table public.expenses (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  date date not null,
  category text not null check (category in (
    'driver_pay', 'fuel', 'maintenance', 'toll', 'parking', 'gate_pass',
    'vehicle_rent', 'other'
  )),
  payee text not null check (length(trim(payee)) between 1 and 160),
  net numeric(14,2) not null check (net >= 0),
  vat numeric(14,2) not null default 0 check (vat >= 0),
  vehicle_id uuid,
  driver_id uuid,
  work_order_id uuid,
  description text,
  due_date date,
  reference text,
  notes text,
  receipt_ref text,
  is_paid boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  foreign key (tenant_id, vehicle_id)
    references public.vehicles (tenant_id, id) on delete set null (vehicle_id),
  foreign key (tenant_id, driver_id)
    references public.drivers (tenant_id, id) on delete set null (driver_id),
  foreign key (tenant_id, work_order_id)
    references public.work_orders (tenant_id, id) on delete set null (work_order_id)
);

create index expenses_tenant_date_idx on public.expenses (tenant_id, date desc);

create table public.invoices (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  number text not null,
  buyer_id uuid not null,
  buyer_name text not null,
  buyer_address text,
  buyer_trn text,
  buyer_contact text,
  payment_terms text not null,
  issue_date date not null,
  due_date date,
  supply_date date,
  net numeric(14,2) not null check (net >= 0),
  vat numeric(14,2) not null check (vat >= 0),
  gross numeric(14,2) not null check (gross >= 0),
  status text not null check (status in ('issued', 'part_paid', 'paid', 'voided')),
  void_reason text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (tenant_id, number),
  unique (tenant_id, id),
  foreign key (tenant_id, buyer_id)
    references public.parties (tenant_id, id) on delete restrict
);

create index invoices_tenant_issue_date_idx on public.invoices (tenant_id, issue_date desc);

create table public.invoice_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  invoice_id uuid not null,
  name text not null,
  description text,
  quantity numeric(10,2) not null check (quantity > 0),
  unit_price numeric(14,2) not null check (unit_price >= 0),
  unit text not null,
  discount numeric(14,2) not null default 0 check (discount >= 0),
  vat_rate numeric(5,2) not null default 5 check (vat_rate >= 0),
  net_override numeric(14,2) check (net_override >= 0),
  vat_override numeric(14,2) check (vat_override >= 0),
  net numeric(14,2) not null check (net >= 0),
  vat numeric(14,2) not null check (vat >= 0),
  gross numeric(14,2) not null check (gross >= 0),
  created_at timestamptz not null default now(),
  foreign key (tenant_id, invoice_id)
    references public.invoices (tenant_id, id) on delete cascade
);

create index invoice_lines_invoice_id_idx on public.invoice_lines (invoice_id);

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  number text not null,
  supplier_id uuid not null,
  period_start date not null,
  period_end date not null,
  total numeric(14,2) not null check (total >= 0),
  status text not null check (status in ('issued', 'part_paid', 'paid', 'voided')),
  void_reason text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  unique (tenant_id, number),
  unique (tenant_id, id),
  check (period_end >= period_start),
  foreign key (tenant_id, supplier_id)
    references public.parties (tenant_id, id) on delete restrict
);

create index settlements_tenant_period_end_idx on public.settlements (tenant_id, period_end desc);

create table public.settlement_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  settlement_id uuid not null,
  work_order_id uuid not null,
  date date not null,
  amount numeric(14,2) not null check (amount >= 0),
  customer_name text,
  vehicle_id uuid,
  driver_id uuid,
  route text,
  created_at timestamptz not null default now(),
  foreign key (tenant_id, settlement_id)
    references public.settlements (tenant_id, id) on delete cascade,
  foreign key (tenant_id, work_order_id)
    references public.work_orders (tenant_id, id) on delete restrict,
  foreign key (tenant_id, vehicle_id)
    references public.vehicles (tenant_id, id) on delete set null (vehicle_id),
  foreign key (tenant_id, driver_id)
    references public.drivers (tenant_id, id) on delete set null (driver_id)
);

create index settlement_lines_settlement_id_idx on public.settlement_lines (settlement_id);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  direction text not null check (direction in ('incoming', 'outgoing')),
  party_id uuid,
  method text not null check (method in ('cash', 'bank_transfer', 'cheque')),
  amount numeric(14,2) not null check (amount > 0),
  date date not null,
  reference text,
  cheque_date date,
  cheque_state text check (cheque_state in ('received', 'cleared', 'bounced')),
  notes text,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  check (
    (method = 'cheque' and cheque_state is not null)
    or (method <> 'cheque' and cheque_state is null)
  ),
  unique (tenant_id, id),
  foreign key (tenant_id, party_id)
    references public.parties (tenant_id, id) on delete restrict
);

create index payments_tenant_date_idx on public.payments (tenant_id, date desc);

create table public.payment_allocations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  payment_id uuid not null,
  -- document_id is polymorphic (invoice/settlement/expense) so it cannot carry a
  -- foreign key; record_payment_allocation validates tenant and document instead.
  document_type text not null check (document_type in ('invoice', 'settlement', 'expense')),
  document_id uuid not null,
  amount numeric(14,2) not null check (amount > 0),
  created_at timestamptz not null default now(),
  foreign key (tenant_id, payment_id)
    references public.payments (tenant_id, id) on delete cascade
);

create index payment_allocations_document_idx
  on public.payment_allocations (tenant_id, document_type, document_id);

-- work_orders ↔ invoices is circular, so this one constraint must be added
-- after both tables exist; it is part of the initial schema, not a patch.
alter table public.work_orders
  add constraint work_orders_invoice_id_fkey
  foreign key (tenant_id, invoice_id) references public.invoices(tenant_id, id);

create or replace function private.money_ensure_access(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null
     or not private.has_access_pack(p_tenant_id, 'money') then
    raise exception 'Money access required.' using errcode = '42501';
  end if;
end;
$$;

create or replace function private.money_ensure_owner(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null
     or not private.is_tenant_owner(p_tenant_id) then
    raise exception 'Tenant owner access required.' using errcode = '42501';
  end if;
end;
$$;

create or replace function private.money_immutable_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  parent_status text;
  expected_status text;
begin
  if tg_op = 'DELETE' then
    if tg_table_name = 'invoices' then parent_status := old.status;
    elsif tg_table_name = 'settlements' then parent_status := old.status;
    elsif tg_table_name = 'invoice_lines' then
      select status into parent_status from public.invoices where id = old.invoice_id;
    elsif tg_table_name = 'settlement_lines' then
      select status into parent_status from public.settlements where id = old.settlement_id;
    end if;
    if parent_status is distinct from 'draft' then
      raise exception 'Issued financial snapshots are immutable.' using errcode = '55000';
    end if;
    return old;
  end if;

  if tg_table_name = 'invoices' or tg_table_name = 'settlements' then
    if new.status = 'voided' and not private.is_tenant_owner(old.tenant_id) then
      raise exception 'Only the tenant owner can void financial documents.' using errcode = '42501';
    end if;
    if old.status = 'paid' and new.status = 'voided' then
      raise exception 'Paid financial documents cannot be voided.' using errcode = 'P0001';
    end if;
    if new.status <> old.status and new.status <> 'voided' then
      if tg_table_name = 'invoices' then
        select case
          when round(i.gross - coalesce(sum(pa.amount) filter (where p.direction = 'incoming' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) <= 0 then 'paid'
          when coalesce(sum(pa.amount) filter (where p.direction = 'incoming' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0) > 0 then 'part_paid'
          else 'issued'
        end into expected_status
        from public.invoices i
        left join public.payment_allocations pa on pa.document_type = 'invoice' and pa.document_id = i.id
        left join public.payments p on p.id = pa.payment_id
        where i.id = old.id
        group by i.gross;
      else
        select case
          when round(s.total - coalesce(sum(pa.amount) filter (where p.direction = 'outgoing' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) <= 0 then 'paid'
          when coalesce(sum(pa.amount) filter (where p.direction = 'outgoing' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0) > 0 then 'part_paid'
          else 'issued'
        end into expected_status
        from public.settlements s
        left join public.payment_allocations pa on pa.document_type = 'settlement' and pa.document_id = s.id
        left join public.payments p on p.id = pa.payment_id
        where s.id = old.id
        group by s.total;
      end if;
      if new.status <> expected_status then
        raise exception 'Financial status is server-managed.' using errcode = '55000';
      end if;
    end if;
    if old.status is distinct from 'draft'
       and (to_jsonb(new) - array['status', 'void_reason', 'created_at'])
           is distinct from (to_jsonb(old) - array['status', 'void_reason', 'created_at']) then
      raise exception 'Issued financial snapshots are immutable.' using errcode = '55000';
    end if;
  elsif tg_table_name = 'invoice_lines' then
    select status into parent_status from public.invoices where id = old.invoice_id;
    if parent_status is distinct from 'draft' then
      raise exception 'Issued financial snapshots are immutable.' using errcode = '55000';
    end if;
  elsif tg_table_name = 'settlement_lines' then
    select status into parent_status from public.settlements where id = old.settlement_id;
    if parent_status is distinct from 'draft' then
      raise exception 'Issued financial snapshots are immutable.' using errcode = '55000';
    end if;
  end if;
  return new;
end;
$$;

create trigger invoices_immutable
before update or delete on public.invoices
for each row execute function private.money_immutable_row();
create trigger invoice_lines_immutable
before update or delete on public.invoice_lines
for each row execute function private.money_immutable_row();
create trigger settlements_immutable
before update or delete on public.settlements
for each row execute function private.money_immutable_row();
create trigger settlement_lines_immutable
before update or delete on public.settlement_lines
for each row execute function private.money_immutable_row();

create or replace function private.refresh_money_statuses(
  p_tenant_id uuid,
  p_invoice_ids uuid[] default '{}',
  p_settlement_ids uuid[] default '{}',
  p_expense_ids uuid[] default '{}'
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.invoices i
  set status = case
    when round(i.gross - coalesce((
      select sum(pa.amount)
      from public.payment_allocations pa
      join public.payments p on p.id = pa.payment_id
      where pa.tenant_id = p_tenant_id
        and pa.document_type = 'invoice'
        and pa.document_id = i.id
        and p.direction = 'incoming'
        and (p.method <> 'cheque' or p.cheque_state = 'cleared')
    ), 0), 2) <= 0 then 'paid'
    when coalesce((
      select sum(pa.amount)
      from public.payment_allocations pa
      join public.payments p on p.id = pa.payment_id
      where pa.tenant_id = p_tenant_id
        and pa.document_type = 'invoice'
        and pa.document_id = i.id
        and p.direction = 'incoming'
        and (p.method <> 'cheque' or p.cheque_state = 'cleared')
    ), 0) > 0 then 'part_paid'
    else 'issued'
  end
  where i.tenant_id = p_tenant_id
    and i.status <> 'voided'
    and (cardinality(p_invoice_ids) = 0 or i.id = any(p_invoice_ids));

  update public.settlements s
  set status = case
    when round(s.total - coalesce((
      select sum(pa.amount)
      from public.payment_allocations pa
      join public.payments p on p.id = pa.payment_id
      where pa.tenant_id = p_tenant_id
        and pa.document_type = 'settlement'
        and pa.document_id = s.id
        and p.direction = 'outgoing'
        and (p.method <> 'cheque' or p.cheque_state = 'cleared')
    ), 0), 2) <= 0 then 'paid'
    when coalesce((
      select sum(pa.amount)
      from public.payment_allocations pa
      join public.payments p on p.id = pa.payment_id
      where pa.tenant_id = p_tenant_id
        and pa.document_type = 'settlement'
        and pa.document_id = s.id
        and p.direction = 'outgoing'
        and (p.method <> 'cheque' or p.cheque_state = 'cleared')
    ), 0) > 0 then 'part_paid'
    else 'issued'
  end
  where s.tenant_id = p_tenant_id
    and s.status <> 'voided'
    and (cardinality(p_settlement_ids) = 0 or s.id = any(p_settlement_ids));

  update public.expenses e
  set is_paid = round(e.net + e.vat - coalesce((
    select sum(pa.amount)
    from public.payment_allocations pa
    join public.payments p on p.id = pa.payment_id
    where pa.tenant_id = p_tenant_id
      and pa.document_type = 'expense'
      and pa.document_id = e.id
      and p.direction = 'outgoing'
      and (p.method <> 'cheque' or p.cheque_state = 'cleared')
  ), 0), 2) <= 0
  where e.tenant_id = p_tenant_id
    and (cardinality(p_expense_ids) = 0 or e.id = any(p_expense_ids));
end;
$$;

create or replace function public.issue_invoice(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid;
  v_invoice_id uuid;
  v_invoice_prefix text;
  buyer_type text;
  line jsonb;
  work_id uuid;
  line_count int;
  work_count int;
  requested_work_count int := jsonb_array_length(coalesce(payload->'work_order_ids', '[]'::jsonb));
  total_net numeric(14,2) := 0;
  total_vat numeric(14,2) := 0;
  line_net numeric(14,2);
  line_vat numeric(14,2);
begin
  select tm.tenant_id into v_tenant_id
  from public.tenant_members tm
  where tm.user_id = (select auth.uid()) and tm.status = 'active'
  limit 1;
  perform private.money_ensure_access(v_tenant_id);

  select p.type into buyer_type
  from public.parties p
  where p.id = (payload->>'buyer_id')::uuid
    and p.tenant_id = v_tenant_id and not p.is_archived;
  if buyer_type is distinct from 'customer' then
    raise exception 'Invoice buyer is unavailable.' using errcode = 'P0001';
  end if;

  select count(*) into line_count from jsonb_array_elements(coalesce(payload->'lines', '[]'::jsonb));
  if line_count = 0 then raise exception 'Invoice needs a line.' using errcode = '22023'; end if;

  select count(*) into work_count
  from public.work_orders w
  where w.tenant_id = v_tenant_id
    and w.id in (select value::uuid from jsonb_array_elements_text(coalesce(payload->'work_order_ids', '[]'::jsonb)))
    and w.customer_id = (payload->>'buyer_id')::uuid
    and w.status = 'completed'
    and w.invoice_id is null;
  if work_count <> requested_work_count then
    raise exception 'Only completed, unbilled customer work can be invoiced.' using errcode = 'P0001';
  end if;

  for line in select * from jsonb_array_elements(payload->'lines') loop
    line_net := round(coalesce(nullif(line->>'net_override', '')::numeric,
      round(coalesce((line->>'quantity')::numeric, 1) * coalesce((line->>'unit_price')::numeric, 0)
        - coalesce((line->>'discount')::numeric, 0), 2)), 2);
    line_vat := round(coalesce(nullif(line->>'vat_override', '')::numeric,
      round(line_net * coalesce((line->>'vat_rate')::numeric, 5) / 100, 2)), 2);
    total_net := round(total_net + line_net, 2);
    total_vat := round(total_vat + line_vat, 2);
  end loop;

  select bp.invoice_prefix into v_invoice_prefix
  from public.business_profiles bp
  where bp.tenant_id = v_tenant_id;
  v_invoice_prefix := coalesce(nullif(trim(v_invoice_prefix), ''), 'INV') || '-';

  v_invoice_id := extensions.gen_random_uuid();
  insert into public.invoices (
    id, tenant_id, number, buyer_id, buyer_name, buyer_address, buyer_trn,
    buyer_contact, payment_terms, issue_date, due_date, supply_date,
    net, vat, gross, status
  ) values (
    v_invoice_id, v_tenant_id,
    private.next_document_number(v_tenant_id, 'invoice', v_invoice_prefix),
    (payload->>'buyer_id')::uuid,
    payload->>'buyer_name', payload->>'buyer_address', payload->>'buyer_trn',
    payload->>'buyer_contact', coalesce(payload->>'payment_terms', 'On receipt'),
    ((payload->>'issue_date')::timestamptz)::date,
    nullif(payload->>'due_date', '')::timestamptz::date,
    nullif(payload->>'supply_date', '')::timestamptz::date,
    total_net, total_vat, round(total_net + total_vat, 2), 'issued'
  );

  for line in select * from jsonb_array_elements(payload->'lines') loop
    line_net := round(coalesce(nullif(line->>'net_override', '')::numeric,
      round(coalesce((line->>'quantity')::numeric, 1) * coalesce((line->>'unit_price')::numeric, 0)
        - coalesce((line->>'discount')::numeric, 0), 2)), 2);
    line_vat := round(coalesce(nullif(line->>'vat_override', '')::numeric,
      round(line_net * coalesce((line->>'vat_rate')::numeric, 5) / 100, 2)), 2);
    insert into public.invoice_lines (
      tenant_id, invoice_id, name, description, quantity, unit_price, unit,
      discount, vat_rate, net_override, vat_override, net, vat, gross
    ) values (
      v_tenant_id, v_invoice_id, line->>'name', line->>'description',
      coalesce((line->>'quantity')::numeric, 1),
      coalesce((line->>'unit_price')::numeric, 0), coalesce(line->>'unit', 'unit'),
      coalesce((line->>'discount')::numeric, 0), coalesce((line->>'vat_rate')::numeric, 5),
      nullif(line->>'net_override', '')::numeric,
      nullif(line->>'vat_override', '')::numeric,
      line_net, line_vat, round(line_net + line_vat, 2)
    );
  end loop;

  update public.work_orders
  set status = 'billed', invoice_id = v_invoice_id
  where tenant_id = v_tenant_id
    and id in (select value::uuid from jsonb_array_elements_text(coalesce(payload->'work_order_ids', '[]'::jsonb)));
  return v_invoice_id;
end;
$$;

create or replace function public.void_invoice(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_tenant_id uuid; current_status text;
begin
  select i.tenant_id, i.status into v_tenant_id, current_status from public.invoices i where i.id = p_id;
  if current_status is null then raise exception 'Invoice not found.' using errcode = 'P0002'; end if;
  perform private.money_ensure_owner(v_tenant_id);
  if current_status = 'paid' then raise exception 'Paid invoices cannot be voided.' using errcode = 'P0001'; end if;
  if current_status = 'voided' then raise exception 'Invoice is already voided.' using errcode = 'P0001'; end if;
  update public.invoices set status = 'voided', void_reason = nullif(trim(p_reason), '') where id = p_id;
  update public.work_orders set status = 'completed', invoice_id = null
  where tenant_id = v_tenant_id and invoice_id = p_id;
end;
$$;

create or replace function public.issue_supplier_settlement(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid; v_settlement_id uuid; supplier_type text; line jsonb;
  line_count int; v_total numeric(14,2) := 0;
begin
  select tm.tenant_id into v_tenant_id from public.tenant_members tm
  where tm.user_id = (select auth.uid()) and tm.status = 'active' limit 1;
  perform private.money_ensure_access(v_tenant_id);
  select p.type into supplier_type from public.parties p
  where p.id = (payload->>'supplier_id')::uuid and p.tenant_id = v_tenant_id and not p.is_archived;
  if supplier_type is distinct from 'supplier' then
    raise exception 'Settlement supplier is unavailable.' using errcode = 'P0001';
  end if;
  select count(*) into line_count from jsonb_array_elements(coalesce(payload->'lines', '[]'::jsonb));
  if line_count = 0 then raise exception 'Settlement needs a line.' using errcode = '22023'; end if;
  if exists (
    select 1
    from jsonb_array_elements(payload->'lines') l
    where not exists (
      select 1 from public.work_orders w
      where w.id = (l->>'work_order_id')::uuid and w.tenant_id = v_tenant_id
    )
  ) then
    raise exception 'Settlement work order is unavailable.' using errcode = 'P0001';
  end if;

  for line in select * from jsonb_array_elements(payload->'lines') loop
    v_total := round(v_total + (line->>'amount')::numeric, 2);
  end loop;

  v_settlement_id := extensions.gen_random_uuid();
  insert into public.settlements (
    id, tenant_id, number, supplier_id, period_start, period_end, total, status
  ) values (
    v_settlement_id, v_tenant_id,
    -- 'SET-' mirrors AppConfig.settlementPrefix; fixed system-wide, not tenant-configurable.
    private.next_document_number(v_tenant_id, 'settlement', 'SET-'),
    (payload->>'supplier_id')::uuid,
    ((payload->>'period_start')::timestamptz)::date,
    ((payload->>'period_end')::timestamptz)::date,
    v_total, 'issued'
  );
  for line in select * from jsonb_array_elements(payload->'lines') loop
    insert into public.settlement_lines (
      tenant_id, settlement_id, work_order_id, date, amount,
      customer_name, vehicle_id, driver_id, route
    ) values (
      v_tenant_id, v_settlement_id, (line->>'work_order_id')::uuid,
      ((line->>'date')::timestamptz)::date, (line->>'amount')::numeric,
      line->>'customer_name', nullif(line->>'vehicle_id', '')::uuid,
      nullif(line->>'driver_id', '')::uuid, line->>'route'
    );
  end loop;
  return v_settlement_id;
end;
$$;

create or replace function public.void_supplier_settlement(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_tenant_id uuid; current_status text;
begin
  select s.tenant_id, s.status into v_tenant_id, current_status from public.settlements s where s.id = p_id;
  if current_status is null then raise exception 'Settlement not found.' using errcode = 'P0002'; end if;
  perform private.money_ensure_owner(v_tenant_id);
  if current_status = 'paid' then raise exception 'Paid settlements cannot be voided.' using errcode = 'P0001'; end if;
  if current_status = 'voided' then raise exception 'Settlement is already voided.' using errcode = 'P0001'; end if;
  update public.settlements set status = 'voided', void_reason = nullif(trim(p_reason), '') where id = p_id;
end;
$$;

create or replace function public.record_payment_allocation(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid; v_payment_id uuid; allocation jsonb; allocated numeric(14,2) := 0;
  direction text := payload->>'direction'; method text := payload->>'method';
  state text; target_total numeric(14,2); target_amount numeric(14,2);
  target_status text; target_tenant uuid; target_party uuid;
  invoice_ids uuid[] := '{}'; settlement_ids uuid[] := '{}'; expense_ids uuid[] := '{}';
begin
  select tm.tenant_id into v_tenant_id from public.tenant_members tm
  where tm.user_id = (select auth.uid()) and tm.status = 'active' limit 1;
  perform private.money_ensure_access(v_tenant_id);
  if direction not in ('incoming', 'outgoing') or method not in ('cash', 'bank_transfer', 'cheque') then
    raise exception 'Payment fields are invalid.' using errcode = '22023';
  end if;
  if (payload->>'amount')::numeric <= 0 then raise exception 'Payment amount must be positive.' using errcode = '22023'; end if;
  state := case when method = 'cheque' then 'received' else null end;
  insert into public.payments (
    tenant_id, direction, party_id, method, amount, date, reference,
    cheque_date, cheque_state, notes
  ) values (
    v_tenant_id, direction, nullif(payload->>'party_id', '')::uuid, method,
    (payload->>'amount')::numeric, ((payload->>'date')::timestamptz)::date,
    payload->>'reference', nullif(payload->>'cheque_date', '')::timestamptz::date,
    state, payload->>'notes'
  ) returning id into v_payment_id;

  for allocation in select * from jsonb_array_elements(coalesce(payload->'allocations', '[]'::jsonb)) loop
    if (allocation->>'amount')::numeric <= 0 then raise exception 'Allocation must be positive.' using errcode = '22023'; end if;
    allocated := round(allocated + (allocation->>'amount')::numeric, 2);
    if allocated > (payload->>'amount')::numeric then
      raise exception 'Allocations exceed payment amount.' using errcode = '22023';
    end if;
    target_total := 0;
    target_amount := 0;
    target_party := null;
    select coalesce(sum(pa.amount), 0) into target_total
    from public.payment_allocations pa join public.payments p on p.id = pa.payment_id
    where pa.tenant_id = v_tenant_id
      and pa.document_type = allocation->>'document_type'
      and pa.document_id = (allocation->>'document_id')::uuid
      and (p.method <> 'cheque' or p.cheque_state in ('received', 'cleared'));

    if allocation->>'document_type' = 'invoice' then
      if direction <> 'incoming' then raise exception 'Incoming payments allocate invoices only.' using errcode = '22023'; end if;
      select i.gross, i.status, i.tenant_id, i.buyer_id into target_amount, target_status, target_tenant, target_party
      from public.invoices i where i.id = (allocation->>'document_id')::uuid;
    elsif allocation->>'document_type' = 'settlement' then
      if direction <> 'outgoing' then raise exception 'Outgoing payments allocate settlements only.' using errcode = '22023'; end if;
      select s.total, s.status, s.tenant_id, s.supplier_id into target_amount, target_status, target_tenant, target_party
      from public.settlements s where s.id = (allocation->>'document_id')::uuid;
    elsif allocation->>'document_type' = 'expense' then
      if direction <> 'outgoing' then raise exception 'Outgoing payments allocate expenses only.' using errcode = '22023'; end if;
      select round(e.net + e.vat, 2), case when e.is_paid then 'paid' else 'issued' end, e.tenant_id
      into target_amount, target_status, target_tenant
      from public.expenses e where e.id = (allocation->>'document_id')::uuid;
    else
      raise exception 'Payment target is invalid.' using errcode = '22023';
    end if;
    if target_tenant is distinct from v_tenant_id or target_status is null or target_status = 'voided' then
      raise exception 'Payment target is unavailable.' using errcode = 'P0001';
    end if;
    if target_party is not null and payload->>'party_id' is not null
       and target_party <> (payload->>'party_id')::uuid then
      raise exception 'Payment party does not match the target.' using errcode = '22023';
    end if;
    if target_total + (allocation->>'amount')::numeric > target_amount then
      raise exception 'Allocation exceeds the remaining balance.' using errcode = '22023';
    end if;
    insert into public.payment_allocations (
      tenant_id, payment_id, document_type, document_id, amount
    ) values (
      v_tenant_id, v_payment_id, allocation->>'document_type',
      (allocation->>'document_id')::uuid, (allocation->>'amount')::numeric
    );
    if allocation->>'document_type' = 'invoice' then invoice_ids := array_append(invoice_ids, (allocation->>'document_id')::uuid); end if;
    if allocation->>'document_type' = 'settlement' then settlement_ids := array_append(settlement_ids, (allocation->>'document_id')::uuid); end if;
    if allocation->>'document_type' = 'expense' then expense_ids := array_append(expense_ids, (allocation->>'document_id')::uuid); end if;
  end loop;
  perform private.refresh_money_statuses(v_tenant_id, invoice_ids, settlement_ids, expense_ids);
  return v_payment_id;
end;
$$;

create or replace function public.transition_cheque_state(p_payment_id uuid, p_new_state text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_tenant_id uuid; old_state text; payment_method text; invoice_ids uuid[]; settlement_ids uuid[]; expense_ids uuid[];
begin
  select p.tenant_id, p.cheque_state, p.method into v_tenant_id, old_state, payment_method
  from public.payments p where p.id = p_payment_id;
  perform private.money_ensure_access(v_tenant_id);
  if payment_method <> 'cheque' or old_state <> 'received' or p_new_state not in ('cleared', 'bounced') then
    raise exception 'Cheque transition is invalid.' using errcode = 'P0001';
  end if;
  select coalesce(array_agg(pa.document_id) filter (where pa.document_type = 'invoice'), '{}'),
         coalesce(array_agg(pa.document_id) filter (where pa.document_type = 'settlement'), '{}'),
         coalesce(array_agg(pa.document_id) filter (where pa.document_type = 'expense'), '{}')
  into invoice_ids, settlement_ids, expense_ids
  from public.payment_allocations pa where pa.payment_id = p_payment_id;
  update public.payments set cheque_state = p_new_state where id = p_payment_id;
  perform private.refresh_money_statuses(v_tenant_id, invoice_ids, settlement_ids, expense_ids);
end;
$$;

create view public.invoice_balances with (security_invoker = true) as
select i.tenant_id, i.id as invoice_id, i.number, i.gross,
  case when i.status = 'voided' then 0 else round(coalesce(sum(pa.amount) filter (where p.direction = 'incoming' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) end as paid,
  case when i.status = 'voided' then 0 else round(i.gross - coalesce(sum(pa.amount) filter (where p.direction = 'incoming' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) end as balance
from public.invoices i
left join public.payment_allocations pa on pa.document_type = 'invoice' and pa.document_id = i.id
left join public.payments p on p.id = pa.payment_id
group by i.tenant_id, i.id, i.number, i.gross;

create view public.settlement_balances with (security_invoker = true) as
select s.tenant_id, s.id as settlement_id, s.number, s.total,
  case when s.status = 'voided' then 0 else round(coalesce(sum(pa.amount) filter (where p.direction = 'outgoing' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) end as paid,
  case when s.status = 'voided' then 0 else round(s.total - coalesce(sum(pa.amount) filter (where p.direction = 'outgoing' and (p.method <> 'cheque' or p.cheque_state = 'cleared')), 0), 2) end as balance
from public.settlements s
left join public.payment_allocations pa on pa.document_type = 'settlement' and pa.document_id = s.id
left join public.payments p on p.id = pa.payment_id
group by s.tenant_id, s.id, s.number, s.total;

create view public.party_balances with (security_invoker = true) as
with customer_balances as (
  select i.tenant_id, i.buyer_id as party_id,
    round(sum(ib.balance) filter (where i.status <> 'voided'), 2) as balance
  from public.invoices i join public.invoice_balances ib on ib.invoice_id = i.id
  group by i.tenant_id, i.buyer_id
), supplier_settlements as (
  select s.tenant_id, s.supplier_id as party_id,
    round(sum(sb.balance) filter (where s.status <> 'voided'), 2) as balance
  from public.settlements s join public.settlement_balances sb on sb.settlement_id = s.id
  group by s.tenant_id, s.supplier_id
), supplier_expenses as (
  select e.tenant_id, p.id as party_id,
    round(sum(e.net + e.vat - coalesce(ea.paid, 0)), 2) as balance
  from public.expenses e
  join public.parties p on p.tenant_id = e.tenant_id and p.type = 'supplier' and lower(p.name) = lower(e.payee)
  left join lateral (
    select round(coalesce(sum(pa.amount) filter (where pay.direction = 'outgoing' and (pay.method <> 'cheque' or pay.cheque_state = 'cleared')), 0), 2) as paid
    from public.payment_allocations pa join public.payments pay on pay.id = pa.payment_id
    where pa.document_type = 'expense' and pa.document_id = e.id
  ) ea on true
  group by e.tenant_id, p.id
), supplier_balances as (
  select p.tenant_id, p.id as party_id,
    round(coalesce(ss.balance, 0) + coalesce(se.balance, 0), 2) as balance
  from public.parties p
  left join supplier_settlements ss on ss.party_id = p.id and ss.tenant_id = p.tenant_id
  left join supplier_expenses se on se.party_id = p.id and se.tenant_id = p.tenant_id
  where p.type = 'supplier'
)
select p.tenant_id, p.id as party_id, p.type as party_type,
  case when p.type = 'customer' then coalesce(cb.balance, 0) else coalesce(sb.balance, 0) end as balance
from public.parties p
left join customer_balances cb on cb.party_id = p.id and cb.tenant_id = p.tenant_id
left join supplier_balances sb on sb.party_id = p.id and sb.tenant_id = p.tenant_id;

create view public.unbilled_work with (security_invoker = true) as
select w.tenant_id, w.id as work_order_id, w.number, w.customer_id, p.name as customer_name,
  w.agreement_id, w.date, w.work_type, w.status, w.pickup, w.destination,
  w.planned_start, w.planned_end, w.customer_job_reference, w.description, w.notes,
  round(coalesce((select sum(round(l.quantity * l.unit_price - l.discount, 2))
    from public.work_order_charge_lines l where l.work_order_id = w.id), 0), 2) as net,
  round(coalesce((select sum(round(round(l.quantity * l.unit_price - l.discount, 2) * l.vat_rate / 100, 2))
    from public.work_order_charge_lines l where l.work_order_id = w.id), 0), 2) as vat,
  round(coalesce((select sum(round(l.quantity * l.unit_price - l.discount, 2))
    from public.work_order_charge_lines l where l.work_order_id = w.id), 0)
    + coalesce((select sum(round(round(l.quantity * l.unit_price - l.discount, 2) * l.vat_rate / 100, 2))
    from public.work_order_charge_lines l where l.work_order_id = w.id), 0), 2) as gross,
  coalesce((select jsonb_agg(jsonb_build_object(
    'vehicle_id', a.vehicle_id, 'driver_id', a.driver_id, 'source', a.source,
    'supplier_id', a.supplier_id, 'supplier_payable', a.supplier_payable, 'notes', a.notes
  ) order by a.id) from public.work_order_allocations a where a.work_order_id = w.id), '[]'::jsonb) as allocations,
  coalesce((select jsonb_agg(jsonb_build_object(
    'name', l.name, 'description', l.description, 'quantity', l.quantity,
    'unit_price', l.unit_price, 'unit', l.unit, 'discount', l.discount, 'vat_rate', l.vat_rate
  ) order by l.id) from public.work_order_charge_lines l where l.work_order_id = w.id), '[]'::jsonb) as charge_lines
from public.work_orders w join public.parties p on p.id = w.customer_id
where w.status = 'completed' and w.invoice_id is null;

create view public.statement_rows with (security_invoker = true) as
select w.tenant_id, w.customer_id as party_id, w.date, w.id as work_order_id,
  coalesce(w.description, w.pickup || ' to ' || w.destination) as description,
  round(coalesce(sum(round(l.quantity * l.unit_price - l.discount, 2)), 0)
    + coalesce(sum(round(round(l.quantity * l.unit_price - l.discount, 2) * l.vat_rate / 100, 2)), 0), 2) as amount
from public.work_orders w
join public.work_order_charge_lines l on l.work_order_id = w.id
where w.status <> 'canceled'
group by w.tenant_id, w.customer_id, w.date, w.id, w.description, w.pickup, w.destination;

alter table public.expenses enable row level security;
alter table public.expenses force row level security;
alter table public.invoices enable row level security;
alter table public.invoices force row level security;
alter table public.invoice_lines enable row level security;
alter table public.invoice_lines force row level security;
alter table public.settlements enable row level security;
alter table public.settlements force row level security;
alter table public.settlement_lines enable row level security;
alter table public.settlement_lines force row level security;
alter table public.payments enable row level security;
alter table public.payments force row level security;
alter table public.payment_allocations enable row level security;
alter table public.payment_allocations force row level security;

create policy expenses_select_member on public.expenses for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = expenses.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);
create policy expenses_insert_money on public.expenses for insert to authenticated with check (private.has_access_pack(tenant_id, 'money'));

create policy invoices_select_member on public.invoices for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = invoices.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);
create policy invoice_lines_select_member on public.invoice_lines for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = invoice_lines.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);

create policy settlements_select_member on public.settlements for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = settlements.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);
create policy settlement_lines_select_member on public.settlement_lines for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = settlement_lines.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);

create policy payments_select_member on public.payments for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = payments.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);
create policy payment_allocations_select_member on public.payment_allocations for select to authenticated using (
  exists (select 1 from public.tenant_members tm where tm.tenant_id = payment_allocations.tenant_id and tm.user_id = (select auth.uid()) and tm.status = 'active')
);

revoke all on public.expenses, public.invoices, public.invoice_lines, public.settlements,
  public.settlement_lines, public.payments, public.payment_allocations from anon, authenticated;
grant select, insert on public.expenses to authenticated;
-- invoices/settlements change only through the security-definer RPCs; the
-- immutability trigger stays as a second layer behind the missing grant.
grant select on public.invoices, public.settlements to authenticated;
grant select on public.invoice_lines, public.settlement_lines, public.payments, public.payment_allocations to authenticated;
revoke all on public.invoice_balances, public.settlement_balances, public.party_balances,
  public.unbilled_work, public.statement_rows from anon, authenticated;
grant select on public.invoice_balances, public.settlement_balances, public.party_balances,
  public.unbilled_work, public.statement_rows to authenticated;

revoke all on function private.money_ensure_access(uuid) from public, anon;
revoke all on function private.money_ensure_owner(uuid) from public, anon;
revoke all on function private.money_immutable_row() from public, anon, authenticated;
revoke all on function private.refresh_money_statuses(uuid, uuid[], uuid[], uuid[]) from public, anon, authenticated;
revoke all on function public.issue_invoice(jsonb), public.void_invoice(uuid, text),
  public.issue_supplier_settlement(jsonb), public.void_supplier_settlement(uuid, text),
  public.record_payment_allocation(jsonb), public.transition_cheque_state(uuid, text)
  from public, anon;
grant execute on function public.issue_invoice(jsonb), public.void_invoice(uuid, text),
  public.issue_supplier_settlement(jsonb), public.void_supplier_settlement(uuid, text),
  public.record_payment_allocation(jsonb), public.transition_cheque_state(uuid, text)
  to authenticated;
