import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/features/more/data/driver_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a driver row and writes dates as database dates', () {
    final driver = DriverRow.fromRow({
      'id': 'driver-1',
      'name': 'Aisha Khan',
      'phone': '+971500000000',
      'licence_number': 'DL-1',
      'licence_expiry': '2026-08-09',
      'identity_reference': 'ID-1',
      'identity_expiry': '2027-01-02',
      'employment': 'customer',
      'supplier_id': 'supplier-1',
      'notes': 'Note',
      'is_archived': true,
    });

    expect(driver.licenceExpiry, DateTime(2026, 8, 9));
    expect(driver.identityExpiry, DateTime(2027, 1, 2));
    expect(driver.employment, Responsibility.customer);
    expect(driver.toRow('tenant-1'), {
      'tenant_id': 'tenant-1',
      'name': 'Aisha Khan',
      'phone': '+971500000000',
      'licence_number': 'DL-1',
      'licence_expiry': '2026-08-09',
      'identity_reference': 'ID-1',
      'identity_expiry': '2027-01-02',
      'employment': 'customer',
      'supplier_id': 'supplier-1',
      'notes': 'Note',
    });
  });

  test('maps and writes nullable driver fields', () {
    final driver = DriverRow.fromRow({
      'id': 'driver-2',
      'name': 'Omar Ali',
      'phone': null,
      'licence_number': null,
      'licence_expiry': null,
      'identity_reference': null,
      'identity_expiry': null,
      'employment': 'operator',
      'supplier_id': null,
      'notes': null,
      'is_archived': false,
    });

    expect(driver.licenceExpiry, isNull);
    expect(driver.identityExpiry, isNull);
    expect(driver.toRow('tenant-2')['licence_expiry'], isNull);
    expect(driver.toRow('tenant-2')['identity_expiry'], isNull);
  });
}
