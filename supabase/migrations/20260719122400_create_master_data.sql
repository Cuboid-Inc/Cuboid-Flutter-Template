create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  plate_number text not null check (length(trim(plate_number)) between 1 and 40),
  label text not null check (length(trim(label)) between 1 and 160),
  vehicle_class text not null check (
    vehicle_class in (
      'three_ton',
      'seven_ton',
      'ten_ton',
      'flatbed',
      'thirty_seat_bus',
      'trailer',
      'pickup',
      'custom'
    )
  ),
  ownership text not null check (ownership in ('owned', 'external')),
  supplier_id uuid,
  make text,
  model text,
  year int check (year between 1980 and 2100),
  registration_expiry date,
  insurance_expiry date,
  inspection_expiry date,
  notes text,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (ownership = 'external' and supplier_id is not null)
    or (ownership = 'owned' and supplier_id is null)
  ),
  unique (tenant_id, id),
  foreign key (tenant_id, supplier_id)
    references public.parties (tenant_id, id) on delete restrict
);

create index vehicles_tenant_id_idx on public.vehicles (tenant_id);

create trigger vehicles_set_updated_at
before update on public.vehicles
for each row execute function private.set_updated_at();

create table public.drivers (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  name text not null check (length(trim(name)) between 1 and 160),
  phone text,
  licence_number text,
  licence_expiry date,
  identity_reference text,
  identity_expiry date,
  employment text not null default 'operator'
    check (employment in ('operator', 'customer')),
  supplier_id uuid,
  notes text,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, id),
  foreign key (tenant_id, supplier_id)
    references public.parties (tenant_id, id) on delete restrict
);

create index drivers_tenant_id_idx on public.drivers (tenant_id);

create trigger drivers_set_updated_at
before update on public.drivers
for each row execute function private.set_updated_at();

create table public.agreements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  reference text not null check (length(trim(reference)) between 1 and 40),
  name text not null check (length(trim(name)) between 1 and 160),
  customer_id uuid not null,
  rate_model text not null check (rate_model in ('monthly', 'per_trip')),
  start_date date,
  end_date date,
  invoice_grouping text not null default 'per_work'
    check (invoice_grouping in ('per_work', 'monthly_consolidated')),
  base_rate numeric(14,2) not null default 0 check (base_rate >= 0),
  duty_days int not null default 0,
  included_hours int not null default 0,
  overtime_rate numeric(14,2) not null default 0 check (overtime_rate >= 0),
  extra_day_rate numeric(14,2) not null default 0 check (extra_day_rate >= 0),
  extra_trip_rate numeric(14,2) not null default 0 check (extra_trip_rate >= 0),
  vat_rate int not null default 5,
  driver_responsibility text not null default 'operator'
    check (driver_responsibility in ('operator', 'customer')),
  fuel_responsibility text not null default 'operator'
    check (fuel_responsibility in ('operator', 'customer')),
  maintenance_responsibility text not null default 'operator'
    check (maintenance_responsibility in ('operator', 'customer')),
  default_vehicle_id uuid,
  purchase_order_reference text,
  payment_terms text not null default 'on_receipt' check (
    payment_terms in ('on_receipt', 'net_7', 'net_15', 'net_30', 'net_45', 'net_60')
  ),
  notes text,
  default_extras jsonb not null default '{}'::jsonb,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, reference),
  unique (tenant_id, id),
  foreign key (tenant_id, customer_id)
    references public.parties (tenant_id, id) on delete restrict,
  foreign key (tenant_id, default_vehicle_id)
    references public.vehicles (tenant_id, id) on delete set null (default_vehicle_id)
);

create index agreements_tenant_id_idx on public.agreements (tenant_id);

create trigger agreements_set_updated_at
before update on public.agreements
for each row execute function private.set_updated_at();

