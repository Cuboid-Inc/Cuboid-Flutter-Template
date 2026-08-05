-- Atomic replacement for the 3 sequential inserts + manual rollback chain
-- in the invite-staff Edge Function. Only callable by service_role since it
-- skips the owner-permission check (that stays in the Edge Function, run
-- against the caller's own membership before the auth user is created).
create or replace function public.create_invited_member(
  p_tenant_id uuid,
  p_user_id uuid,
  p_display_name text,
  p_email text,
  p_invited_by uuid,
  p_packs text[]
)
returns uuid
language plpgsql
set search_path = ''
as $$
declare
  v_member_id uuid;
begin
  insert into public.tenant_members (
    tenant_id, user_id, display_name, email, role, status, invited_by, invited_at
  )
  values (
    p_tenant_id, p_user_id, p_display_name, p_email, 'staff', 'invited', p_invited_by, now()
  )
  returning id into v_member_id;

  insert into public.member_access_packs (member_id, pack)
  select v_member_id, pack from unnest(p_packs) as pack;

  insert into public.user_profiles (user_id, display_name)
  values (p_user_id, p_display_name);

  return v_member_id;
end;
$$;

revoke execute on function public.create_invited_member from public;
grant execute on function public.create_invited_member to service_role;
