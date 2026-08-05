import 'package:fleetgo/ui/common/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Global iOS-style app bar: centered title, chevron back button, and
/// consistently styled actions. Use this instead of raw [AppBar] everywhere.
class AppBarIOS extends StatelessWidget implements PreferredSizeWidget {
  const AppBarIOS({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
    this.showBackButton = true,
  });

  final String title;
  final List<Widget>? actions;

  /// Overrides the default pop behavior (e.g. a multi-step wizard's "back").
  final VoidCallback? onBack;

  /// Set false to force-hide the back button even if the route can pop.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final canPop = onBack != null || (ModalRoute.of(context)?.canPop ?? false);
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
      leading: showBackButton && canPop
          ? IconButton(
              icon: const Icon(CupertinoIcons.chevron_back, size: 22),
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Text-style [AppBarIOS] action (e.g. Edit, Cancel, Invite).
class AppBarTextAction extends StatelessWidget {
  const AppBarTextAction({
    super.key,
    required this.label,
    this.onPressed,
    this.showDot = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Shows a small dot next to the label, e.g. to flag a non-default filter.
  final bool showDot;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Badge(
      isLabelVisible: showDot,
      smallSize: 7,
      alignment: AlignmentDirectional.topEnd,
      offset: const Offset(4, -2),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.primary,
        ),
      ),
    ),
  );
}

/// Icon-style [AppBarIOS] action (e.g. add, share, export).
class AppBarIconAction extends StatelessWidget {
  const AppBarIconAction({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) =>
      IconButton(icon: Icon(icon), onPressed: onPressed, tooltip: tooltip);
}
