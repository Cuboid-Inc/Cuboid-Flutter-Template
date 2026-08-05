import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/features/money/data/money_extensions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and builds an invoice issue payload', () {
    final invoice = InvoiceRow.fromRow({
      'id': 'invoice-1',
      'number': 'INV-1',
      'buyer_id': 'customer-1',
      'buyer_name': 'Customer',
      'buyer_address': 'Street',
      'buyer_trn': 'TRN-1',
      'buyer_contact': 'Aisha',
      'payment_terms': 'Net 30',
      'issue_date': '2026-07-18',
      'due_date': '2026-08-17',
      'supply_date': '2026-07-18',
      'status': 'part_paid',
      'void_reason': null,
      'invoice_lines': [
        {
          'name': 'Trip',
          'description': 'D',
          'quantity': 2.9,
          'unit_price': 10.005,
          'unit': 'trip',
          'discount': 1.005,
          'vat_rate': 5,
          'net_override': 20.005,
          'vat_override': 1.005,
        },
      ],
    });

    expect(invoice.status, InvoiceStatus.partPaid);
    expect(invoice.dueDate, DateTime(2026, 8, 17));
    expect(invoice.lines.single.quantity, 2);
    expect(invoice.lines.single.netAmountOverride, 20.01);
    expect(invoice.lines.single.vatAmountOverride, 1.01);

    invoice.linkedWorkOrderIds.add('work-1');
    expect(
      invoice.toIssuePayload(),
      containsPair('work_order_ids', ['work-1']),
    );
    expect(invoice.toIssuePayload()['lines'], hasLength(1));
  });

  test('maps invoice and line defaults and serializes a line', () {
    final invoice = InvoiceRow.fromRow({
      'id': 'invoice-2',
      'number': 'INV-2',
      'buyer_id': 'customer-1',
      'buyer_name': 'Customer',
      'buyer_address': null,
      'buyer_trn': null,
      'buyer_contact': null,
      'payment_terms': 'On receipt',
      'issue_date': '2026-07-18',
      'due_date': null,
      'supply_date': null,
      'status': 'draft',
      'void_reason': 'none',
    });

    expect(invoice.lines, isEmpty);
    final line = InvoiceLineRow.fromRow({
      'name': 'Trip',
      'description': null,
      'quantity': 1,
      'unit_price': 10,
      'unit': 'unit',
      'discount': 0,
      'vat_rate': 5,
      'net_override': null,
      'vat_override': null,
    });
    expect(line.toPayload()['net_override'], isNull);
    expect(line.toPayload()['vat_override'], isNull);
  });

  test('maps and builds settlement payloads', () {
    final settlement = SettlementRow.fromRow({
      'id': 'settlement-1',
      'number': 'SET-1',
      'supplier_id': 'supplier-1',
      'period_start': '2026-07-01',
      'period_end': '2026-07-31',
      'status': 'issued',
      'void_reason': null,
      'settlement_lines': [
        {
          'work_order_id': 'work-1',
          'date': '2026-07-18',
          'amount': 10.005,
          'customer_name': 'Customer',
          'vehicle_id': 'vehicle-1',
          'driver_id': 'driver-1',
          'route': 'A to B',
        },
      ],
    });

    expect(settlement.status, SettlementStatus.issued);
    expect(settlement.lines.single.amount, 10.01);
    expect(settlement.lines.single.toPayload(), {
      'work_order_id': 'work-1',
      'date': '2026-07-18T00:00:00.000',
      'amount': 10.01,
      'customer_name': 'Customer',
      'vehicle_id': 'vehicle-1',
      'driver_id': 'driver-1',
      'route': 'A to B',
    });
    expect(
      settlement.toIssuePayload()['period_start'],
      '2026-07-01T00:00:00.000',
    );

    final empty = SettlementRow.fromRow({
      'id': 'settlement-2',
      'number': 'SET-2',
      'supplier_id': 'supplier-1',
      'period_start': '2026-07-01',
      'period_end': '2026-07-31',
      'status': 'draft',
      'void_reason': 'void',
    });
    expect(empty.lines, isEmpty);
  });

  test('maps payments and serializes cheque and non-cheque payloads', () {
    final cheque = PaymentRow.fromRow({
      'id': 'payment-1',
      'direction': 'incoming',
      'party_id': 'customer-1',
      'date': '2026-07-18',
      'amount': 10.005,
      'method': 'cheque',
      'reference': 'CHQ-1',
      'cheque_date': '2026-07-20',
      'cheque_state': 'received',
      'notes': 'Note',
      'payment_allocations': [
        {'document_type': 'invoice', 'document_id': 'invoice-1', 'amount': 5},
        {
          'document_type': 'settlement',
          'document_id': 'settlement-1',
          'amount': 3,
        },
        {'document_type': 'expense', 'document_id': 'expense-1', 'amount': 2},
      ],
    });

    expect(cheque.chequeState, ChequeState.received);
    expect(cheque.chequeDate, DateTime(2026, 7, 20));
    expect(cheque.allocations[0].invoiceId, 'invoice-1');
    expect(cheque.allocations[1].settlementId, 'settlement-1');
    expect(cheque.allocations[2].expenseId, 'expense-1');
    expect(cheque.toPayload()['cheque_state'], 'received');
    expect(cheque.toPayload()['allocations'], hasLength(3));

    final cash = PaymentRow.fromRow({
      'id': 'payment-2',
      'direction': 'outgoing',
      'party_id': null,
      'date': '2026-07-18',
      'amount': 2,
      'method': 'cash',
      'reference': null,
      'cheque_date': null,
      'cheque_state': null,
      'notes': null,
    });
    expect(cash.chequeState, ChequeState.cleared);
    expect(cash.toPayload()['cheque_state'], isNull);
    expect(cash.allocations, isEmpty);
  });

  test('maps and writes expense rows with optional values', () {
    final expense = ExpenseRow.fromRow({
      'id': 'expense-1',
      'date': '2026-07-18',
      'category': 'fuel',
      'payee': 'Fuel',
      'net': 10.005,
      'vat': 0.505,
      'vehicle_id': 'vehicle-1',
      'driver_id': 'driver-1',
      'work_order_id': 'work-1',
      'description': 'Diesel',
      'due_date': '2026-07-20',
      'reference': 'REF-1',
      'notes': 'Note',
      'is_paid': true,
    });

    expect(expense.category, ExpenseCategory.fuel);
    expect(expense.total, 10.52);
    expect(expense.isPaid, isTrue);
    expect(expense.toRow('tenant-1'), containsPair('tenant_id', 'tenant-1'));
    expect(expense.toRow('tenant-1')['due_date'], '2026-07-20T00:00:00.000');

    final unpaid = ExpenseRow.fromRow({
      'id': 'expense-2',
      'date': '2026-07-18',
      'category': 'other',
      'payee': 'Other',
      'net': 1,
      'vat': 0,
      'vehicle_id': null,
      'driver_id': null,
      'work_order_id': null,
      'description': null,
      'due_date': null,
      'reference': null,
      'notes': null,
      'is_paid': null,
    });
    expect(unpaid.isPaid, isFalse);
    expect(unpaid.toRow('tenant-1')['due_date'], isNull);
  });
}
