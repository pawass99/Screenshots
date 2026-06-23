import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/forgot_password_page.dart';
import 'package:screenshots/features/auth/presentation/reset_password_page.dart';
import 'package:screenshots/features/auth/presentation/sign_up_page.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/services/profile_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.initialMessage});

  final String? initialMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = const AuthService();
  final ProfileService _profileService = const ProfileService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final StreamSubscription<AuthState> _authStateSubscription;

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;
  String? _infoMessage;

  @override
  void initState() {
    super.initState();
    _infoMessage = widget.initialMessage;
    _authStateSubscription = _authService.onAuthStateChange.listen((data) {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.passwordRecovery) {
        Navigator.of(
          context,
        ).push(ArchivePageRoute(builder: (_) => const ResetPasswordPage()));
      } else if (data.event == AuthChangeEvent.signedIn &&
          data.session != null) {
        _handleSuccessfulLogin();
      }
    });
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSuccessfulLogin() async {
    if (!mounted) return;

    // Automatically provision profile if it's their first time
    await _profileService.ensureProfileExists();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      ArchivePageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
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
    } on AuthException catch (error) {
      setState(() {
        _formError = error.message;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _formError = 'Unable to open the archive right now.';
        _isLoading = false;
      });
    }
  }

  void _goToSignUp() {
    Navigator.of(
      context,
    ).push(ArchivePageRoute(builder: (_) => const SignUpPage()));
  }

  void _goToForgotPassword() {
    Navigator.of(
      context,
    ).push(ArchivePageRoute(builder: (_) => const ForgotPasswordPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final panelHeight = math.max(480.0, viewportHeight * 0.60);
          final contentHeight = math.max(viewportHeight, panelHeight + 140);

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: SizedBox(
                height: contentHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: viewportHeight * 0.15,
                      left: ScreenshotSpacing.mobileMargin,
                      right: ScreenshotSpacing.mobileMargin,
                      child: const _WelcomeHeader(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: panelHeight,
                      child: _SignInPanel(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        emailError: _emailError,
                        passwordError: _passwordError,
                        formError: _formError,
                        infoMessage: _infoMessage,
                        isLoading: _isLoading,
                        onSubmit: _submit,
                        onGoToSignUp: _goToSignUp,
                        onGoToForgotPassword: _goToForgotPassword,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Sign In.',
        style: TextStyle(
          fontFamily: 'LibreBaskerville',
          fontSize: 48,
          color: ScreenshotColors.onSurface,
        ),
      ),
    );
  }
}

class _SignInPanel extends StatelessWidget {
  const _SignInPanel({
    required this.emailController,
    required this.passwordController,
    required this.emailError,
    required this.passwordError,
    required this.formError,
    required this.infoMessage,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoToSignUp,
    required this.onGoToForgotPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final String? emailError;
  final String? passwordError;
  final String? formError;
  final String? infoMessage;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoToSignUp;
  final VoidCallback onGoToForgotPassword;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ScreenshotColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
        border: Border(
          top: BorderSide(color: ScreenshotColors.outlineVariant, width: 1),
          left: BorderSide(color: ScreenshotColors.outlineVariant, width: 1),
          right: BorderSide(color: ScreenshotColors.outlineVariant, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (infoMessage != null) ...[
                _AuthMessage(text: infoMessage!, tone: _AuthMessageTone.info),
                const SizedBox(height: ScreenshotSpacing.md),
              ],
              _SignInTextField(
                controller: emailController,
                label: 'Email',
                hintText: 'Your Email',
                errorText: emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 12),
              _SignInTextField(
                controller: passwordController,
                label: 'Password',
                hintText: 'Enter Your Password',
                errorText: passwordError,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: isLoading ? null : onGoToForgotPassword,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        fontFamily: 'Satoshi',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: ScreenshotColors.onSurfaceVariant,
                        decoration: TextDecoration.underline,
                        decorationColor: ScreenshotColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              if (formError != null) ...[
                const SizedBox(height: 12),
                _InlineFormWarning(text: formError!),
              ],
              const SizedBox(height: 24),
              _SignInButton(onPressed: onSubmit, isLoading: isLoading),
              const SizedBox(height: 16),
              _SignUpPrompt(onPressed: isLoading ? null : onGoToSignUp),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInTextField extends StatelessWidget {
  const _SignInTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: ScreenshotColors.outlineVariant, width: 1),
    );

    return Semantics(
      textField: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Satoshi',
                    fontSize: 14,
                    color: ScreenshotColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: hasError
                      ? Text(
                          errorText!,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Satoshi',
                            color: ScreenshotColors.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            cursorColor: ScreenshotColors.onSurface,
            style: TextStyle(
              fontFamily: 'Satoshi',
              fontSize: 16,
              color: ScreenshotColors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: ScreenshotColors.surfaceLow,
              hintStyle: TextStyle(
                fontFamily: 'Satoshi',
                fontSize: 16,
                color: ScreenshotColors.outline,
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              constraints: const BoxConstraints(minHeight: 60),
              border: border,
              enabledBorder: hasError
                  ? border.copyWith(
                      borderSide: BorderSide(
                        color: ScreenshotColors.error,
                        width: 1.2,
                      ),
                    )
                  : border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: hasError
                      ? ScreenshotColors.error
                      : ScreenshotColors.onSurfaceVariant,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: ScreenshotColors.primary,
          disabledBackgroundColor: ScreenshotColors.primary.withValues(
            alpha: 0.34,
          ),
          foregroundColor: ScreenshotColors.onPrimary,
          disabledForegroundColor: ScreenshotColors.onPrimary.withValues(
            alpha: 0.56,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: ScreenshotColors.onPrimary,
                ),
              )
            : const Text('Sign In'),
      ),
    );
  }
}

class _InlineFormWarning extends StatelessWidget {
  const _InlineFormWarning({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontFamily: 'Satoshi',
            color: ScreenshotColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SignUpPrompt extends StatelessWidget {
  const _SignUpPrompt({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 14,
            color: ScreenshotColors.onSurfaceVariant,
          ),
        ),
        InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              'Sign Up',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: ScreenshotColors.onSurface,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: ScreenshotColors.onSurface,
                decorationThickness: 1.5,
              ),
            ),
          ),
        ),
      ],
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
          borderRadius: BorderRadius.circular(14),
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
            style: TextStyle(
              fontFamily: 'Satoshi',
              color: isError
                  ? ScreenshotColors.error
                  : ScreenshotColors.onSurface,
              fontSize: 14,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
