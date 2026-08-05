-- Reusable per-work-order net/vat/gross, unfiltered by status (unlike unbilled_work, which is
-- scoped to completed+unbilled only). Ownership split and vehicle profit both need every status.
create view public.work_order_totals with (security_invoker = true) as
select w.tenant_id, w.id as work_order_id, w.customer_id, w.date, w.status,
  round(coalesce(sum(round(l.quantity * l.unit_price - l.discount, 2)), 0), 2) as net,
  round(coalesce(sum(round(round(l.quantity * l.unit_price - l.discount, 2) * l.vat_rate / 100, 2)), 0), 2) as vat,
  round(
    coalesce(sum(round(l.quantity * l.unit_price - l.discount, 2)), 0)
    + coalesce(sum(round(round(l.quantity * l.unit_price - l.discount, 2) * l.vat_rate / 100, 2)), 0),
    2
  ) as gross
from public.work_orders w
left join public.work_order_charge_lines l on l.work_order_id = w.id
group by w.tenant_id, w.id, w.customer_id, w.date, w.status;

create or replace function public.home_totals(
  p_tenant_id uuid, p_start date, p_end date
)
returns table (
  billed numeric(14,2), revenue numeric(14,2), operating_costs numeric(14,2),
  received numeric(14,2), paid_out numeric(14,2), cash_flow numeric(14,2), profit numeric(14,2),
  total_receivables numeric(14,2), total_payables numeric(14,2),
  receivable_count integer, payable_count integer,
  unbilled_count integer, pending_cheque_count integer
)
language sql security invoker stable as $$
  with period_invoices as (
    select * from public.invoices
    where tenant_id = p_tenant_id and status <> 'voided' and issue_date between p_start and p_end
  ),
  period_settlements as (
    select * from public.settlements
    where tenant_id = p_tenant_id and status <> 'voided' and period_end between p_start and p_end
  ),
  period_expenses as (
    select * from public.expenses where tenant_id = p_tenant_id and date between p_start and p_end
  ),
  period_payments as (
    select * from public.payments where tenant_id = p_tenant_id and date between p_start and p_end
  ),
  cleared_period_payments as (
    select * from period_payments where method <> 'cheque' or cheque_state = 'cleared'
  )
  select
    round(coalesce((select sum(gross) from period_invoices), 0), 2),
    round(coalesce((select sum(net) from period_invoices), 0), 2),
    round(
      coalesce((select sum(total) from period_settlements), 0)
      + coalesce((select sum(net) from period_expenses), 0), 2
    ),
    round(coalesce((select sum(amount) from cleared_period_payments where direction = 'incoming'), 0), 2),
    round(coalesce((select sum(amount) from cleared_period_payments where direction = 'outgoing'), 0), 2),
    round(
      coalesce((select sum(amount) from cleared_period_payments where direction = 'incoming'), 0)
      - coalesce((select sum(amount) from cleared_period_payments where direction = 'outgoing'), 0), 2
    ),
    round(
      coalesce((select sum(net) from period_invoices), 0)
      - coalesce((select sum(total) from period_settlements), 0)
      - coalesce((select sum(net) from period_expenses), 0), 2
    ),
    round(coalesce((select sum(balance) from public.invoice_balances where tenant_id = p_tenant_id), 0), 2),
    round(coalesce((select sum(balance) from public.settlement_balances where tenant_id = p_tenant_id), 0), 2),
    (select count(*)::integer from public.invoice_balances where tenant_id = p_tenant_id and balance > 0),
    (select count(*)::integer from public.settlement_balances where tenant_id = p_tenant_id and balance > 0),
    (select count(*)::integer from public.unbilled_work where tenant_id = p_tenant_id),
    (select count(*)::integer from period_payments where method = 'cheque' and cheque_state = 'received');
$$;

