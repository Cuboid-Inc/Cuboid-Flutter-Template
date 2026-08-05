import 'package:fleetgo/core/config/formatters.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class FinancialLineTile extends StatelessWidget {
  const FinancialLineTile({
    super.key,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.discount,
    required this.vatRate,
    required this.net,
    required this.gross,
  });

  final String description;
  final String quantity;
  final num unitPrice;
  final num discount;
  final num vatRate;
  final num net;
  final num gross;

  @override
  Widget build(BuildContext context) {
    final discountText = discount > 0
        ? ' · Disc. ${Formatters.rawMoney(discount)}'
        : '';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        description,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        '$quantity × ${Formatters.rawMoney(unitPrice)}$discountText · VAT ${_vatPercentage(vatRate)}% · Net ${Formatters.rawMoney(net)}',
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Text(
        Formatters.rawMoney(gross),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          fontSize: 16,
        ),
      ),
    );
  }
}

String _vatPercentage(num rate) => rate.toStringAsFixed(0);
