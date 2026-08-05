import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/ui/widgets/financial_line_tile.dart';
import 'package:flutter/material.dart';

class InvoiceLineTile extends StatelessWidget {
  const InvoiceLineTile({super.key, required this.line});
  final InvoiceLine line;

  @override
  Widget build(BuildContext context) => FinancialLineTile(
    description: line.name,
    quantity: '${line.quantity} ${line.unit}',
    unitPrice: line.unitPrice,
    discount: line.discount,
    vatRate: line.vatRate,
    net: line.net,
    gross: line.gross,
  );
}
