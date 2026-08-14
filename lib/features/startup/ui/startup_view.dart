import 'package:cuboid_flutter_template/core/constants/app_constants.dart';
import 'package:cuboid_flutter_template/core/constants/asset_paths.dart';
import 'package:cuboid_flutter_template/core/theme/app_colors.dart';
import 'package:cuboid_flutter_template/core/theme/ui_helpers.dart';
import 'package:cuboid_flutter_template/features/startup/ui/startup_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Brief branded splash shown while we check for an existing session.
class StartupView extends StackedView<StartupViewModel> {
  const StartupView({super.key});

  @override
  Widget builder(
    BuildContext context,
    StartupViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 128,
                height: 128,
                decoration: const BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary,
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Image.asset(AssetPaths.startupLogo),
              ),
              const SizedBox(height: s16),
              Text(
                AppConfig.appName,
                style: const TextStyle(
                  inherit: false,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  letterSpacing: -0.02,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  StartupViewModel viewModelBuilder(BuildContext context) => StartupViewModel();

  @override
  void onViewModelReady(StartupViewModel viewModel) =>
      WidgetsBinding.instance.addPostFrameCallback((_) => viewModel.init());
}
