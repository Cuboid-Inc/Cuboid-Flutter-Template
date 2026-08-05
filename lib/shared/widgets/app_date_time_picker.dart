import 'dart:ui';

import 'package:cuboid_flutter_template/core/formatters/formatters.dart';
import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AppDateTimePickerMode { date, time, dateTime }

class AppDateTimePicker extends StatelessWidget {
  const AppDateTimePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.mode = AppDateTimePickerMode.dateTime,
    this.placeholder = 'Select date & time...',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final AppDateTimePickerMode mode;
  final String placeholder;

  String _formatValue(DateTime val) {
    switch (mode) {
      case AppDateTimePickerMode.date:
        return Formatters.date(val);
      case AppDateTimePickerMode.time:
        return Formatters.time(val);
      case AppDateTimePickerMode.dateTime:
        return Formatters.dateTime(val);
    }
  }

  CupertinoDatePickerMode _getCupertinoMode() {
    switch (mode) {
      case AppDateTimePickerMode.date:
        return CupertinoDatePickerMode.date;
      case AppDateTimePickerMode.time:
        return CupertinoDatePickerMode.time;
      case AppDateTimePickerMode.dateTime:
        return CupertinoDatePickerMode.dateAndTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            letterSpacing: 0.6,
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showPicker(context),
          borderRadius: BorderRadius.circular(radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(radiusMd),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x05101828),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: value != null
                      ? Text(
                          _formatValue(value!),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        )
                      : Text(
                          placeholder,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                const Icon(
                  CupertinoIcons.calendar,
                  color: AppColors.mutedLight,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    final tempVal = value ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 300,
            color: AppColors.white.withValues(alpha: 0.95),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppColors.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select $label',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.light,
                    ),
                    child: CupertinoDatePicker(
                      mode: _getCupertinoMode(),
                      initialDateTime: tempVal,
                      use24hFormat: true,
                      onDateTimeChanged: onChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
