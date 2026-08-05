import 'package:cuboid_flutter_template/core/models/work_order.dart';
import 'package:cuboid_flutter_template/ui/widgets/financial_line_tile.dart';
import 'package:flutter/material.dart';

class WorkChargeTile extends StatelessWidget {
  const WorkChargeTile({super.key, required this.line});
  final ChargeLine line;

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
