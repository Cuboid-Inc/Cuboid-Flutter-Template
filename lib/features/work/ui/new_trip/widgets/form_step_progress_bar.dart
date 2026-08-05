import 'package:flutter/material.dart';
import 'package:fleetgo/ui/common/app_colors.dart';

class FormStepProgressBar extends StatelessWidget {
  const FormStepProgressBar({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= totalSteps; i++)
          Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: i < totalSteps ? 8 : 0),
              decoration: BoxDecoration(
                color: i <= currentStep ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}
