import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ArchiveTextField extends StatelessWidget {
  const ArchiveTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: ScreenshotTypography.labelCaps),
        const SizedBox(height: ScreenshotSpacing.xs),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          cursorColor: ScreenshotColors.primary,
          style: ScreenshotTypography.bodyMedium.copyWith(
            color: ScreenshotColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: ScreenshotColors.deepestSurface,
            hintStyle: ScreenshotTypography.bodyMedium.copyWith(
              color: ScreenshotColors.onSurfaceVariant.withValues(alpha: 0.48),
            ),
            errorStyle: ScreenshotTypography.metadata.copyWith(
              color: ScreenshotColors.error,
              letterSpacing: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ScreenshotSpacing.md,
              vertical: ScreenshotSpacing.sm,
            ),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: ScreenshotColors.outlineVariant),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: ScreenshotColors.outlineVariant),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: ScreenshotColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: ScreenshotColors.error),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: ScreenshotColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
