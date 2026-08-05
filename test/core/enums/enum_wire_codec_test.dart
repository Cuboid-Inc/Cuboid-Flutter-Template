import 'package:fleetgo/core/enums/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toJson writes the required snake_case values', () {
    expect(PartyType.customer.toJson(), 'customer');
    expect(RateModel.perTrip.toJson(), 'per_trip');
    expect(PaymentTerms.onReceipt.toJson(), 'on_receipt');
    expect(PaymentTerms.net7.toJson(), 'net_7');
    expect(PaymentTerms.net30.toJson(), 'net_30');
    expect(VehicleClass.threeTon.toJson(), 'three_ton');
    expect(VehicleClass.thirtySeatBus.toJson(), 'thirty_seat_bus');
    expect(
      InvoiceGrouping.monthlyConsolidated.toJson(),
      'monthly_consolidated',
    );
    expect(InvoiceStatus.partPaid.toJson(), 'part_paid');
    expect(PaymentMethod.bankTransfer.toJson(), 'bank_transfer');
    expect(ExpenseCategory.gatePass.toJson(), 'gate_pass');
    expect(AccessPack.masterData.toJson(), 'master_data');
  });

  test('enumFromJson reads the required snake_case values', () {
    expect(enumFromJson('customer', PartyType.values), PartyType.customer);
    expect(enumFromJson('per_trip', RateModel.values), RateModel.perTrip);
    expect(
      enumFromJson('on_receipt', PaymentTerms.values),
      PaymentTerms.onReceipt,
    );
    expect(enumFromJson('net_7', PaymentTerms.values), PaymentTerms.net7);
    expect(enumFromJson('net_30', PaymentTerms.values), PaymentTerms.net30);
    expect(
      enumFromJson('three_ton', VehicleClass.values),
      VehicleClass.threeTon,
    );
    expect(
      enumFromJson('thirty_seat_bus', VehicleClass.values),
      VehicleClass.thirtySeatBus,
    );
    expect(
      enumFromJson('monthly_consolidated', InvoiceGrouping.values),
      InvoiceGrouping.monthlyConsolidated,
    );
    expect(
      enumFromJson('part_paid', InvoiceStatus.values),
      InvoiceStatus.partPaid,
    );
    expect(
      enumFromJson('bank_transfer', PaymentMethod.values),
      PaymentMethod.bankTransfer,
    );
    expect(
      enumFromJson('gate_pass', ExpenseCategory.values),
      ExpenseCategory.gatePass,
    );
    expect(
      enumFromJson('master_data', AccessPack.values),
      AccessPack.masterData,
    );
  });

  test('enumFromJson functions handle null and unknown values', () {
    expect(enumFromJsonOrNull(null, PartyType.values), isNull);
    expect(enumFromJsonOrNull('missing', PartyType.values), isNull);
    expect(
      () => enumFromJson('missing', PartyType.values),
      throwsArgumentError,
    );
  });
}
