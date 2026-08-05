import 'package:fleetgo/core/enums/enums.dart';
import 'package:fleetgo/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class InvoiceStatusChip extends StatelessWidget {
  const InvoiceStatusChip(this.status, {super.key});
  final InvoiceStatus status;

  @override
  Widget build(BuildContext context) => switch (status) {
    InvoiceStatus.paid => StatusChip.success('Paid'),
    InvoiceStatus.partPaid => StatusChip.warning('Part Paid'),
    InvoiceStatus.issued => StatusChip.info('Issued'),
    InvoiceStatus.voided => StatusChip.neutral('Void'),
    InvoiceStatus.draft => StatusChip.neutral('Draft'),
  };
}
