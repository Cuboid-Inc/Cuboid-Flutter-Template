import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/ui/widgets/status_chip.dart';
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
