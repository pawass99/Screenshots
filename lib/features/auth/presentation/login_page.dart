import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/sign_up_page.dart';
import 'package:screenshots/features/auth/presentation/widgets/auth_entrance.dart';
import 'package:screenshots/features/auth/presentation/widgets/auth_screen_shell.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_button.dart';
import 'package:screenshots/widgets/archive_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = const AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _infoMessage = widget.initialMessage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _passwordError = password.isEmpty ? 'Password is required' : null;
      _formError = null;
      _infoMessage = null;
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signIn(email: email, password: password);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        ArchivePageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    } on AuthException catch (error) {
      setState(() => _formError = error.message);
    } catch (_) {
      setState(() => _formError = 'Unable to open the archive right now.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToSignUp() {
    Navigator.of(
      context,
    ).push(ArchivePageRoute(builder: (_) => const SignUpPage()));
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      eyebrow: 'Archive Access',
      title: 'Enter your private frame library.',
      body:
          'Sign in to continue collecting scenes, movie records, and visual references.',
      child: AuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_infoMessage != null) ...[
              _AuthMessage(text: _infoMessage!, tone: _AuthMessageTone.info),
              const SizedBox(height: ScreenshotSpacing.md),
            ],
            if (_formError != null) ...[
              _AuthMessage(text: _formError!, tone: _AuthMessageTone.error),
              const SizedBox(height: ScreenshotSpacing.md),
            ],
            ArchiveTextField(
              controller: _emailController,
              label: 'Email',
              hintText: 'name@example.com',
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: ScreenshotSpacing.lg),
            ArchiveTextField(
              controller: _passwordController,
              label: 'Password',
              hintText: 'Your archive key',
              errorText: _passwordError,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: ScreenshotSpacing.xl),
            ArchiveButton(
              label: 'Enter Archive',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: ScreenshotSpacing.md),
            ArchiveButton(
              label: 'Create Account',
              onPressed: _isLoading ? null : _goToSignUp,
              variant: ArchiveButtonVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }
}

enum _AuthMessageTone { info, error }

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.text, required this.tone});

  final String text;
  final _AuthMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final isError = tone == _AuthMessageTone.error;

    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ScreenshotColors.surfaceLow,
          border: Border.all(
            color: isError
                ? ScreenshotColors.error
                : ScreenshotColors.outlineVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.md),
          child: Text(
            text,
            style: ScreenshotTypography.metadata.copyWith(
              color: isError
                  ? ScreenshotColors.error
                  : ScreenshotColors.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