create or replace function public.period_ownership_split(
  p_tenant_id uuid, p_start date, p_end date
)
returns table (owned numeric(14,2), external numeric(14,2))
language sql security invoker stable as $$
  with period_work as (
    select t.work_order_id, t.net from public.work_order_totals t
    where t.tenant_id = p_tenant_id and t.date between p_start and p_end
  ),
  classified as (
    -- LEFT JOIN, not inner: a work order with zero allocations counts as owned (matches the
    -- Dart fold's `.any(...)` on an empty list, which is false, falling to the owned branch).
    select pw.work_order_id, pw.net, coalesce(bool_or(a.source = 'supplier'), false) as has_supplier
    from period_work pw
    left join public.work_order_allocations a on a.work_order_id = pw.work_order_id
    group by pw.work_order_id, pw.net
  )
  select
    round(coalesce(sum(net) filter (where not has_supplier), 0), 2),
    round(coalesce(sum(net) filter (where has_supplier), 0), 2)
  from classified;
$$;

create or replace function public.vehicle_profit(
  p_tenant_id uuid, p_start date, p_end date
)
returns table (vehicle_id uuid, revenue numeric(14,2), payable numeric(14,2), expense numeric(14,2))
language sql security invoker stable as $$
  with period_work as (
    select t.work_order_id, t.net from public.work_order_totals t
    where t.tenant_id = p_tenant_id and t.date between p_start and p_end
  ),
  -- Work orders with zero allocations are excluded by this inner join, matching the Dart fold's
  -- `if (work.allocations.isEmpty) return sum;` skip.
  alloc as (
    select a.id, a.work_order_id, a.vehicle_id, a.supplier_payable,
      row_number() over (partition by a.work_order_id order by a.id) as rn,
      count(*) over (partition by a.work_order_id) as alloc_count
    from public.work_order_allocations a
    join period_work pw on pw.work_order_id = a.work_order_id
  ),
  -- Revenue splits evenly across a work order's allocations; the remainder from that division
  -- goes entirely to the first allocation (rn = 1, ordered by allocation id) — this exactly
  -- mirrors the Dart fold's `index == 0 ? remainder : 0`. Get this bit right; it's the one place
  -- naive per-row division would silently drop or duplicate a cent.
  revenue_share as (
    select a.vehicle_id, a.rn, a.supplier_payable,
      round(pw.net / a.alloc_count, 2) as share,
      round(pw.net - round(pw.net / a.alloc_count, 2) * a.alloc_count, 2) as remainder
    from alloc a join period_work pw on pw.work_order_id = a.work_order_id
  ),
  revenue_agg as (
    select vehicle_id,
      round(sum(share + case when rn = 1 then remainder else 0 end), 2) as revenue,
      round(sum(supplier_payable), 2) as payable
    from revenue_share group by vehicle_id
  ),
  expense_agg as (
    select vehicle_id, round(sum(net), 2) as expense from public.expenses
    where tenant_id = p_tenant_id and date between p_start and p_end and vehicle_id is not null
    group by vehicle_id
  )
  select v.id, round(coalesce(ra.revenue, 0), 2), round(coalesce(ra.payable, 0), 2), round(coalesce(ea.expense, 0), 2)
  from public.vehicles v
  left join revenue_agg ra on ra.vehicle_id = v.id
  left join expense_agg ea on ea.vehicle_id = v.id
  where v.tenant_id = p_tenant_id and v.is_archived = false;
$$;

create or replace function public.expense_summary(
  p_tenant_id uuid, p_start date, p_end date
)
returns table (category text, total numeric(14,2))
language sql security invoker stable as $$
  select category, round(sum(net), 2) from public.expenses
  where tenant_id = p_tenant_id and date between p_start and p_end
  group by category;
$$;

create or replace function public.cashbook_totals(
  p_tenant_id uuid, p_start date, p_end date
)
returns table (in_amount numeric(14,2), out_amount numeric(14,2))
language sql security invoker stable as $$
  select
    round(coalesce(sum(amount) filter (where direction = 'incoming'), 0), 2),
    round(coalesce(sum(amount) filter (where direction = 'outgoing'), 0), 2)
  from public.payments
  where tenant_id = p_tenant_id and date between p_start and p_end
    and (method <> 'cheque' or cheque_state = 'cleared');
$$;

create or replace function public.more_menu_counts(p_tenant_id uuid)
returns table (
  customers integer, suppliers integer,
  vehicles_active integer, vehicles_external integer,
  drivers integer, agreements integer, route_rates integer, staff integer
)
language sql security invoker stable as $$
  select
    (select count(*)::integer from public.parties
      where tenant_id = p_tenant_id and is_archived = false and type = 'customer'),
    (select count(*)::integer from public.parties
      where tenant_id = p_tenant_id and is_archived = false and type = 'supplier'),
    (select count(*)::integer from public.vehicles
      where tenant_id = p_tenant_id and is_archived = false),
    (select count(*)::integer from public.vehicles
      where tenant_id = p_tenant_id and is_archived = false and ownership = 'external'),
    (select count(*)::integer from public.drivers
      where tenant_id = p_tenant_id and is_archived = false),
    (select count(*)::integer from public.agreements
      where tenant_id = p_tenant_id and is_archived = false),
    (select count(*)::integer from public.route_rates
      where tenant_id = p_tenant_id and is_archived = false),
    (select count(*)::integer from public.tenant_members
      where tenant_id = p_tenant_id);
$$;
-- more_menu_counts is security invoker: a non-owner caller's RLS already restricts what they can
-- see in tenant_members, so no app-level owner check belongs inside this function.

revoke all on public.work_order_totals from anon, authenticated;
grant select on public.work_order_totals to authenticated;

revoke all on function public.home_totals(uuid, date, date),
  public.period_ownership_split(uuid, date, date),
  public.vehicle_profit(uuid, date, date),
  public.expense_summary(uuid, date, date),
  public.cashbook_totals(uuid, date, date),
  public.more_menu_counts(uuid)
  from public, anon;
grant execute on function public.home_totals(uuid, date, date),
  public.period_ownership_split(uuid, date, date),
  public.vehicle_profit(uuid, date, date),
  public.expense_summary(uuid, date, date),
  public.cashbook_totals(uuid, date, date),
  public.more_menu_counts(uuid)
  to authenticated;
