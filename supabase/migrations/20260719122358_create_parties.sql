create or replace function private.has_access_pack(check_tenant_id uuid, check_pack text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.tenant_members
    where tenant_id = check_tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
      and (
        role = 'owner'
        or exists (
          select 1
          from public.member_access_packs
          where member_id = tenant_members.id
            and pack = check_pack
        )
      )
  );
$$;

revoke all on function private.has_access_pack(uuid, text) from public, anon;
grant execute on function private.has_access_pack(uuid, text) to authenticated;

create table public.parties (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  name text not null check (length(trim(name)) between 1 and 160),
  type text not null check (type in ('customer', 'supplier')),
  address text,
  city text,
  country text not null default 'United Arab Emirates',
  trn text,
  contact_person text,
  phone text,
  email text,
  payment_terms text not null default 'on_receipt' check (
    payment_terms in ('on_receipt', 'net_7', 'net_15', 'net_30', 'net_45', 'net_60')
  ),
  notes text,
  is_archived boolean not null default false,
  created_by uuid references auth.users(id) on delete set null default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- referenced by tenant-scoped composite foreign keys in later migrations
  unique (tenant_id, id)
);

create index parties_tenant_id_idx on public.parties (tenant_id);

create trigger parties_set_updated_at
before update on public.parties
for each row execute function private.set_updated_at();

alter table public.parties enable row level security;
alter table public.parties force row level security;

create policy parties_select_member
on public.parties for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where tenant_id = parties.tenant_id
      and user_id = (select auth.uid())
      and status = 'active'
  )
);

create policy parties_insert_master_data
on public.parties for insert
to authenticated
with check (private.has_access_pack(tenant_id, 'master_data'));

create policy parties_update_master_data
on public.parties for update
to authenticated
using (private.has_access_pack(tenant_id, 'master_data'))
with check (private.has_access_pack(tenant_id, 'master_data'));

revoke all on public.parties from anon, authenticated;
grant select, insert, update on public.parties to authenticated;
