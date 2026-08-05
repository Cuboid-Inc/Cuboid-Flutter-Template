import 'dart:ui';

import 'package:cuboid_flutter_template/features/home/ui/home_view.dart';
import 'package:cuboid_flutter_template/features/shell/shell_viewmodel.dart';
import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

/// Root shell: the four tabs (Home/Work/Money/More) matching the design's
/// TAB BAR, backed by an [IndexedStack] so each tab keeps its state.
/// Styled as an iOS 26 frosted glass floating capsule navigation bar.
class ShellView extends StackedView<ShellViewModel> {
  const ShellView({super.key});

  static const _tabs = [
    (
      label: 'Home',
      selectedIcon: CupertinoIcons.house_fill,
      unselectedIcon: CupertinoIcons.house,
      view: HomeView(),
    ),
  ];

  @override
  Widget builder(
    BuildContext context,
    ShellViewModel viewModel,
    Widget? child,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: viewModel.index,
            children: [for (final t in _tabs) t.view],
          ),
          // Floating Capsule Tab Bar (iOS 26 Style)
          Positioned(
            left: 20,
            right: 20,
            bottom: 28,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _TabButton(
                            label: _tabs[i].label,
                            selectedIcon: _tabs[i].selectedIcon,
                            unselectedIcon: _tabs[i].unselectedIcon,
                            selected: viewModel.index == i,
                            onTap: () => viewModel.setIndex(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  ShellViewModel viewModelBuilder(BuildContext context) => ShellViewModel();
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.muted.withValues(alpha: 0.7);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: selected ? 58 : 42,
            height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              selected ? selectedIcon : unselectedIcon,
              color: selected ? activeColor : inactiveColor,
              size: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? activeColor : inactiveColor,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
