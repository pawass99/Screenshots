import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/login_page.dart';
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

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthService _authService = const AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _passwordError = password.isEmpty
          ? 'Password is required'
          : password.length < 6
          ? 'Use at least 6 characters'
          : null;
      _confirmPasswordError = confirmPassword != password
          ? 'Passwords do not match'
          : null;
      _formError = null;
    });

    if (_emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
      );

      if (!mounted) {
        return;
      }

      if (response.session != null) {
        Navigator.of(context).pushAndRemoveUntil(
          ArchivePageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        ArchivePageRoute(
          builder: (_) => const LoginPage(
            initialMessage:
                'Account created. Check your email before entering the archive.',
          ),
        ),
      );
    } on AuthException catch (error) {
      setState(() => _formError = error.message);
    } catch (_) {
      setState(() => _formError = 'Unable to create an archive account.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      eyebrow: 'New Archive',
      title: 'Start collecting cinematic references.',
      body:
          'Create an account for saved scenes, movie records, and future collections.',
      child: AuthEntrance(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_formError != null) ...[
              _AuthMessage(text: _formError!),
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
              hintText: 'Minimum 6 characters',
              errorText: _passwordError,
              obscureText: true,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: ScreenshotSpacing.lg),
            ArchiveTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hintText: 'Repeat your archive key',
              errorText: _confirmPasswordError,
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: ScreenshotSpacing.xl),
            ArchiveButton(
              label: 'Create Archive',
              onPressed: _submit,
              isLoading: _isLoading,
            ),
            const SizedBox(height: ScreenshotSpacing.md),
            ArchiveButton(
              label: 'Back to Login',
              onPressed: _isLoading ? null : _goToLogin,
              variant: ArchiveButtonVariant.ghost,
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ScreenshotColors.surfaceLow,
          border: Border.all(color: ScreenshotColors.error),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.md),
          child: Text(
            text,
            style: ScreenshotTypography.metadata.copyWith(
              color: ScreenshotColors.error,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
