import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';

class ScreenshotTypography {
  const ScreenshotTypography._();

  static const serifDisplayFamily = 'DMSerifDisplay';
  static const headlineSerifFamily = 'CormorantGaramond';

  static const largeDisplay = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 52,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    height: 0.92,
  );

  static const mediumDisplay = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 0.98,
  );

  static const headline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.05,
  );

  static const smallHeadline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.1,
  );

  static const bodyLarge = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static const bodyMedium = TextStyle(
    color: ScreenshotColors.onSurfaceVariant,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static const metadata = TextStyle(
    color: ScreenshotColors.onSurfaceVariant,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.9,
    height: 1.25,
  );

  static const labelCaps = TextStyle(
    color: ScreenshotColors.onSurface,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    height: 1.2,
  );

  static const serifDescription = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: serifDisplayFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.32,
  );

  static const archiveHeadline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: headlineSerifFamily,
    fontSize: 25,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1,
  );

  static const archiveSectionTitle = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: headlineSerifFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.05,
  );

  static const archiveDisplayTitle = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: headlineSerifFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 0.98,
  );
}
