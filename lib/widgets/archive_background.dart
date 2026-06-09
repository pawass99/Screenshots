import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';

class ArchiveBackground extends StatelessWidget {
  const ArchiveBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ScreenshotColors.deepestSurface,
        gradient: RadialGradient(
          center: Alignment(0.72, -1.08),
          radius: 1.2,
          colors: [Color(0x22111112), ScreenshotColors.deepestSurface],
        ),
      ),
      child: child,
    );
  }
}
