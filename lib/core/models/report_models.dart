import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/models/invoice.dart';
import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/core/money.dart';

class CashbookTotals {
  const CashbookTotals({required this.inAmount, required this.outAmount});

  final num inAmount;
  final num outAmount;
  num get net => roundMoney(inAmount - outAmount);
}

class HomeTotals {
  const HomeTotals({
    required this.billed,
    required this.revenue,
    required this.operatingCosts,
    required this.received,
    required this.paidOut,
  });

  final num billed;
  final num revenue;
  final num operatingCosts;
  final num received;
  final num paidOut;
  num get profit => roundMoney(revenue - operatingCosts);
  num get cashFlow => roundMoney(received - paidOut);
}

class ExpenseTotal {
  const ExpenseTotal(this.category, this.amount);

  final ExpenseCategory category;
  final num amount;
}

class PartyBalance {
  const PartyBalance({required this.partyId, required this.amount});

  final String partyId;
  final num amount;
}

class VehicleProfit {
  const VehicleProfit({
    required this.vehicleId,
    required this.revenue,
    required this.payable,
    required this.expense,
  });

  final String vehicleId;
  final num revenue;
  final num payable;
  final num expense;
  num get profit => roundMoney(revenue - payable - expense);
}

class OwnershipSplit {
  const OwnershipSplit({required this.owned, required this.external});

  final num owned;
  final num external;
}

class StatementRow {
  const StatementRow({
    required this.partyId,
    required this.date,
    required this.workOrderId,
    required this.description,
    required this.amount,
  });

  final String partyId;
  final DateTime date;
  final String workOrderId;
  final String description;
  final num amount;
}

class UnbilledWorkRow {
  const UnbilledWorkRow({required this.workOrder, required this.customerName});

  final WorkOrder workOrder;
  final String customerName;
}

class UnpaidInvoiceRow {
  const UnpaidInvoiceRow({required this.invoice, required this.balance});

  final Invoice invoice;
  final num balance;
}

class ExpiringDocument {
  const ExpiringDocument({
    required this.ownerId,
    required this.ownerName,
    required this.ownerType,
    required this.kind,
    required this.expiresOn,
  });

  final String ownerId;
  final String ownerName;
  final String ownerType;
  final String kind;
  final DateTime expiresOn;
}
