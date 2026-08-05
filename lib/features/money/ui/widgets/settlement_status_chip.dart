import 'package:cuboid_flutter_template/core/enums/enums.dart';
import 'package:cuboid_flutter_template/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class SettlementStatusChip extends StatelessWidget {
  const SettlementStatusChip(this.status, {super.key});
  final SettlementStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    SettlementStatus.paid => StatusChip.success('Paid'),
    SettlementStatus.partPaid => StatusChip.warning('Part Paid'),
    SettlementStatus.issued => StatusChip.info('Issued'),
    SettlementStatus.voided => StatusChip.neutral('Void'),
    SettlementStatus.draft => StatusChip.neutral('Draft'),
  };
}
