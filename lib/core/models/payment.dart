import 'package:fleetgo/core/enums/enums.dart';

class PaymentAllocation {
  const PaymentAllocation({
    required this.amount,
    this.invoiceId,
    this.settlementId,
    this.expenseId,
  });

  final num amount;
  final String? invoiceId;
  final String? settlementId;
  final String? expenseId;

  String? get targetId => invoiceId ?? settlementId ?? expenseId;
}

class Payment {
  Payment({
    required this.id,
    required this.direction,
    required this.partyId,
    required this.date,
    required this.amount,
    required this.method,
    List<PaymentAllocation>? allocations,
    this.bankOrChequeReference,
    this.chequeDate,
    this.chequeState = ChequeState.cleared,
    this.notes,
  }) : allocations = allocations ?? [];

  final String id;
  final PaymentDirection direction;
  final String? partyId;
  final DateTime date;
  final num amount;
  final PaymentMethod method;
  final String? bankOrChequeReference;
  final DateTime? chequeDate;
  ChequeState chequeState;
  final List<PaymentAllocation> allocations;
  final String? notes;

  bool get isCleared =>
      method != PaymentMethod.cheque || chequeState == ChequeState.cleared;
}
