import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/core/money.dart';

class InvoiceLine {
  const InvoiceLine({
    required this.name,
    this.description,
    this.quantity = 1,
    required this.unitPrice,
    this.unit = 'unit',
    this.discount = 0,
    this.vatRate = 5,
    this.netAmountOverride,
    this.vatAmountOverride,
  });

  final String name;
  final String? description;
  final int quantity;
  final num unitPrice;
  final String unit;
  final num discount;
  final num vatRate;
  final num? netAmountOverride;
  final num? vatAmountOverride;

  num get net =>
      roundMoney(netAmountOverride ?? quantity * unitPrice - discount);
  num get vat => roundMoney(vatAmountOverride ?? vatAmount(net, vatRate));
  num get gross => roundMoney(net + vat);
}

class Invoice {
  Invoice({
    required this.id,
    required this.number,
    required this.buyerId,
    required this.buyerName,
    this.buyerAddress,
    this.buyerTrn,
    this.buyerContact,
    this.paymentTerms = 'On receipt',
    required this.issueDate,
    this.dueDate,
    this.supplyDate,
    List<InvoiceLine>? lines,
    List<String>? linkedWorkOrderIds,
    this.status = InvoiceStatus.draft,
    this.voidReason,
  }) : lines = lines ?? [],
       linkedWorkOrderIds = linkedWorkOrderIds ?? [];

  final String id;
  final String number;
  final String buyerId;
  final String buyerName;
  final String? buyerAddress;
  final String? buyerTrn;
  final String? buyerContact;
  final String paymentTerms;
  final DateTime issueDate;
  final DateTime? dueDate;
  final DateTime? supplyDate;
  final List<InvoiceLine> lines;
  final List<String> linkedWorkOrderIds;
  InvoiceStatus status;
  String? voidReason;

  num get net =>
      roundMoney(lines.fold<num>(0, (sum, line) => roundMoney(sum + line.net)));
  num get vat =>
      roundMoney(lines.fold<num>(0, (sum, line) => roundMoney(sum + line.vat)));
  num get gross => roundMoney(net + vat);
}
