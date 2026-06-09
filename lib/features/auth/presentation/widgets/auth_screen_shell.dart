import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.child,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ScreenshotSpacing.mobileMargin,
                  ScreenshotSpacing.xxl,
                  ScreenshotSpacing.mobileMargin,
                  ScreenshotSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow.toUpperCase(),
                      style: ScreenshotTypography.labelCaps,
                    ),
                    const SizedBox(height: ScreenshotSpacing.md),
                    Text(
                      title,
                      style: ScreenshotTypography.archiveDisplayTitle,
                    ),
                    const SizedBox(height: ScreenshotSpacing.md),
                    Text(
                      body,
                      style: ScreenshotTypography.bodyMedium.copyWith(
                        color: ScreenshotColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
