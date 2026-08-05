import 'package:flutter/material.dart';

import 'package:fleetgo/ui/common/app_colors.dart';

/// Small muted uppercase header used between list sections
/// (e.g. "NEEDS ATTENTION", "CUSTOMERS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.06,
        color: AppColors.muted,
      ),
    );
  }
}
