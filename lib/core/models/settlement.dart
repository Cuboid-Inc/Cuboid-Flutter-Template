import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/money.dart';

class SettlementLine {
  const SettlementLine({
    required this.workOrderId,
    required this.date,
    required this.amount,
    this.customerName,
    this.vehicleId,
    this.driverId,
    this.route,
  });

  final String workOrderId;
  final DateTime date;
  final num amount;
  final String? customerName;
  final String? vehicleId;
  final String? driverId;
  final String? route;
}

class SupplierSettlement {
  SupplierSettlement({
    required this.id,
    required this.number,
    required this.supplierId,
    required this.periodStart,
    required this.periodEnd,
    List<SettlementLine>? lines,
    this.status = SettlementStatus.draft,
    this.voidReason,
  }) : lines = lines ?? [];

  final String id;
  final String number;
  final String supplierId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final List<SettlementLine> lines;
  SettlementStatus status;
  String? voidReason;

  num get total => roundMoney(
    lines.fold<num>(0, (sum, line) => roundMoney(sum + line.amount)),
  );
}
