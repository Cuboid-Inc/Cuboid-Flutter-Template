import 'package:fleetgo/app/app.locator.dart';
import 'package:fleetgo/core/cache/cache_entry.dart';
import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/paginated_result.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/period.dart';
import 'package:fleetgo/core/models/settlement.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/result.dart';
import 'package:fleetgo/core/supabase/supabase_guard.dart';
import 'package:fleetgo/features/auth/data/auth_repository.dart';
import 'package:fleetgo/features/money/data/money_extensions.dart';
import 'package:fleetgo/features/money/data/money_rows.dart';
import 'package:fleetgo/main.logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoneyBalances {
  const MoneyBalances({
    required this.invoices,
    required this.settlements,
    required this.parties,
  });

  final Map<String, num> invoices;
  final Map<String, num> settlements;
  final Map<String, num> parties;
}

class MoneyRepository with RepositoryCacheMixin {
  MoneyRepository([AuthRepository? auth])
    : _auth = auth ?? locator<AuthRepository>();

  final AuthRepository _auth;
  final _cache = <String, CacheEntry<Object>>{};
  final _logger = AppLogger('MoneyRepository');

  String _tenantId() {
    final tenantId = _auth.currentAccess?.tenantId;
    if (tenantId == null) throw StateError('No active tenant.');
    return tenantId;
  }

  void invalidateCache() => clearCache(_cache);

