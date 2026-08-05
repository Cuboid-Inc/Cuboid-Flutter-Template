create table public.document_sequences (
  tenant_id uuid not null references public.tenants(id) on delete cascade,
  kind text not null,
  year integer not null,
  next_value bigint not null default 1 check (next_value > 0),
  primary key (tenant_id, kind, year)
);

-- Document numbers use a PREFIX-YEAR-NNN format, resetting to 001 at the
-- start of each calendar year per tenant per kind, zero-padded to a 3-digit
-- floor that grows naturally past 999.
create or replace function private.next_document_number(
  p_tenant_id uuid,
  p_kind text,
  p_prefix text
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_year int := extract(year from now())::int;
  v_next bigint;
begin
  if not exists (
    select 1
    from public.tenant_members
    where tenant_id = p_tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  ) then
    raise exception 'Active tenant membership is required.' using errcode = '42501';
  end if;

  insert into public.document_sequences (tenant_id, kind, year)
  values (p_tenant_id, p_kind, v_year)
  on conflict (tenant_id, kind, year) do update
    set next_value = public.document_sequences.next_value;

  select next_value
  into v_next
  from public.document_sequences
  where tenant_id = p_tenant_id
    and kind = p_kind
    and year = v_year
  for update;

  update public.document_sequences
  set next_value = v_next + 1
  where tenant_id = p_tenant_id
    and kind = p_kind
    and year = v_year;

  return p_prefix || v_year || '-' ||
    lpad(v_next::text, greatest(length(v_next::text), 3), '0');
end;
$$;

revoke all on function private.next_document_number(uuid, text, text)
from public, anon, authenticated;
grant execute on function private.next_document_number(uuid, text, text)
to authenticated;

-- The manual "Agreement Ref" field was removed from the client form, so new
-- agreements arrive with an empty reference; auto-assign one on insert,
-- matching AppConfig.agreementPrefix. Edits keep whatever reference the row
-- already has.
create or replace function private.agreements_set_reference()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.reference is null or length(trim(new.reference)) = 0 then
    new.reference := private.next_document_number(new.tenant_id, 'agreement', 'AGR-');
  end if;
  return new;
end;
$$;

revoke all on function private.agreements_set_reference()
from public, anon, authenticated;

create trigger agreements_set_reference
before insert on public.agreements
for each row execute function private.agreements_set_reference();

create table public.work_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  number text not null,
  customer_id uuid not null,
  agreement_id uuid,
  date timestamptz not null,
  work_type text not null check (work_type in ('per_trip', 'monthly_extra')),
  status text not null default 'planned'
    check (status in ('planned', 'completed', 'canceled', 'billed')),
  pickup text not null,
  destination text not null,
  planned_start timestamptz,
  planned_end timestamptz,
  customer_job_reference text,
  description text,
  notes text,
  invoice_id uuid,
  created_at timestamptz not null default now(),
  unique (tenant_id, number),
  unique (tenant_id, id),
  foreign key (tenant_id, customer_id)
    references public.parties (tenant_id, id) on delete restrict,
  foreign key (tenant_id, agreement_id)
    references public.agreements (tenant_id, id) on delete restrict
);

create table public.work_order_allocations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  work_order_id uuid not null,
  vehicle_id uuid not null,
  driver_id uuid,
  source text not null check (source in ('owned', 'supplier')),
  supplier_id uuid,
  supplier_payable numeric(14,2) not null default 0 check (supplier_payable >= 0),
  notes text,
  foreign key (tenant_id, work_order_id)
    references public.work_orders (tenant_id, id) on delete cascade,
  foreign key (tenant_id, vehicle_id)
    references public.vehicles (tenant_id, id) on delete restrict,
  foreign key (tenant_id, driver_id)
    references public.drivers (tenant_id, id) on delete restrict,
  foreign key (tenant_id, supplier_id)
    references public.parties (tenant_id, id) on delete restrict
);

create table public.work_order_charge_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  work_order_id uuid not null,
  name text not null,
  description text,
  quantity numeric(10,2) not null default 1,
  unit_price numeric(14,2) not null,
  unit text not null default 'unit',
  discount numeric(14,2) not null default 0,
  vat_rate numeric(5,2) not null default 5,
  foreign key (tenant_id, work_order_id)
    references public.work_orders (tenant_id, id) on delete cascade
);

create index work_orders_tenant_date_idx
  on public.work_orders (tenant_id, date desc);
create index work_order_allocations_work_order_id_idx
  on public.work_order_allocations (work_order_id);
create index work_order_charge_lines_work_order_id_idx
  on public.work_order_charge_lines (work_order_id);

alter table public.document_sequences enable row level security;
alter table public.document_sequences force row level security;
alter table public.work_orders enable row level security;
alter table public.work_orders force row level security;
alter table public.work_order_allocations enable row level security;
alter table public.work_order_allocations force row level security;
alter table public.work_order_charge_lines enable row level security;
alter table public.work_order_charge_lines force row level security;

create policy work_orders_select_member
on public.work_orders for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = work_orders.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

-- Writes go through the security-definer RPCs below so status, numbering,
-- and invoice linkage stay server-managed. The only direct write clients keep
-- is deleting a still-planned work order (blueprint rule).
create policy work_orders_delete_planned
on public.work_orders for delete
to authenticated
using (
  status = 'planned'
  and private.has_access_pack(tenant_id, 'operations')
);

create policy work_order_allocations_select_member
on public.work_order_allocations for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = work_order_allocations.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy work_order_charge_lines_select_member
on public.work_order_charge_lines for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = work_order_charge_lines.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

