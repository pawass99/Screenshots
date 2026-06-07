import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class MetadataChip extends StatelessWidget {
  const MetadataChip({
    super.key,
    required this.label,
    this.isActive = false,
    this.onPressed,
  });

  final String label;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: isActive ? const Color(0x1CE4CD91) : const Color(0x12EAE1DA),
        border: Border.all(
          color: isActive
              ? ScreenshotColors.primary
              : ScreenshotColors.outlineVariant,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ScreenshotSpacing.sm,
          vertical: ScreenshotSpacing.xs,
        ),
        child: Text(
          label.toUpperCase(),
          style: ScreenshotTypography.metadata.copyWith(
            color: isActive
                ? ScreenshotColors.onSurface
                : ScreenshotColors.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ),
    );

    if (onPressed == null) {
      return child;
    }

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}
