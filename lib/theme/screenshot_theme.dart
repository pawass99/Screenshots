import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ScreenshotTheme {
  const ScreenshotTheme._();

  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ScreenshotColors.background,
      colorScheme: const ColorScheme.dark(
        primary: ScreenshotColors.primary,
        onPrimary: ScreenshotColors.onPrimary,
        secondary: ScreenshotColors.secondary,
        error: ScreenshotColors.error,
        surface: ScreenshotColors.surface,
        onSurface: ScreenshotColors.onSurface,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        displayLarge: ScreenshotTypography.largeDisplay,
        displayMedium: ScreenshotTypography.mediumDisplay,
        headlineMedium: ScreenshotTypography.headline,
        headlineSmall: ScreenshotTypography.smallHeadline,
        bodyLarge: ScreenshotTypography.bodyLarge,
        bodyMedium: ScreenshotTypography.bodyMedium,
        labelMedium: ScreenshotTypography.metadata,
        labelSmall: ScreenshotTypography.labelCaps,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: ScreenshotColors.primary,
        selectionColor: Color(0x44E4CD91),
        selectionHandleColor: ScreenshotColors.primary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ScreenshotColors.primary,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ScreenshotColors.primary,
          minimumSize: const Size(44, 44),
          textStyle: ScreenshotTypography.labelCaps,
        ),
      ),
      useMaterial3: true,
    );
  }
}
