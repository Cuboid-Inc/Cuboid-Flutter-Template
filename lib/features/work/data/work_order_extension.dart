import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';

extension WorkOrderRow on WorkOrder {
  Map<String, dynamic> toRow(String tenantId) => {
    'id': id,
    'number': number,
    'tenant_id': tenantId,
    'customer_id': customerId,
    'agreement_id': agreementId,
    'date': date.toIso8601String(),
    'work_type': workType.toJson(),
    'status': status.toJson(),
    'pickup': pickup,
    'destination': destination,
    'planned_start': plannedStart?.toIso8601String(),
    'planned_end': plannedEnd?.toIso8601String(),
    'customer_job_reference': customerJobReference,
    'description': description,
    'notes': notes,
    'invoice_id': invoiceId,
    'allocations': allocations.map((allocation) => allocation.toRow()).toList(),
    'charge_lines': chargeLines.map((line) => line.toRow()).toList(),
  };

  static WorkOrder fromRow(Map<String, dynamic> row) => WorkOrder(
    id: row['id'] as String,
    number: row['number'] as String,
    customerId: row['customer_id'] as String,
    agreementId: row['agreement_id'] as String?,
    date: DateTime.parse(row['date'] as String),
    pickup: row['pickup'] as String,
    destination: row['destination'] as String,
    workType: enumFromJson(row['work_type'] as String, WorkType.values),
    plannedStart: _dateTimeFromDatabase(row['planned_start']),
    plannedEnd: _dateTimeFromDatabase(row['planned_end']),
    customerJobReference: row['customer_job_reference'] as String?,
    description: row['description'] as String?,
    status: enumFromJson(row['status'] as String, WorkStatus.values),
    allocations: (row['work_order_allocations'] as List<dynamic>? ?? const [])
        .map(
          (value) =>
              VehicleAllocationRow.fromRow(value as Map<String, dynamic>),
        )
        .toList(),
    chargeLines: (row['work_order_charge_lines'] as List<dynamic>? ?? const [])
        .map((value) => ChargeLineRow.fromRow(value as Map<String, dynamic>))
        .toList(),
    notes: row['notes'] as String?,
    invoiceId: row['invoice_id'] as String?,
  );
}

extension VehicleAllocationRow on VehicleAllocation {
  Map<String, dynamic> toRow() => {
    'vehicle_id': vehicleId,
    'driver_id': driverId,
    'source': source.toJson(),
    'supplier_id': supplierId,
    'supplier_payable': roundMoney(supplierPayable),
    'notes': notes,
  };

  static VehicleAllocation fromRow(Map<String, dynamic> row) =>
      VehicleAllocation(
        vehicleId: row['vehicle_id'] as String,
        driverId: row['driver_id'] as String?,
        source: enumFromJson(row['source'] as String, VehicleSource.values),
        supplierId: row['supplier_id'] as String?,
        supplierPayable: roundMoney(row['supplier_payable'] as num),
        notes: row['notes'] as String?,
      );
}

extension ChargeLineRow on ChargeLine {
  Map<String, dynamic> toRow() => {
    'name': name,
    'description': description,
    'quantity': quantity,
    'unit_price': roundMoney(unitPrice),
    'unit': unit,
    'discount': roundMoney(discount),
    'vat_rate': vatRate,
  };

  static ChargeLine fromRow(Map<String, dynamic> row) => ChargeLine(
    name: row['name'] as String,
    description: row['description'] as String?,
    quantity: (row['quantity'] as num).toInt(),
    unitPrice: roundMoney(row['unit_price'] as num),
    unit: row['unit'] as String,
    discount: roundMoney(row['discount'] as num),
    vatRate: row['vat_rate'] as num,
  );
}

DateTime? _dateTimeFromDatabase(dynamic value) =>
    value == null ? null : DateTime.tryParse(value as String);
