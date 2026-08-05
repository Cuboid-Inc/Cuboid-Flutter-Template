import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/more/data/agreement_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps and writes an agreement with nullable dates', () {
    final agreement = AgreementRow.fromRow({
      'id': 'agreement-1',
      'reference': 'AGR-1',
      'name': 'Monthly hire',
      'customer_id': 'customer-1',
      'rate_model': 'monthly',
      'start_date': '2026-08-01',
      'end_date': '2026-12-31',
      'invoice_grouping': 'monthly_consolidated',
      'base_rate': 100.005,
      'duty_days': 26.9,
      'included_hours': 8.9,
      'overtime_rate': 20.005,
      'extra_day_rate': 30.005,
      'extra_trip_rate': 40.005,
      'vat_rate': 5,
      'driver_responsibility': 'customer',
      'fuel_responsibility': 'operator',
      'maintenance_responsibility': 'customer',
      'default_vehicle_id': 'vehicle-1',
      'purchase_order_reference': 'PO-1',
      'payment_terms': 'net_30',
      'notes': 'Note',
      'default_extras': {'parking': 12.345},
      'is_archived': true,
    });

    expect(agreement.startDate, DateTime(2026, 8));
    expect(agreement.endDate, DateTime(2026, 12, 31));
    expect(agreement.baseRate, 100.01);
    expect(agreement.dutyDays, 26);
    expect(agreement.includedHours, 8);
    expect(agreement.paymentTerms, PaymentTerms.net30);
    expect(agreement.driverResponsibility, Responsibility.customer);
    expect(agreement.defaultExtras, {'parking': 12.35});

    final row = agreement.toRow('tenant-1');
    expect(row['tenant_id'], 'tenant-1');
    expect(row['rate_model'], 'monthly');
    expect(row['start_date'], '2026-08-01');
    expect(row['end_date'], '2026-12-31');
    expect(row['invoice_grouping'], 'monthly_consolidated');
    expect(row['payment_terms'], 'net_30');
    expect(row['default_extras'], {'parking': 12.35});
  });

  test('maps nullable agreement dates', () {
    final agreement = AgreementRow.fromRow({
      'id': 'agreement-2',
      'reference': 'AGR-2',
      'name': 'Trip rate',
      'customer_id': 'customer-1',
      'rate_model': 'per_trip',
      'start_date': null,
      'end_date': null,
      'invoice_grouping': 'per_work',
      'base_rate': 0,
      'duty_days': 0,
      'included_hours': 0,
      'overtime_rate': 0,
      'extra_day_rate': 0,
      'extra_trip_rate': 0,
      'vat_rate': 5,
      'driver_responsibility': 'operator',
      'fuel_responsibility': 'operator',
      'maintenance_responsibility': 'operator',
      'default_vehicle_id': null,
      'purchase_order_reference': null,
      'payment_terms': 'on_receipt',
      'notes': null,
      'default_extras': null,
      'is_archived': false,
    });

    expect(agreement.startDate, isNull);
    expect(agreement.endDate, isNull);
    expect(agreement.toRow('tenant-2')['start_date'], isNull);
    expect(agreement.toRow('tenant-2')['end_date'], isNull);
  });
}
