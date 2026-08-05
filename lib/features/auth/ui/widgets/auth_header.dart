import 'package:flutter/material.dart';
import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:fleetgo/ui/common/ui_helpers.dart';
import 'package:fleetgo/features/auth/ui/widgets/auth_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    this.icon,
    this.logoAsset,
    required this.title,
    required this.subtitle,
  }) : assert(
         icon != null || logoAsset != null,
         'Provide either icon or logoAsset',
       );

  final IconData? icon;
  final String? logoAsset;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: logoAsset == null
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  )
                : null,
            borderRadius: BorderRadius.circular(radiusLg),
            boxShadow: AuthStyles.logoShadow,
          ),
          child: logoAsset != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(radiusLg),
                  child: Image.asset(logoAsset!, fit: BoxFit.cover),
                )
              : Icon(icon, color: AppColors.white, size: 38),
        ),
        const SizedBox(height: s16),
        Text(title, textAlign: TextAlign.center, style: AuthStyles.titleStyle),
        const SizedBox(height: s4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AuthStyles.subtitleStyle,
        ),
      ],
    );
  }
}
