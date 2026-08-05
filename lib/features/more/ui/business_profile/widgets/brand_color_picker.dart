import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

const _swatches = [
  0xFF11B2F3, // Sky (app primary)
  0xFF4F46E5, // Indigo
  0xFF0D9488, // Teal
  0xFFC2410C, // Rust
  0xFFBE123C, // Wine
  0xFF101828, // Ink
];

/// Letterhead accent color used on PDF invoices/statements headers.
class BrandColorPicker extends StatelessWidget {
  const BrandColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final swatch in _swatches)
        Padding(
          padding: const EdgeInsets.only(right: s12),
          child: GestureDetector(
            onTap: () => onChanged(swatch),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(swatch),
                shape: BoxShape.circle,
                border: value == swatch
                    ? Border.all(color: AppColors.ink, width: 2)
                    : null,
              ),
              child: value == swatch
                  ? const Icon(
                      CupertinoIcons.check_mark,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ),
        ),
    ],
  );
}
