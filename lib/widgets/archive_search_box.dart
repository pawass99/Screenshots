import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ArchiveSearchBox extends StatelessWidget {
  const ArchiveSearchBox({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      cursorColor: ScreenshotColors.primary,
      style: ScreenshotTypography.bodyMedium.copyWith(
        color: ScreenshotColors.onSurface,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ScreenshotColors.onSurfaceVariant,
          size: 18,
        ),
        hintText: hintText,
        hintStyle: ScreenshotTypography.bodyMedium.copyWith(
          color: ScreenshotColors.outline,
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0x12EAE1DA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ScreenshotSpacing.md,
          vertical: ScreenshotSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScreenshotColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScreenshotColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: ScreenshotColors.primary),
        ),
      ),
    );
  }
}
