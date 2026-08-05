import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/material.dart';

abstract final class AuthStyles {
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.navy, AppColors.primaryDark],
    ),
  );

  static const List<BoxShadow> logoShadow = [
    BoxShadow(color: AppColors.primary, blurRadius: 30, offset: Offset(0, 12)),
  ];

  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.white,
    letterSpacing: -0.02,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    color: AppColors.mutedLight,
  );

  static const TextStyle infoTextStyle = TextStyle(
    fontSize: 12.5,
    color: Color(0xFF7D92B4),
    height: 1.6,
  );
}
