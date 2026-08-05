import 'package:flutter/cupertino.dart';
import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/core/models/invoice.dart';
import 'package:fleetgo/ui/common/app_colors.dart';

class PartyOpenInvoiceTile extends StatelessWidget {
  const PartyOpenInvoiceTile({
    super.key,
    required this.invoice,
    required this.balance,
    required this.onTap,
  });

  final Invoice invoice;
  final num balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Issued ${Formatters.date(invoice.issueDate)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              Formatters.money(balance),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              CupertinoIcons.chevron_right,
              color: AppColors.muted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
