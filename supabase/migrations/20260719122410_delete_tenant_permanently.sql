-- Permanent tenant offboarding for offboard_tenant.js. Most tenant-scoped
-- tables are "on delete restrict" against tenants by design, so a plain
-- `delete from tenants` fails the moment any child row exists. This deletes
-- every child table in FK-safe order inside one transaction (security
-- definer runs as the migration owner, which bypasses RLS/force RLS), so a
-- failure partway through rolls back instead of leaving a half-deleted
-- tenant. Every table is deleted explicitly -- ON DELETE CASCADE is NOT
-- relied on, because session_replication_role = replica (below) also
-- suppresses cascade propagation, not just user triggers.
create or replace function public.delete_tenant_permanently(p_tenant_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Issued invoices/settlements are protected by an immutability trigger
  -- (private.money_immutable_row) that rejects UPDATE/DELETE once status
  -- isn't 'draft' -- correct for normal app use (corrections = void +
  -- reissue), but a full tenant purge is a different operation. Disabling
  -- triggers for this transaction only (auto-reverts at commit) skips that
  -- guard, along with the updated_at/reference triggers, none of which
  -- matter for a delete.
  set local session_replication_role = replica;

  delete from public.payment_allocations where tenant_id = p_tenant_id;
  delete from public.settlement_lines where tenant_id = p_tenant_id;
  delete from public.invoice_lines where tenant_id = p_tenant_id;
  delete from public.work_order_charge_lines where tenant_id = p_tenant_id;
  delete from public.work_order_allocations where tenant_id = p_tenant_id;

  -- work_orders.invoice_id -> invoices has no explicit "on delete" action
  -- (defaults to restrict), and it's the one circular reference in the
  -- schema, so it has to be cleared before invoices can be deleted.
  update public.work_orders set invoice_id = null where tenant_id = p_tenant_id;

  delete from public.settlements where tenant_id = p_tenant_id;
  delete from public.payments where tenant_id = p_tenant_id;
  delete from public.invoices where tenant_id = p_tenant_id;
  delete from public.expenses where tenant_id = p_tenant_id;
  delete from public.work_orders where tenant_id = p_tenant_id;
  delete from public.agreements where tenant_id = p_tenant_id;
  delete from public.route_rates where tenant_id = p_tenant_id;
  delete from public.vehicles where tenant_id = p_tenant_id;
  delete from public.drivers where tenant_id = p_tenant_id;
  delete from public.parties where tenant_id = p_tenant_id;
  delete from public.business_profiles where tenant_id = p_tenant_id;
  delete from public.document_sequences where tenant_id = p_tenant_id;
  delete from public.member_access_packs
    where member_id in (select id from public.tenant_members where tenant_id = p_tenant_id);
  delete from public.tenant_members where tenant_id = p_tenant_id;
  delete from public.tenants where id = p_tenant_id;
end;
$$;

revoke all on function public.delete_tenant_permanently(uuid) from public, anon, authenticated;
grant execute on function public.delete_tenant_permanently(uuid) to service_role;
