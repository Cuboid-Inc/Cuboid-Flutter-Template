import 'package:cuboid_flutter_template/ui/common/app_colors.dart';
import 'package:cuboid_flutter_template/ui/common/ui_helpers.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// Labeled text field: uppercase muted label above a filled input,
/// matching the design's form fields.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.autofillHints,
    this.textInputAction,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.showVisibilityToggle = false,
    this.enabled = true,
    this.validator,
    this.maxLength,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final bool enableSuggestions;
  final bool autocorrect;
  final bool showVisibilityToggle;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final int? maxLength;
  final Widget? prefixIcon;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Column(
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
          TextFormField(
            controller: widget.controller,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            obscureText: _obscureText,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            autofillHints: widget.autofillHints,
            textInputAction: widget.textInputAction,
            enableSuggestions: widget.enableSuggestions,
            autocorrect: widget.autocorrect,
            validator: widget.validator,
            maxLength: widget.maxLength,
            buildCounter: widget.maxLength == null
                ? null
                : (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              errorStyle: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.showVisibilityToggle
                  ? IconButton(
                      tooltip: _obscureText ? 'Show password' : 'Hide password',
                      onPressed: widget.enabled
                          ? () => setState(() => _obscureText = !_obscureText)
                          : null,
                      icon: Icon(
                        _obscureText
                            ? CupertinoIcons.eye
                            : CupertinoIcons.eye_slash,
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