revoke all on public.document_sequences from anon, authenticated;
revoke all on public.work_orders from anon, authenticated;
revoke all on public.work_order_allocations from anon, authenticated;
revoke all on public.work_order_charge_lines from anon, authenticated;

grant select, delete on public.work_orders to authenticated;
grant select on public.work_order_allocations to authenticated;
grant select on public.work_order_charge_lines to authenticated;

create or replace function public.create_work_order(payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid := (payload->>'tenant_id')::uuid;
  v_work_order_id uuid := extensions.gen_random_uuid();
  v_allocation jsonb;
  v_charge_line jsonb;
begin
  if not private.has_access_pack(v_tenant_id, 'operations') then
    raise exception 'Operations access is required.' using errcode = '42501';
  end if;

  insert into public.work_orders (
    id,
    tenant_id,
    number,
    customer_id,
    agreement_id,
    date,
    work_type,
    status,
    pickup,
    destination,
    planned_start,
    planned_end,
    customer_job_reference,
    description,
    notes,
    invoice_id
  )
  values (
    v_work_order_id,
    v_tenant_id,
    -- 'WO-' mirrors AppConfig.workOrderPrefix; fixed system-wide, not tenant-configurable.
    private.next_document_number(v_tenant_id, 'work_order', 'WO-'),
    (payload->>'customer_id')::uuid,
    (payload->>'agreement_id')::uuid,
    (payload->>'date')::timestamptz,
    coalesce(payload->>'work_type', 'per_trip'),
    -- server-managed: new work is always planned and unbilled
    'planned',
    payload->>'pickup',
    payload->>'destination',
    nullif(payload->>'planned_start', '')::timestamptz,
    nullif(payload->>'planned_end', '')::timestamptz,
    nullif(payload->>'customer_job_reference', ''),
    nullif(payload->>'description', ''),
    nullif(payload->>'notes', ''),
    null
  );

  for v_allocation in
    select * from jsonb_array_elements(coalesce(payload->'allocations', '[]'::jsonb))
  loop
    insert into public.work_order_allocations (
      tenant_id,
      work_order_id,
      vehicle_id,
      driver_id,
      source,
      supplier_id,
      supplier_payable,
      notes
    )
    values (
      v_tenant_id,
      v_work_order_id,
      (v_allocation->>'vehicle_id')::uuid,
      nullif(v_allocation->>'driver_id', '')::uuid,
      v_allocation->>'source',
      nullif(v_allocation->>'supplier_id', '')::uuid,
      coalesce((v_allocation->>'supplier_payable')::numeric, 0),
      nullif(v_allocation->>'notes', '')
    );
  end loop;

  for v_charge_line in
    select * from jsonb_array_elements(coalesce(payload->'charge_lines', '[]'::jsonb))
  loop
    insert into public.work_order_charge_lines (
      tenant_id,
      work_order_id,
      name,
      description,
      quantity,
      unit_price,
      unit,
      discount,
      vat_rate
    )
    values (
      v_tenant_id,
      v_work_order_id,
      v_charge_line->>'name',
      nullif(v_charge_line->>'description', ''),
      coalesce((v_charge_line->>'quantity')::numeric, 1),
      (v_charge_line->>'unit_price')::numeric,
      coalesce(v_charge_line->>'unit', 'unit'),
      coalesce((v_charge_line->>'discount')::numeric, 0),
      coalesce((v_charge_line->>'vat_rate')::numeric, 5)
    );
  end loop;

  return v_work_order_id;
end;
$$;

create or replace function public.complete_work_order(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid;
  v_status text;
begin
  select tenant_id, status
  into v_tenant_id, v_status
  from public.work_orders
  where id = p_id
  for update;

  if v_tenant_id is null then
    raise exception 'Work order not found.' using errcode = 'P0001';
  end if;
  if not private.has_access_pack(v_tenant_id, 'operations') then
    raise exception 'Operations access is required.' using errcode = '42501';
  end if;
  if v_status <> 'planned' then
    raise exception 'Only planned work orders can be completed.' using errcode = 'P0001';
  end if;
  if not exists (
    select 1 from public.work_order_allocations where work_order_id = p_id
  ) then
    raise exception 'A work order needs at least one vehicle allocation before completion.'
      using errcode = 'P0001';
  end if;

  update public.work_orders
  set status = 'completed'
  where id = p_id;
end;
$$;

create or replace function public.cancel_work_order(p_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_tenant_id uuid;
  v_status text;
begin
  select tenant_id, status
  into v_tenant_id, v_status
  from public.work_orders
  where id = p_id
  for update;

  if v_tenant_id is null then
    raise exception 'Work order not found.' using errcode = 'P0001';
  end if;
  if not private.has_access_pack(v_tenant_id, 'operations') then
    raise exception 'Operations access is required.' using errcode = '42501';
  end if;
  if v_status <> 'planned' then
    raise exception 'Only planned work orders can be canceled.' using errcode = 'P0001';
  end if;

  update public.work_orders
  set status = 'canceled'
  where id = p_id;
end;
$$;

revoke all on function public.create_work_order(jsonb)
from public, anon, authenticated;
revoke all on function public.complete_work_order(uuid)
from public, anon, authenticated;
revoke all on function public.cancel_work_order(uuid)
from public, anon, authenticated;

grant execute on function public.create_work_order(jsonb) to authenticated;
grant execute on function public.complete_work_order(uuid) to authenticated;
grant execute on function public.cancel_work_order(uuid) to authenticated;
