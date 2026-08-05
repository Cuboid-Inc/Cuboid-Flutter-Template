import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/driver.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/report_models.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/models/vehicle.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/more/data/driver_repository.dart';
import 'package:fleetgo/features/more/data/vehicle_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeSummary {
  const HomeSummary({
    required this.period,
    required this.profit,
    required this.billed,
    required this.revenue,
    required this.operatingCosts,
    required this.received,
    required this.paidOut,
    required this.cashFlow,
    required this.totalReceivables,
    required this.totalPayables,
    required this.receivableCount,
    required this.payableCount,
    required this.unbilledCount,
    required this.pendingChequeCount,
    required this.expiries,
  });

  final Period period;
  final num profit;
  final num billed;
  final num revenue;
  final num operatingCosts;
  final num received;
  final num paidOut;
  final num cashFlow;
  final num totalReceivables;
  final num totalPayables;
  final int receivableCount;
  final int payableCount;
  final int unbilledCount;
  final int pendingChequeCount;
  final List<ExpiringDocument> expiries;
}

class HomeRepository with RepositoryCacheMixin {
  HomeRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};

  String _tenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<HomeSummary>> fetchSummary([Period? period]) {
    final selected = period ?? Period.thisMonth();
    return cached(
      _cache,
      'summary_${selected.start.toIso8601String()}_${selected.end.toIso8601String()}',
      () async {
        final totalsResult = await guard(() async {
          final rows = await Supabase.instance.client.rpc(
            'home_totals',
            params: {
              'p_tenant_id': _tenantId(),
              'p_start': selected.start.toIso8601String(),
              'p_end': selected.end.toIso8601String(),
            },
          );
          return rows.single;
        });
        if (totalsResult case Failure(:final failure)) {
          return Failure(failure);
        }
        final row = (totalsResult as Success).value;
        final expiringResult = await _readExpiringDocuments(selected.start);
        if (expiringResult case Failure(:final failure)) {
          return Failure(failure);
        }
        return Success(
          HomeSummary(
            period: selected,
            profit: row['profit'] as num,
            billed: row['billed'] as num,
            revenue: row['revenue'] as num,
            operatingCosts: row['operating_costs'] as num,
            received: row['received'] as num,
            paidOut: row['paid_out'] as num,
            cashFlow: row['cash_flow'] as num,
            totalReceivables: row['total_receivables'] as num,
            totalPayables: row['total_payables'] as num,
            receivableCount: row['receivable_count'] as int,
            payableCount: row['payable_count'] as int,
            unbilledCount: row['unbilled_count'] as int,
            pendingChequeCount: row['pending_cheque_count'] as int,
            expiries: (expiringResult as Success<List<ExpiringDocument>>).value,
          ),
        );
      },
    );
  }

  Future<Result<List<ExpiringDocument>>> fetchExpiringDocuments({
    DateTime? from,
  }) {
    final start = from ?? Period.thisMonth().start;
    return cached(
      _cache,
      'expiries_${start.toIso8601String()}',
      () => _readExpiringDocuments(start),
    );
  }

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static HomeTotals homeTotalsFor({
    required Period period,
    required List<Invoice> invoices,
    required List<SupplierSettlement> settlements,
    required List<Payment> payments,
    required List<Expense> expenses,
  }) {
    final billed = invoices
        .where(
          (invoice) =>
              invoice.status != InvoiceStatus.voided &&
              period.contains(invoice.issueDate),
        )
        .fold<num>(0, (sum, invoice) => roundMoney(sum + invoice.gross));
    final revenue = invoices
        .where(
          (invoice) =>
              invoice.status != InvoiceStatus.voided &&
              period.contains(invoice.issueDate),
        )
        .fold<num>(0, (sum, invoice) => roundMoney(sum + invoice.net));
    final operatingCosts = roundMoney(
      settlements
              .where(
                (settlement) =>
                    settlement.status != SettlementStatus.voided &&
                    period.contains(settlement.periodEnd),
              )
              .fold<num>(
                0,
                (sum, settlement) => roundMoney(sum + settlement.total),
              ) +
          expenses
              .where((expense) => period.contains(expense.date))
              .fold<num>(0, (sum, expense) => roundMoney(sum + expense.net)),
    );
    final cashbook = _cashbookFor(period, payments);
    return HomeTotals(
      billed: billed,
      revenue: revenue,
      operatingCosts: operatingCosts,
      received: cashbook.inAmount,
      paidOut: cashbook.outAmount,
    );
  }

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static num profitFor({
    required Period period,
    required List<Invoice> invoices,
    required List<SupplierSettlement> settlements,
    required List<Expense> expenses,
  }) {
    final revenue = invoices
        .where(
          (invoice) =>
              invoice.status != InvoiceStatus.voided &&
              period.contains(invoice.issueDate),
        )
        .fold<num>(0, (sum, invoice) => roundMoney(sum + invoice.net));
    final payables = settlements
        .where(
          (settlement) =>
              settlement.status != SettlementStatus.voided &&
              period.contains(settlement.periodEnd),
        )
        .fold<num>(0, (sum, settlement) => roundMoney(sum + settlement.total));
    final costs = expenses
        .where((expense) => period.contains(expense.date))
        .fold<num>(0, (sum, expense) => roundMoney(sum + expense.net));
    return roundMoney(revenue - payables - costs);
  }

  static CashbookTotals _cashbookFor(Period period, List<Payment> payments) {
    num incoming = 0;
    num outgoing = 0;
    for (final payment in payments.where(
      (payment) => payment.isCleared && period.contains(payment.date),
    )) {
      if (payment.direction == PaymentDirection.incoming) {
        incoming = roundMoney(incoming + payment.amount);
      } else {
        outgoing = roundMoney(outgoing + payment.amount);
      }
    }
    return CashbookTotals(inAmount: incoming, outAmount: outgoing);
  }

  // ponytail: client-side fold retained for live SQL validation; remove after the next wave.
  // ignore: unused_element
  static num _sumBalances(List<dynamic> rows) => rows.fold<num>(
    0,
    (sum, row) => roundMoney(sum + (row['balance'] as num)),
  );

  // ponytail: client-side fold, move to a SQL view if a tenant outgrows single-fetch periods.
  static Future<Result<List<ExpiringDocument>>> _readExpiringDocuments(
    DateTime start,
  ) async {
    final vehiclesResult = await locator<VehicleRepository>().fetchVehicles();
    if (vehiclesResult case Failure(:final failure)) return Failure(failure);
    final driversResult = await locator<DriverRepository>().fetchDrivers();
    if (driversResult case Failure(:final failure)) return Failure(failure);
    final vehicles = (vehiclesResult as Success<List<Vehicle>>).value;
    final drivers = (driversResult as Success<List<Driver>>).value;

    final end = start.add(const Duration(days: 30));
    final rows = <ExpiringDocument>[];
    void addRow(
      String ownerId,
      String name,
      String ownerType,
      DateTime? expiry,
      String kind,
    ) {
      if (expiry == null) return;
      if (expiry.isBefore(start) || expiry.isAfter(end)) return;
      rows.add(
        ExpiringDocument(
          ownerId: ownerId,
          ownerName: name,
          ownerType: ownerType,
          kind: kind,
          expiresOn: expiry,
        ),
      );
    }

    for (final vehicle in vehicles) {
      addRow(
        vehicle.id,
        vehicle.label,
        'vehicle',
        vehicle.registrationExpiry,
        'Registration',
      );
      addRow(
        vehicle.id,
        vehicle.label,
        'vehicle',
        vehicle.insuranceExpiry,
        'Insurance',
      );
      addRow(
        vehicle.id,
        vehicle.label,
        'vehicle',
        vehicle.inspectionExpiry,
        'Inspection',
      );
    }
    for (final driver in drivers) {
      addRow(driver.id, driver.name, 'driver', driver.licenceExpiry, 'Licence');
      addRow(
        driver.id,
        driver.name,
        'driver',
        driver.identityExpiry,
        'Emirates ID',
      );
    }
    rows.sort((a, b) => a.expiresOn.compareTo(b.expiresOn));
    return Success(rows);
  }
}
