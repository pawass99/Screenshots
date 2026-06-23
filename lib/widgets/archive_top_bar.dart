import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ArchiveTopBar extends StatelessWidget {
  const ArchiveTopBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.titleStyle,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.md,
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.sm,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ScreenshotSpacing.tapTarget,
        ),
        child: Row(
          children: [
            if (leading case final leading?) ...[
              leading,
              const SizedBox(width: ScreenshotSpacing.sm),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle ?? ScreenshotTypography.archiveHeadline,
              ),
            ),
            ...(trailing == null ? const <Widget>[] : [trailing!]),
          ],
        ),
      ),
    );
  }
}

class ArchiveIconButton extends StatelessWidget {
  const ArchiveIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        width: ScreenshotSpacing.tapTarget,
        height: ScreenshotSpacing.tapTarget,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: 20,
          color: ScreenshotColors.onSurface,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x12EAE1DA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: const BorderSide(color: ScreenshotColors.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}
