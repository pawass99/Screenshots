import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenshots/features/auth/presentation/login_page.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _splashBackground = Color(0xFF111112);

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
      backgroundColor: _splashBackground,
      body: SafeArea(
        child: Center(
          child: disableMotion
              ? const _SplashMark()
              : FadeTransition(opacity: _opacity, child: const _SplashMark()),
        ),
      ),
    );
  }
}

class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      // Membuat wordmark utama splash screen.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SvgPicture.asset(
          'assets/images/screenshot_wordmark.svg',
          width: 369,
          height: 24,
          semanticsLabel: 'SCREENSHOT',
        ),
      ),
    );
  }
}
