import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/money.dart';

class VehicleAllocation {
  const VehicleAllocation({
    required this.vehicleId,
    this.driverId,
    this.source = VehicleSource.owned,
    this.supplierId,
    this.supplierPayable = 0,
    this.notes,
  });

  final String vehicleId;
  final String? driverId;
  final VehicleSource source;
  final String? supplierId;
  final num supplierPayable;
  final String? notes;
}

class ChargeLine {
  const ChargeLine({
    required this.name,
    this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.unit = 'unit',
    this.discount = 0,
    this.vatRate = 5,
  });

  final String name;
  final String? description;
  final int quantity;
  final num unitPrice;
  final String unit;
  final num discount;
  final num vatRate;

  num get net => roundMoney(quantity * unitPrice - discount);
  num get vat => vatAmount(net, vatRate);
  num get gross => roundMoney(net + vat);
}

class WorkOrder {
  WorkOrder({
    required this.id,
    required this.number,
    required this.customerId,
    this.agreementId,
    required this.date,
    required this.pickup,
    required this.destination,
    this.workType = WorkType.perTrip,
    this.plannedStart,
    this.plannedEnd,
    this.customerJobReference,
    this.description,
    this.status = WorkStatus.planned,
    List<VehicleAllocation>? allocations,
    List<ChargeLine>? chargeLines,
    this.notes,
    this.invoiceId,
  }) : allocations = allocations ?? [],
       chargeLines = chargeLines ?? [];

  final String id;
  final String number;
  final String customerId;
  final String? agreementId;
  final DateTime date;
  final WorkType workType;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final String? customerJobReference;
  final String? description;
  WorkStatus status;
  final String pickup;
  final String destination;
  final List<VehicleAllocation> allocations;
  final List<ChargeLine> chargeLines;
  final String? notes;
  String? invoiceId;

  num get net => roundMoney(
    chargeLines.fold<num>(0, (sum, line) => roundMoney(sum + line.net)),
  );
  num get vat => roundMoney(
    chargeLines.fold<num>(0, (sum, line) => roundMoney(sum + line.vat)),
  );
  num get gross => roundMoney(net + vat);
  String get route => '$pickup → $destination';
}
