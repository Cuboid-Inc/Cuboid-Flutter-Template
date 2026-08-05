import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11.5,
      letterSpacing: 0.6,
      color: AppColors.muted,
      fontWeight: FontWeight.w800,
    ),
  );
}
