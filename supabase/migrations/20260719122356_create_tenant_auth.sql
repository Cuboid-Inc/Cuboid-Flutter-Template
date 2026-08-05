create schema if not exists private;

create table public.tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 160),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (length(trim(display_name)) between 1 and 120),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.tenant_members (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null check (length(trim(display_name)) between 1 and 120),
  email text not null check (
    email = lower(trim(email))
    and position('@' in email) > 1
  ),
  role text not null default 'staff' check (role in ('owner', 'staff')),
  status text not null default 'invited'
    check (status in ('invited', 'active', 'suspended')),
  invited_by uuid references auth.users(id) on delete set null,
  invited_at timestamptz,
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (tenant_id, email),
  unique (tenant_id, user_id),
  -- ponytail: MVP has one tenant per login; add tenant selection before relaxing this.
  unique (user_id)
);

create table public.member_access_packs (
  member_id uuid not null references public.tenant_members(id) on delete cascade,
  pack text not null check (pack in ('operations', 'master_data', 'money', 'reports')),
  created_at timestamptz not null default now(),
  primary key (member_id, pack)
);

create index tenant_members_tenant_id_idx
  on public.tenant_members (tenant_id);
create index tenant_members_invited_by_idx
  on public.tenant_members (invited_by)
  where invited_by is not null;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger tenants_set_updated_at
before update on public.tenants
for each row execute function private.set_updated_at();

create trigger user_profiles_set_updated_at
before update on public.user_profiles
for each row execute function private.set_updated_at();

create trigger tenant_members_set_updated_at
before update on public.tenant_members
for each row execute function private.set_updated_at();

create or replace function private.is_tenant_owner(check_tenant_id uuid)
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
      and role = 'owner'
      and status = 'active'
  );
$$;

create or replace function public.accept_invitation()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  accepted boolean;
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required.' using errcode = '42501';
  end if;

  update public.tenant_members
  set status = 'active', accepted_at = now(), updated_at = now()
  where user_id = (select auth.uid())
    and status = 'invited'
  returning true into accepted;

  if accepted is not true then
    raise exception 'Invitation unavailable.' using errcode = 'P0001';
  end if;

  return true;
end;
$$;

alter table public.tenants enable row level security;
alter table public.tenants force row level security;
alter table public.user_profiles enable row level security;
alter table public.user_profiles force row level security;
alter table public.tenant_members enable row level security;
alter table public.tenant_members force row level security;
alter table public.member_access_packs enable row level security;
alter table public.member_access_packs force row level security;

create policy tenants_select_member
on public.tenants for select
to authenticated
using (
  is_active
  and exists (
    select 1
    from public.tenant_members
    where tenant_id = tenants.id
      and user_id = (select auth.uid())
      and status in ('invited', 'active')
  )
);

create policy user_profiles_select_self
on public.user_profiles for select
to authenticated
using ((select auth.uid()) = user_id);

create policy tenant_members_select_self_or_owner
on public.tenant_members for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_tenant_owner(tenant_id))
);

create policy member_access_packs_select_self_or_owner
on public.member_access_packs for select
to authenticated
using (
  exists (
    select 1
    from public.tenant_members
    where id = member_id
      and (
        user_id = (select auth.uid())
        or (select private.is_tenant_owner(tenant_id))
      )
  )
);

revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

revoke all on function private.set_updated_at() from public, anon, authenticated;
revoke all on function private.is_tenant_owner(uuid) from public, anon;
grant execute on function private.is_tenant_owner(uuid) to authenticated;

revoke all on function public.accept_invitation() from public, anon;
grant execute on function public.accept_invitation() to authenticated;

revoke all on public.tenants from anon, authenticated;
revoke all on public.user_profiles from anon, authenticated;
revoke all on public.tenant_members from anon, authenticated;
revoke all on public.member_access_packs from anon, authenticated;

grant select on public.tenants to authenticated;
grant select on public.user_profiles to authenticated;
grant select on public.tenant_members to authenticated;
grant select on public.member_access_packs to authenticated;
