import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/money.dart';
import 'package:fleetgo/core/models/expense.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/core/models/payment.dart';
import 'package:fleetgo/core/models/settlement.dart';

DateTime _date(Object value) => DateTime.parse(value.toString());
DateTime? _dateOrNull(Object? value) => value == null ? null : _date(value);
num _money(Object? value) => roundMoney((value as num?) ?? 0);

extension InvoiceRow on Invoice {
  static Invoice fromRow(Map<String, dynamic> row) => Invoice(
    id: row['id'] as String,
    number: row['number'] as String,
    buyerId: row['buyer_id'] as String,
    buyerName: row['buyer_name'] as String,
    buyerAddress: row['buyer_address'] as String?,
    buyerTrn: row['buyer_trn'] as String?,
    buyerContact: row['buyer_contact'] as String?,
    paymentTerms: row['payment_terms'] as String,
    issueDate: _date(row['issue_date']!),
    dueDate: _dateOrNull(row['due_date']),
    supplyDate: _dateOrNull(row['supply_date']),
    status: enumFromJson(row['status'] as String, InvoiceStatus.values),
    voidReason: row['void_reason'] as String?,
    lines: ((row['invoice_lines'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(InvoiceLineRow.fromRow)
        .toList(),
  );

  Map<String, dynamic> toIssuePayload() => {
    'buyer_id': buyerId,
    'buyer_name': buyerName,
    'buyer_address': buyerAddress,
    'buyer_trn': buyerTrn,
    'buyer_contact': buyerContact,
    'payment_terms': paymentTerms,
    'issue_date': issueDate.toIso8601String(),
    'due_date': dueDate?.toIso8601String(),
    'supply_date': supplyDate?.toIso8601String(),
    'work_order_ids': linkedWorkOrderIds,
    'lines': lines.map((line) => line.toPayload()).toList(),
  };
}

extension InvoiceLineRow on InvoiceLine {
  static InvoiceLine fromRow(Map<String, dynamic> row) => InvoiceLine(
    name: row['name'] as String,
    description: row['description'] as String?,
    quantity: _money(row['quantity']).toInt(),
    unitPrice: _money(row['unit_price']),
    unit: row['unit'] as String,
    discount: _money(row['discount']),
    vatRate: _money(row['vat_rate']),
    netAmountOverride: row['net_override'] == null
        ? null
        : _money(row['net_override']),
    vatAmountOverride: row['vat_override'] == null
        ? null
        : _money(row['vat_override']),
  );

  Map<String, dynamic> toPayload() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'unit_price': unitPrice,
    'unit': unit,
    'discount': discount,
    'vat_rate': vatRate,
    'net_override': netAmountOverride,
    'vat_override': vatAmountOverride,
  };
}

extension SettlementRow on SupplierSettlement {
  static SupplierSettlement fromRow(Map<String, dynamic> row) =>
      SupplierSettlement(
        id: row['id'] as String,
        number: row['number'] as String,
        supplierId: row['supplier_id'] as String,
        periodStart: _date(row['period_start']!),
        periodEnd: _date(row['period_end']!),
        status: enumFromJson(row['status'] as String, SettlementStatus.values),
        voidReason: row['void_reason'] as String?,
        lines: ((row['settlement_lines'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SettlementLineRow.fromRow)
            .toList(),
      );

  Map<String, dynamic> toIssuePayload() => {
    'supplier_id': supplierId,
    'period_start': periodStart.toIso8601String(),
    'period_end': periodEnd.toIso8601String(),
    'lines': lines.map((line) => line.toPayload()).toList(),
  };
}

extension SettlementLineRow on SettlementLine {
  static SettlementLine fromRow(Map<String, dynamic> row) => SettlementLine(
    workOrderId: row['work_order_id'] as String,
    date: _date(row['date']!),
    amount: _money(row['amount']),
    customerName: row['customer_name'] as String?,
    vehicleId: row['vehicle_id'] as String?,
    driverId: row['driver_id'] as String?,
    route: row['route'] as String?,
  );

  Map<String, dynamic> toPayload() => {
    'work_order_id': workOrderId,
    'date': date.toIso8601String(),
    'amount': amount,
    'customer_name': customerName,
    'vehicle_id': vehicleId,
    'driver_id': driverId,
    'route': route,
  };
}

extension PaymentRow on Payment {
  static Payment fromRow(Map<String, dynamic> row) => Payment(
    id: row['id'] as String,
    direction: enumFromJson(
      row['direction'] as String,
      PaymentDirection.values,
    ),
    partyId: row['party_id'] as String?,
    date: _date(row['date']!),
    amount: _money(row['amount']),
    method: enumFromJson(row['method'] as String, PaymentMethod.values),
    bankOrChequeReference: row['reference'] as String?,
    chequeDate: _dateOrNull(row['cheque_date']),
    chequeState:
        enumFromJsonOrNull(
          row['cheque_state'] as String?,
          ChequeState.values,
        ) ??
        ChequeState.cleared,
    notes: row['notes'] as String?,
    allocations: ((row['payment_allocations'] as List?) ?? const [])
        .cast<Map<String, dynamic>>()
        .map(PaymentAllocationRow.fromRow)
        .toList(),
  );

  Map<String, dynamic> toPayload() => {
    'direction': direction.toJson(),
    'party_id': partyId,
    'date': date.toIso8601String(),
    'amount': amount,
    'method': method.toJson(),
    'reference': bankOrChequeReference,
    'cheque_date': chequeDate?.toIso8601String(),
    'cheque_state': method == PaymentMethod.cheque
        ? ChequeState.received.toJson()
        : null,
    'notes': notes,
    'allocations': allocations
        .map((allocation) => allocation.toPayload())
        .toList(),
  };
}

extension PaymentAllocationRow on PaymentAllocation {
  static PaymentAllocation fromRow(Map<String, dynamic> row) {
    final type = row['document_type'] as String;
    final id = row['document_id'] as String;
    return PaymentAllocation(
      amount: _money(row['amount']),
      invoiceId: type == 'invoice' ? id : null,
      settlementId: type == 'settlement' ? id : null,
      expenseId: type == 'expense' ? id : null,
    );
  }

  Map<String, dynamic> toPayload() => {
    'document_type': invoiceId != null
        ? 'invoice'
        : settlementId != null
        ? 'settlement'
        : 'expense',
    'document_id': targetId,
    'amount': amount,
  };
}

extension ExpenseRow on Expense {
  static Expense fromRow(Map<String, dynamic> row) => Expense(
    id: row['id'] as String,
    date: _date(row['date']!),
    category: enumFromJson(row['category'] as String, ExpenseCategory.values),
    payee: row['payee'] as String,
    net: _money(row['net']),
    vat: _money(row['vat']),
    vehicleId: row['vehicle_id'] as String?,
    driverId: row['driver_id'] as String?,
    workOrderId: row['work_order_id'] as String?,
    description: row['description'] as String?,
    dueDate: _dateOrNull(row['due_date']),
    reference: row['reference'] as String?,
    notes: row['notes'] as String?,
    isPaid: row['is_paid'] as bool? ?? false,
  );

  Map<String, dynamic> toRow(String tenantId) => {
    'tenant_id': tenantId,
    'date': date.toIso8601String(),
    'category': category.toJson(),
    'payee': payee,
    'net': net,
    'vat': vat,
    'vehicle_id': vehicleId,
    'driver_id': driverId,
    'work_order_id': workOrderId,
    'description': description,
    'due_date': dueDate?.toIso8601String(),
    'reference': reference,
    'notes': notes,
    'is_paid': isPaid,
  };
}
