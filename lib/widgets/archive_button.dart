import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

enum ArchiveButtonVariant { primary, ghost }

class ArchiveButton extends StatelessWidget {
  const ArchiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = ArchiveButtonVariant.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final ArchiveButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final primary = variant == ArchiveButtonVariant.primary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: ScreenshotSpacing.tapTarget),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: primary
                ? ScreenshotColors.primary
                : ScreenshotColors.surfaceLow,
            disabledBackgroundColor: primary
                ? ScreenshotColors.primary.withValues(alpha: 0.34)
                : ScreenshotColors.surfaceLow.withValues(alpha: 0.58),
            foregroundColor: primary
                ? ScreenshotColors.onPrimary
                : ScreenshotColors.onSurface,
            disabledForegroundColor: primary
                ? ScreenshotColors.onPrimary.withValues(alpha: 0.56)
                : ScreenshotColors.onSurfaceVariant.withValues(alpha: 0.5),
            minimumSize: const Size.fromHeight(ScreenshotSpacing.tapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
              side: primary
                  ? BorderSide.none
                  : const BorderSide(color: ScreenshotColors.outlineVariant),
            ),
            textStyle: ScreenshotTypography.labelCaps,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ScreenshotColors.onPrimary,
                  ),
                )
              : Text(label.toUpperCase()),
        ),
      ),
    );
  }
}
