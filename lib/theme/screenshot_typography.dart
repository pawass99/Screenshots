import 'package:flutter/material.dart';
import 'package:screenshots/theme/screenshot_colors.dart';

class ScreenshotTypography {
  const ScreenshotTypography._();

  static const filmTitleFamily = 'Tropikal';
  static const quoteFamily = 'Maghfirea';
  static const sceneDescriptionFamily = 'LibreBaskerville';
  static const metadataFamily = 'Iosevka';
  static const uiFamily = 'Inter';

  static const serifDisplayFamily = sceneDescriptionFamily;
  static const headlineSerifFamily = filmTitleFamily;
  static const splashWordmarkFamily = 'FutureTense';
  static const authHeaderFamily = uiFamily;
  static const authBodyFamily = uiFamily;

  static const largeDisplay = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: filmTitleFamily,
    fontSize: 52,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 0.92,
  );

  static const mediumDisplay = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: filmTitleFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 0.98,
  );

  static const headline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: uiFamily,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.05,
  );

  static const smallHeadline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: uiFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.1,
  );

  static const bodyLarge = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: uiFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static const bodyMedium = TextStyle(
    color: ScreenshotColors.onSurfaceVariant,
    fontFamily: uiFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.45,
  );

  static const metadata = TextStyle(
    color: ScreenshotColors.onSurfaceVariant,
    fontFamily: metadataFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.9,
    height: 1.25,
  );

  static const labelCaps = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: metadataFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    height: 1.2,
  );

  static const serifDescription = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: sceneDescriptionFamily,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.32,
  );

  static const sceneDescription = serifDescription;

  static const quote = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: quoteFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.28,
  );

  static const archiveHeadline = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: uiFamily,
    fontSize: 25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1,
  );

  static const archiveSectionTitle = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: uiFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.05,
  );

  static const archiveDisplayTitle = TextStyle(
    color: ScreenshotColors.onSurface,
    fontFamily: filmTitleFamily,
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 0.98,
  );

  static const splashWordmark = TextStyle(
    color: Colors.white,
    fontFamily: splashWordmarkFamily,
    fontSize: 54,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1,
  );

  static const signInWelcome = TextStyle(
    color: Colors.white,
    fontFamily: authHeaderFamily,
    fontSize: 48,
    fontWeight: FontWeight.w200,
    letterSpacing: 0,
    height: 1,
  );

  static const signInTitle = TextStyle(
    color: Colors.black,
    fontFamily: authBodyFamily,
    fontSize: 42,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.05,
  );

  static const signInFieldLabel = TextStyle(
    color: Colors.black,
    fontFamily: authBodyFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  static const signInFieldInput = TextStyle(
    color: Colors.black,
    fontFamily: authBodyFamily,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
  );

  static const signInFieldHint = TextStyle(
    color: Color(0xFF343434),
    fontFamily: authBodyFamily,
    fontSize: 15,
    fontStyle: FontStyle.normal,
    fontWeight: FontWeight.w300,
    letterSpacing: 0,
    height: 1.2,
  );

  static const signInButton = TextStyle(
    color: Color(0xFFEDEDED),
    fontFamily: authBodyFamily,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1,
  );

  static const signInFooter = TextStyle(
    color: Colors.black,
    fontFamily: authBodyFamily,
    fontSize: 15,
    fontWeight: FontWeight.w200,
    letterSpacing: 0,
    height: 1.2,
  );
}
