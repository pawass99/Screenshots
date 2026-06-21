import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/login_page.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = const AuthService();
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _start();
  }

  Future<void> _start() async {
    _controller.forward();
    await Future<void>.delayed(const Duration(milliseconds: 950));

    if (!mounted) {
      return;
    }

    final destination = _authService.currentSession == null
        ? const LoginPage()
        : const HomePage();

    Navigator.of(
      context,
    ).pushReplacement(ArchivePageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.mobileMargin),
          child: Center(
            child: disableMotion
                ? const _SplashMark()
                : FadeTransition(opacity: _opacity, child: const _SplashMark()),
          ),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SCREENSHOT',
          style: ScreenshotTypography.smallHeadline.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: ScreenshotSpacing.sm),
        Text(
          'PRIVATE CINEMATIC ARCHIVE',
          style: ScreenshotTypography.labelCaps.copyWith(
            color: ScreenshotColors.primary,
          ),
        ),
      ],
    );
  }
}