  Future<Result<List<Invoice>>> fetchInvoices() => cached(
    _cache,
    'invoices_all',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('invoices')
          .select('*, invoice_lines(*)')
          .eq('tenant_id', _tenantId())
          .order('issue_date', ascending: false)
          .order('number', ascending: false);
      return rows.map(InvoiceRow.fromRow).toList();
    }),
  );

  Future<Result<List<SupplierSettlement>>> fetchSettlements() => cached(
    _cache,
    'settlements_all',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('settlements')
          .select('*, settlement_lines(*)')
          .eq('tenant_id', _tenantId())
          .order('period_end', ascending: false)
          .order('number', ascending: false);
      return rows.map(SettlementRow.fromRow).toList();
    }),
  );

  Future<Result<List<Payment>>> fetchPayments() => cached(
    _cache,
    'payments_all',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('payments')
          .select('*, payment_allocations(*)')
          .eq('tenant_id', _tenantId())
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      return rows.map(PaymentRow.fromRow).toList();
    }),
  );

  Future<Result<List<Expense>>> fetchExpenses() => cached(
    _cache,
    'expenses_all',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('expenses')
          .select()
          .eq('tenant_id', _tenantId())
          .order('date', ascending: false)
          .order('created_at', ascending: false);
      return rows.map(ExpenseRow.fromRow).toList();
    }),
  );

  Future<Result<PaginatedResult<Invoice>>> fetchInvoicesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
    Period? period,
  }) => _page(
    'invoices_page_${pageNumber}_${pageSize}_${search ?? ''}_${_periodKey(period)}',
    'invoices',
    '*, invoice_lines(*)',
    pageNumber,
    pageSize,
    InvoiceRow.fromRow,
    ['issue_date', 'number'],
    search: search,
    searchColumns: const ['number', 'buyer_name'],
    period: period,
  );

  Future<Result<PaginatedResult<SupplierSettlement>>> fetchSettlementsPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
    Period? period,
  }) => _page(
    'settlements_page_${pageNumber}_${pageSize}_${search ?? ''}_${_periodKey(period)}',
    'settlements',
    '*, settlement_lines(*)',
    pageNumber,
    pageSize,
    SettlementRow.fromRow,
    ['period_end', 'number'],
    search: search,
    searchColumns: const ['number'],
    period: period,
  );

  Future<Result<PaginatedResult<Payment>>> fetchPaymentsPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
    Period? period,
  }) => _page(
    'payments_page_${pageNumber}_${pageSize}_${search ?? ''}_${_periodKey(period)}',
    'payments',
    '*, payment_allocations(*)',
    pageNumber,
    pageSize,
    PaymentRow.fromRow,
    ['date', 'created_at'],
    search: search,
    searchColumns: const ['reference', 'notes'],
    period: period,
  );

  Future<Result<PaginatedResult<Expense>>> fetchExpensesPage({
    required int pageNumber,
    int pageSize = 50,
    String? search,
    Period? period,
  }) => _page(
    'expenses_page_${pageNumber}_${pageSize}_${search ?? ''}_${_periodKey(period)}',
    'expenses',
    '*',
    pageNumber,
    pageSize,
    ExpenseRow.fromRow,
    ['date', 'created_at'],
    search: search,
    searchColumns: const ['payee', 'reference', 'notes'],
    period: period,
  );

  String _periodKey(Period? period) =>
      period == null
          ? ''
          : '${period.start.toIso8601String()}_${period.end.toIso8601String()}';

  Future<Result<PaginatedResult<T>>> _page<T>(
    String key,
    String table,
    String columns,
    int pageNumber,
    int pageSize,
    T Function(Map<String, dynamic>) map,
    List<String> orderColumns, {
    String? search,
    List<String> searchColumns = const [],
    Period? period,
  }) => cached(
    _cache,
    key,
    () => guard(() async {
      final start = (pageNumber - 1) * pageSize;
      var query = Supabase.instance.client
          .from(table)
          .select(columns)
          .eq('tenant_id', _tenantId());
      if (period != null) {
        query = query
            .gte(orderColumns[0], period.start.toIso8601String())
            .lte(orderColumns[0], period.end.toIso8601String());
      }
      if (search?.isNotEmpty == true && searchColumns.isNotEmpty) {
        query = query.or(
          searchColumns.map((c) => '$c.ilike.%$search%').join(','),
        );
      }
      final response = await query
          .order(orderColumns[0], ascending: false)
          .order(orderColumns[1], ascending: false)
          .range(start, start + pageSize - 1)
          .count(CountOption.exact);
      return PaginatedResult(
        items: response.data.map(map).toList(),
        pageNumber: pageNumber,
        pageSize: pageSize,
        totalRecords: response.count,
      );
    }),
  );

  Future<Result<List<UnbilledWorkRow>>> fetchUnbilledWork() => cached(
    _cache,
    'unbilled_work',
    () => guard(() async {
      final rows = await Supabase.instance.client
          .from('unbilled_work')
          .select()
          .eq('tenant_id', _tenantId())
          .order('date', ascending: false);
      return rows.map(UnbilledWorkRowMapping.fromRow).toList();
    }),
  );

  Future<Result<MoneyBalances>> fetchBalances() => cached(
    _cache,
    'balances',
    () => guard(() async {
      final tenantId = _tenantId();
      final client = Supabase.instance.client;
      final invoices = await client
          .from('invoice_balances')
          .select('invoice_id, balance')
          .eq('tenant_id', tenantId);
      final settlements = await client
          .from('settlement_balances')
          .select('settlement_id, balance')
          .eq('tenant_id', tenantId);
      final parties = await client
          .from('party_balances')
          .select('party_id, balance')
          .eq('tenant_id', tenantId);
      return MoneyBalances(
        invoices: {
          for (final row in invoices)
            row['invoice_id'] as String: roundMoney(row['balance'] as num),
        },
        settlements: {
          for (final row in settlements)
            row['settlement_id'] as String: roundMoney(row['balance'] as num),
        },
        parties: {
          for (final row in parties)
            row['party_id'] as String: roundMoney(row['balance'] as num),
        },
      );
    }),
  );

  Future<Result<List<StatementRow>>> statementRows(Period period) => cached(
    _cache,
    'statements_${period.start.toIso8601String()}_${period.end.toIso8601String()}',
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

  Future<Result<Invoice>> issueInvoice(Invoice invoice) => guard(() async {
    final id = await _rpcId('issue_invoice', {
      'payload': invoice.toIssuePayload(),
    });
    invalidateCache();
    final issuedInvoice = await _invoiceById(id);
    _logger.i('Invoice issued');
    return issuedInvoice;
  });

  Future<Result<void>> voidInvoice(String id, {String? reason}) =>
      guard(() async {
        await Supabase.instance.client.rpc(
          'void_invoice',
          params: {'p_id': id, 'p_reason': reason},
        );
        invalidateCache();
        _logger.i('Invoice voided');
      });

  Future<Result<SupplierSettlement>> issueSettlement(
    SupplierSettlement settlement,
  ) => guard(() async {
    final id = await _rpcId('issue_supplier_settlement', {
      'payload': settlement.toIssuePayload(),
    });
    invalidateCache();
    final issuedSettlement = await _settlementById(id);
    _logger.i('Supplier settlement issued');
    return issuedSettlement;
  });

  Future<Result<void>> voidSettlement(String id, {String? reason}) =>
      guard(() async {
        await Supabase.instance.client.rpc(
          'void_supplier_settlement',
          params: {'p_id': id, 'p_reason': reason},
        );
        invalidateCache();
        _logger.i('Supplier settlement voided');
      });

  Future<Result<void>> recordPayment(Payment payment) => guard(() async {
    await Supabase.instance.client.rpc(
      'record_payment_allocation',
      params: {'payload': payment.toPayload()},
    );
    invalidateCache();
    _logger.i('Payment recorded');
  });

  Future<Result<void>> transitionChequeState(
    String paymentId,
    ChequeState newState,
  ) => guard(() async {
    await Supabase.instance.client.rpc(
      'transition_cheque_state',
      params: {'p_payment_id': paymentId, 'p_new_state': newState.toJson()},
    );
    invalidateCache();
    _logger.i('Cheque state changed to ${newState.name}');
  });

  Future<Result<void>> markChequeCleared(String paymentId) =>
      transitionChequeState(paymentId, ChequeState.cleared);

  Future<Result<Expense>> addExpense(Expense expense) => guard(() async {
    final row = await Supabase.instance.client
        .from('expenses')
        .insert(expense.toRow(_tenantId())..remove('is_paid'))
        .select()
        .single();
    invalidateCache();
    return ExpenseRow.fromRow(row);
  });

  Future<String> _rpcId(String name, Map<String, dynamic> params) async {
    final response = await Supabase.instance.client.rpc(name, params: params);
    return response as String;
  }

  Future<Invoice> _invoiceById(String id) async {
    final row = await Supabase.instance.client
        .from('invoices')
        .select('*, invoice_lines(*)')
        .eq('id', id)
        .single();
    return InvoiceRow.fromRow(row);
  }

  Future<SupplierSettlement> _settlementById(String id) async {
    final row = await Supabase.instance.client
        .from('settlements')
        .select('*, settlement_lines(*)')
        .eq('id', id)
        .single();
    return SettlementRow.fromRow(row);
  }
}
