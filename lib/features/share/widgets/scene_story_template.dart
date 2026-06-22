import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class SceneStoryTemplate extends StatelessWidget {
  final String sceneImageUrl;
  final String description;
  final String? userProfileImageUrl;
  final GlobalKey? repaintBoundaryKey;

  const SceneStoryTemplate({
    super.key,
    required this.sceneImageUrl,
    required this.description,
    this.userProfileImageUrl,
    this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: repaintBoundaryKey,
      child: AspectRatio(
        aspectRatio: 1080 / 1920,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1 - Background
            if (sceneImageUrl.trim().isNotEmpty)
              CachedNetworkImage(
                imageUrl: sceneImageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    const ColoredBox(color: ScreenshotColors.background),
              )
            else
              const ColoredBox(color: ScreenshotColors.background),

            // Blur and Dark Overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.65)),
            ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 4),

                // Layer 2 - User Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ScreenshotColors.surfaceLow,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child:
                        userProfileImageUrl != null &&
                            userProfileImageUrl!.trim().isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: userProfileImageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const ColoredBox(
                              color: ScreenshotColors.surfaceLow,
                            ),
                            errorWidget: (context, url, error) =>
                                const _PlaceholderAvatar(),
                          )
                        : const _PlaceholderAvatar(),
                  ),
                ),

                const SizedBox(height: ScreenshotSpacing.xxl),

                // Layer 3 - Main Scene Card
                FractionallySizedBox(
                  widthFactor: 0.88,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: sceneImageUrl.trim().isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: sceneImageUrl,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                    height: 240,
                                    child: ColoredBox(
                                      color: ScreenshotColors.surfaceLow,
                                      child: Icon(
                                        Icons.broken_image_outlined,
                                        color: ScreenshotColors.outline,
                                      ),
                                    ),
                                  ),
                            )
                          : const SizedBox(
                              height: 240,
                              child: ColoredBox(
                                color: ScreenshotColors.surfaceLow,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: ScreenshotSpacing.xl),

                // Layer 4 - Description
                if (description.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ScreenshotSpacing.xl,
                    ),
                    child: _AdaptiveStoryDescription(description: description),
                  ),

                const SizedBox(height: ScreenshotSpacing.md),

                // Layer 5 - Branding
                FractionallySizedBox(
                  widthFactor: 0.46,
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.48),
                          height: 1,
                          thickness: 0.7,
                        ),
                      ),
                      const SizedBox(width: ScreenshotSpacing.sm),
                      Text(
                        'ON',
                        style: ScreenshotTypography.labelCaps.copyWith(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 9,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(width: ScreenshotSpacing.sm),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.48),
                          height: 1,
                          thickness: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: ScreenshotSpacing.sm),
                Image.asset(
                  'assets/images/Logo.png',
                  width: 132,
                  height: 20,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
                const Spacer(flex: 4),
                const SizedBox(height: ScreenshotSpacing.xxl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdaptiveStoryDescription extends StatelessWidget {
  const _AdaptiveStoryDescription({required this.description});

  final String description;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 112),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: constraints.maxWidth,
              child: Text(
                description.trim(),
                textAlign: TextAlign.center,
                style: ScreenshotTypography.quote.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.28,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlaceholderAvatar extends StatelessWidget {
  const _PlaceholderAvatar();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: ScreenshotColors.surfaceLow,
      child: Center(
        child: Icon(
          Icons.person_outline_rounded,
          color: ScreenshotColors.outline,
          size: 24,
        ),
      ),
    );
  }
}
