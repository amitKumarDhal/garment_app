import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/sizes.dart';

class TCustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final String? prefixText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  // ✅ ADDED THESE PARAMETERS
  final TextInputAction? textInputAction;
  final int maxLines;

  const TCustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.prefixText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.textInputAction,

    // ✅ DEFAULT TO 1 LINE (Standard behavior)
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,

      // ✅ CONNECTED MAX LINES
      maxLines: maxLines,

      style: TextStyle(
        color: isDark ? Colors.white : TColors.textPrimary,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        alignLabelWithHint:
            maxLines > 1, // Ensures label stays at top for big text boxes
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          fontSize: 12,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : TColors.textSecondary,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                size: 20,
                color: isDark ? TColors.accent : TColors.primary,
              )
            : null,
        prefixText: prefixText,
        prefixStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? TColors.accent : TColors.primary,
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.all(TSizes.md),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.sm),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.sm),
          borderSide: const BorderSide(color: TColors.textSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TSizes.sm),
          borderSide: const BorderSide(color: TColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark ? TColors.dark : Colors.grey[50],
      ),
    );
  }
}