create table public.route_rates (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  applies_to text not null check (length(trim(applies_to)) between 1 and 160),
  pickup text not null check (length(trim(pickup)) between 1 and 160),
  destination text not null check (length(trim(destination)) between 1 and 160),
  vehicle_class text not null check (
    vehicle_class in (
      'three_ton',
      'seven_ton',
      'ten_ton',
      'flatbed',
      'thirty_seat_bus',
      'trailer',
      'pickup',
      'custom'
    )
  ),
  rate numeric(14,2) not null check (rate >= 0),
  default_extras jsonb not null default '{}'::jsonb,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index route_rates_tenant_id_idx on public.route_rates (tenant_id);

create trigger route_rates_set_updated_at
before update on public.route_rates
for each row execute function private.set_updated_at();

create table public.business_profiles (
  tenant_id uuid primary key references public.tenants(id) on delete cascade,
  legal_name text not null check (length(trim(legal_name)) between 1 and 160),
  arabic_legal_name text,
  trn text,
  trade_licence text,
  address text,
  city text,
  country text not null default 'United Arab Emirates',
  phone text,
  email text,
  -- 0xFF11B2F3 = 4279350003 (app's primary "Sky"). PostgreSQL integer is signed 32-bit, so bigint is required.
  brand_color bigint not null default 4279350003,
  footer text,
  payment_instructions text,
  invoice_prefix text not null default 'INV',
  use_custom_letterhead boolean not null default false,
  -- ponytail: local device path remains until tenant-scoped Storage branding is implemented. See ARCHITECTURE.md §10, Branding storage.
  letterhead_path text,
  letterhead_margin_top_mm numeric not null default 55,
  letterhead_margin_bottom_mm numeric not null default 25,
  letterhead_margin_left_mm numeric not null default 20,
  letterhead_margin_right_mm numeric not null default 20,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger business_profiles_set_updated_at
before update on public.business_profiles
for each row execute function private.set_updated_at();

alter table public.vehicles enable row level security;
alter table public.vehicles force row level security;
alter table public.drivers enable row level security;
alter table public.drivers force row level security;
alter table public.agreements enable row level security;
alter table public.agreements force row level security;
alter table public.route_rates enable row level security;
alter table public.route_rates force row level security;
alter table public.business_profiles enable row level security;
alter table public.business_profiles force row level security;

create policy vehicles_select_member
on public.vehicles for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = vehicles.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy vehicles_insert_master_data
on public.vehicles for insert
to authenticated
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy vehicles_update_master_data
on public.vehicles for update
to authenticated
using (private.has_access_pack(tenant_id, 'master_data'))
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy drivers_select_member
on public.drivers for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = drivers.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy drivers_insert_master_data
on public.drivers for insert
to authenticated
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy drivers_update_master_data
on public.drivers for update
to authenticated
using (private.has_access_pack(tenant_id, 'master_data'))
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy agreements_select_member
on public.agreements for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = agreements.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy agreements_insert_master_data
on public.agreements for insert
to authenticated
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy agreements_update_master_data
on public.agreements for update
to authenticated
using (private.has_access_pack(tenant_id, 'master_data'))
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy route_rates_select_member
on public.route_rates for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = route_rates.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy route_rates_insert_master_data
on public.route_rates for insert
to authenticated
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy route_rates_update_master_data
on public.route_rates for update
to authenticated
using (private.has_access_pack(tenant_id, 'master_data'))
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy business_profiles_select_member
on public.business_profiles for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = business_profiles.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy business_profiles_insert_owner
on public.business_profiles for insert
to authenticated
with check (private.is_tenant_owner(tenant_id));

create policy business_profiles_update_owner
on public.business_profiles for update
to authenticated
using (private.is_tenant_owner(tenant_id))
with check (private.is_tenant_owner(tenant_id));

revoke all on public.vehicles from anon, authenticated;
revoke all on public.drivers from anon, authenticated;
revoke all on public.agreements from anon, authenticated;
revoke all on public.route_rates from anon, authenticated;
revoke all on public.business_profiles from anon, authenticated;

grant select, insert, update on public.vehicles to authenticated;
grant select, insert, update on public.drivers to authenticated;
grant select, insert, update on public.agreements to authenticated;
grant select, insert, update on public.route_rates to authenticated;
grant select, insert, update on public.business_profiles to authenticated;
