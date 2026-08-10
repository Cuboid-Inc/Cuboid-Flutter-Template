import 'package:nemara_homes/core/theme/app_colors.dart';
import 'package:nemara_homes/core/theme/ui_helpers.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

class AppDropdown<T> extends StatefulWidget {
  const AppDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.itemBuilder,
    this.selectedItemBuilder,
    this.hintText,
    this.validator,
  });

  final String label;
  final T? value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;
  final Widget Function(BuildContext, T)? itemBuilder;
  final List<Widget> Function(BuildContext)? selectedItemBuilder;
  final String? hintText;
  final FormFieldValidator<T>? validator;

  @override
  State<AppDropdown<T>> createState() => _AppDropdownState<T>();
}

class _AppDropdownState<T> extends State<AppDropdown<T>> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.06,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: s8),
        // Listener (not GestureDetector) so it never competes with the
        // dropdown's own tap recognizer — just watches raw pointer events
        // to drive an iOS-style press-dim instead of the Material ripple.
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _setPressed(true),
          onPointerUp: (_) => _setPressed(false),
          onPointerCancel: (_) => _setPressed(false),
          child: AnimatedOpacity(
            opacity: _pressed ? 0.4 : 1,
            duration: const Duration(milliseconds: 120),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
              ),
              child: DropdownButtonFormField<T>(
                initialValue: widget.value,
                validator: widget.validator,
                onChanged: widget.onChanged,
                selectedItemBuilder: widget.selectedItemBuilder,
                hint: widget.hintText != null
                    ? Text(
                        widget.hintText!,
                        style: const TextStyle(
                          color: AppColors.mutedLight,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                icon: const Icon(
                  CupertinoIcons.chevron_down,
                  color: AppColors.muted,
                ),
                isExpanded: true,
                dropdownColor: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                items: widget.items.map((T item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: widget.itemBuilder != null
                        ? widget.itemBuilder!(context, item)
                        : Text(
                            widget.itemLabelBuilder(item),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
