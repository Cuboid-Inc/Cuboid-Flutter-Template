import 'package:cuboid_flutter_template/app/app.locator.dart';
import 'package:cuboid_flutter_template/core/cache/cache_entry.dart';
import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/expense.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/party.dart';
import 'package:cuboid_flutter_template/core/models/payment.dart';
import 'package:cuboid_flutter_template/core/models/period.dart';
import 'package:cuboid_flutter_template/core/models/settlement.dart';
import 'package:cuboid_flutter_template/core/models/vehicle.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';
import 'package:cuboid_flutter_template/core/result.dart';
import 'package:cuboid_flutter_template/core/supabase/supabase_guard.dart';
import 'package:cuboid_flutter_template/features/auth/data/auth_repository.dart';
import 'package:cuboid_flutter_template/features/home/data/home_repository.dart';
import 'package:cuboid_flutter_template/features/money/data/money_extensions.dart';
import 'package:cuboid_flutter_template/features/money/data/money_rows.dart';
import 'package:cuboid_flutter_template/features/more/data/vehicle_repository.dart';
import 'package:cuboid_flutter_template/features/parties/data/parties_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsRepository with RepositoryCacheMixin {
  ReportsRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _tenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<num>> profit(Period period) =>
      cached(_cache, 'profit_${_periodKey(period)}', () async {
        final result = await locator<HomeRepository>().fetchSummary(period);
        return switch (result) {
          Success(:final value) => Success(value.profit),
          Failure(:final failure) => Failure(failure),
        };
      });

  // One copy of the fold; it lives in HomeRepository (Reports already
  // depends on Home for expiries, never the reverse).
  static num profitFor({
    required Period period,
    required List<Invoice> invoices,
    required List<SupplierSettlement> settlements,
    required List<Expense> expenses,
  }) => HomeRepository.profitFor(
    period: period,
    invoices: invoices,
    settlements: settlements,
    expenses: expenses,
  );

  Future<Result<OwnershipSplit>> ownership(Period period) => cached(
    _cache,
    'ownership_${_periodKey(period)}',
    () => guard(() async {
      final row = (await Supabase.instance.client.rpc(
        'period_ownership_split',
        params: {
          'p_tenant_id': _tenantId(),
          'p_start': period.start.toIso8601String(),
          'p_end': period.end.toIso8601String(),
        },
      )).single;
      return OwnershipSplit(
        owned: row['owned'] as num,
        external: row['external'] as num,
      );
    }),
  );

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static OwnershipSplit ownershipFor(List<WorkOrder> workOrders) {
    num owned = 0;
    num external = 0;
    for (final work in workOrders) {
      if (work.allocations.any((a) => a.source == VehicleSource.supplier)) {
        external = roundMoney(external + work.net);
      } else {
        owned = roundMoney(owned + work.net);
      }
    }
    return OwnershipSplit(owned: owned, external: external);
  }

  Future<Result<List<VehicleProfit>>> vehicleProfit(Period period) => cached(
    _cache,
    'vehicle_profit_${_periodKey(period)}',
    () => guard(() async {
      final rows =
          await Supabase.instance.client.rpc(
                'vehicle_profit',
                params: {
                  'p_tenant_id': _tenantId(),
                  'p_start': period.start.toIso8601String(),
                  'p_end': period.end.toIso8601String(),
                },
              )
              as List<dynamic>;
      return rows
          .map(
            (row) => VehicleProfit(
              vehicleId: row['vehicle_id'] as String,
              revenue: row['revenue'] as num,
              payable: row['payable'] as num,
              expense: row['expense'] as num,
            ),
          )
          .toList();
    }),
  );

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static List<VehicleProfit> vehicleProfitFor({
    required List<Vehicle> vehicles,
    required List<WorkOrder> workOrders,
    required List<Expense> expenses,
  }) => [
    for (final vehicle in vehicles)
      VehicleProfit(
        vehicleId: vehicle.id,
        revenue: workOrders.fold<num>(0, (sum, work) {
          if (work.allocations.isEmpty) return sum;
          final share = roundMoney(work.net / work.allocations.length);
          final remainder = roundMoney(
            work.net - share * work.allocations.length,
          );
          final vehicleRevenue = [
            for (var index = 0; index < work.allocations.length; index++)
              if (work.allocations[index].vehicleId == vehicle.id)
                share + (index == 0 ? remainder : 0),
          ].fold<num>(0, (inner, amount) => roundMoney(inner + amount));
          return roundMoney(sum + vehicleRevenue);
        }),
        payable: workOrders.fold<num>(
          0,
          (sum, work) => roundMoney(
            sum +
                work.allocations
                    .where((allocation) => allocation.vehicleId == vehicle.id)
                    .fold<num>(
                      0,
                      (inner, allocation) =>
                          roundMoney(inner + allocation.supplierPayable),
                    ),
          ),
        ),
        expense: expenses
            .where((expense) => expense.vehicleId == vehicle.id)
            .fold<num>(0, (sum, expense) => roundMoney(sum + expense.net)),
      ),
  ];

  Future<Result<List<ExpenseTotal>>> expenseSummary(Period period) => cached(
    _cache,
    'expenses_${_periodKey(period)}',
    () => guard(() async {
      final rows =
          await Supabase.instance.client.rpc(
                'expense_summary',
                params: {
                  'p_tenant_id': _tenantId(),
                  'p_start': period.start.toIso8601String(),
                  'p_end': period.end.toIso8601String(),
                },
              )
              as List<dynamic>;
      return rows
          .map(
            (row) => ExpenseTotal(
              enumFromJson(row['category'] as String, ExpenseCategory.values),
              row['total'] as num,
            ),
          )
          .toList();
    }),
  );

  Future<Result<CashbookTotals>> cashbook(Period period) => cached(
    _cache,
    'cashbook_${_periodKey(period)}',
    () => guard(() async {
      final row = (await Supabase.instance.client.rpc(
        'cashbook_totals',
        params: {
          'p_tenant_id': _tenantId(),
          'p_start': period.start.toIso8601String(),
          'p_end': period.end.toIso8601String(),
        },
      )).single;
      return CashbookTotals(
        inAmount: row['in_amount'] as num,
        outAmount: row['out_amount'] as num,
      );
    }),
  );

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static CashbookTotals cashbookFor(List<Payment> payments) {
    num incoming = 0;
    num outgoing = 0;
    for (final payment in payments.where((payment) => payment.isCleared)) {
      if (payment.direction == PaymentDirection.incoming) {
        incoming = roundMoney(incoming + payment.amount);
      } else {
        outgoing = roundMoney(outgoing + payment.amount);
      }
    }
    return CashbookTotals(inAmount: incoming, outAmount: outgoing);
  }

  Future<Result<List<UnbilledWorkRow>>> unbilledWork(Period period) => cached(
    _cache,
    'unbilled_${_periodKey(period)}',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('unbilled_work')
          .select()
          .eq('tenant_id', _tenantId())
          .gte('date', period.start.toIso8601String())
          .lte('date', period.end.toIso8601String())
          .order('date');
      return rows.map(UnbilledWorkRowMapping.fromRow).toList();
    }),
  );

  Future<Result<List<UnpaidInvoiceRow>>> unpaidInvoices(Period period) =>
      cached(
        _cache,
        'unpaid_${_periodKey(period)}',
        () => guard(() async {
          final tenantId = _tenantId();
          final invoices = await Supabase.instance.client
              .from('invoices')
              .select('*, invoice_lines(*)')
              .eq('tenant_id', tenantId)
              .neq('status', InvoiceStatus.voided.toJson())
              .gte('issue_date', period.start.toIso8601String())
              .lte('issue_date', period.end.toIso8601String());
          final balances = await Supabase.instance.client
              .from('invoice_balances')
              .select('invoice_id, balance')
              .eq('tenant_id', tenantId);
          final balanceByInvoice = {
            for (final row in balances)
              row['invoice_id'] as String: roundMoney(row['balance'] as num),
          };
          return [
            for (final row in invoices)
              if ((balanceByInvoice[row['id'] as String] ?? 0) > 0)
                UnpaidInvoiceRow(
                  invoice: InvoiceRow.fromRow(row),
                  balance: balanceByInvoice[row['id'] as String]!,
                ),
          ];
        }),
      );

  Future<Result<List<ExpiringDocument>>> expiringDocuments(Period period) =>
      locator<HomeRepository>().fetchExpiringDocuments(from: period.start);

  Future<Result<List<StatementRow>>> statementRows(Period period) => cached(
    _cache,
    'statements_${_periodKey(period)}',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('statement_rows')
          .select()
          .eq('tenant_id', _tenantId())
          .gte('date', period.start.toIso8601String())
          .lte('date', period.end.toIso8601String())
          .order('date');
      return rows.map(StatementRowMapping.fromRow).toList();
    }),
  );

  Future<Result<List<Party>>> customers() async {
    final result = await locator<PartiesRepository>().fetchAll();
    return switch (result) {
      Success(:final value) => Success(
        value.where((party) => party.type != PartyType.supplier).toList(),
      ),
      Failure(:final failure) => Failure(failure),
    };
  }

  Future<Result<List<Vehicle>>> vehicles() =>
      locator<VehicleRepository>().fetchVehicles();

  Future<Result<List<int>>> availableYears() => cached(
    _cache,
    'available_years',
    () => guard(() async {
      final first = await Supabase.instance.client
          .from('work_orders')
          .select('date')
          .eq('tenant_id', _tenantId())
          .order('date')
          .limit(1);
      final minYear = first.isEmpty
          ? DateTime.now().year
          : DateTime.parse(first.first['date'] as String).year;
      return [
        for (var year = DateTime.now().year; year >= minYear; year--) year,
      ];
    }),
  );

  String _periodKey(Period period) =>
      '${period.start.toIso8601String()}_${period.end.toIso8601String()}';
}
