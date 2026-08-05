import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

class FormSectionLabel extends StatelessWidget {
  const FormSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.6,
          color: AppColors.muted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
