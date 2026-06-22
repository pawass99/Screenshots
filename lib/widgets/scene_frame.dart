import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class SceneFrame extends StatelessWidget {
  const SceneFrame({
    super.key,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.aspectRatio = 1.82,
    this.borderRadius = 18,
    this.imageFit = BoxFit.cover,
    this.onTap,
  });

  final String imageUrl;
  final String? title;
  final String? subtitle;
  final double aspectRatio;
  final double borderRadius;
  final BoxFit imageFit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final frame = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.trim().isEmpty)
              const ColoredBox(
                color: ScreenshotColors.surfaceLow,
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: ScreenshotColors.outline,
                ),
              )
            else
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: imageFit,
                fadeInDuration: const Duration(milliseconds: 220),
                placeholder: (context, url) => const ColoredBox(
                  color: ScreenshotColors.surfaceLow,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: ScreenshotColors.surfaceLow,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: ScreenshotColors.outline,
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x18000000), Color(0xB0000000)],
                ),
              ),
            ),
            if (title != null || subtitle != null)
              Positioned(
                left: ScreenshotSpacing.sm,
                right: ScreenshotSpacing.sm,
                bottom: ScreenshotSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ScreenshotTypography.labelCaps.copyWith(
                          color: ScreenshotColors.onSurface,
                          letterSpacing: 0,
                        ),
                      ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ScreenshotTypography.metadata.copyWith(
                          color: ScreenshotColors.onSurfaceVariant,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) {
      return frame;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: frame,
    );
  }
}
