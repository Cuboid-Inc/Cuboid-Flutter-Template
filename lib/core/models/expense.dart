import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/core/money.dart';

class Expense {
  Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.payee,
    required this.net,
    this.vat = 0,
    this.vehicleId,
    this.driverId,
    this.workOrderId,
    this.description,
    this.dueDate,
    this.reference,
    this.notes,
    this.isPaid = false,
  });

  final String id;
  final DateTime date;
  final ExpenseCategory category;
  final String payee;
  final num net;
  final num vat;
  final String? vehicleId;
  final String? driverId;
  final String? workOrderId;
  final String? description;
  final DateTime? dueDate;
  final String? reference;
  final String? notes;
  bool isPaid;

  num get total => roundMoney(net + vat);
}
