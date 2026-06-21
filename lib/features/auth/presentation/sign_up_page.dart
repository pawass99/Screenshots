import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/login_page.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
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
    return Scaffold(
      backgroundColor: ScreenshotColors.deepestSurface,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final panelHeight = math.max(680.0, viewportHeight * 0.66);
          final contentHeight = math.max(viewportHeight, panelHeight + 260);

          // Membuat container utama halaman sign up.
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: SizedBox(
                height: contentHeight,
                child: Stack(
                  children: [
                    // Membuat tombol kembali di pojok kiri atas.
                    Positioned(
                      top: MediaQuery.paddingOf(context).top + 12,
                      left: ScreenshotSpacing.mobileMargin,
                      child: _BackArrowButton(
                        onPressed: _isLoading ? null : _goToLogin,
                      ),
                    ),
                    // Membuat header create account pada area gelap.
                    Positioned(
                      top: viewportHeight * 0.2,
                      left: ScreenshotSpacing.mobileMargin,
                      right: ScreenshotSpacing.mobileMargin,
                      child: const _SignUpHeader(),
                    ),
                    // Membuat panel utama form sign up.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: panelHeight,
                      child: _SignUpPanel(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        confirmPasswordController: _confirmPasswordController,
                        emailError: _emailError,
                        passwordError: _passwordError,
                        confirmPasswordError: _confirmPasswordError,
                        formError: _formError,
                        isLoading: _isLoading,
                        onSubmit: _submit,
                        onGoToLogin: _goToLogin,
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

class _BackArrowButton extends StatelessWidget {
  const _BackArrowButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back to login',
      child: SizedBox(
        width: ScreenshotSpacing.tapTarget,
        height: ScreenshotSpacing.tapTarget,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
            ),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
    );
  }
}

class _SignUpHeader extends StatelessWidget {
  const _SignUpHeader();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      // Membuat teks create account sebagai header visual.
      child: Text('Sign Up Here.', style: ScreenshotTypography.signInWelcome),
    );
  }
}

class _SignUpPanel extends StatelessWidget {
  const _SignUpPanel({
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.emailError,
    required this.passwordError,
    required this.confirmPasswordError,
    required this.formError,
    required this.isLoading,
    required this.onSubmit,
    required this.onGoToLogin,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? formError;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFD0D0D0),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(76)),
        border: Border.fromBorderSide(
          BorderSide(color: Colors.black, width: 1.4),
        ),
      ),
      child: SafeArea(
        top: false,
        // Membuat isi panel form sign up.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 58, 28, 30),
          child: Column(
            children: [
              _SignUpTextField(
                controller: emailController,
                label: 'Email',
                hintText: 'Your Email',
                errorText: emailError,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
              ),
              const SizedBox(height: 5),
              _SignUpTextField(
                controller: passwordController,
                label: 'Password',
                hintText: 'Create Your Password',
                errorText: passwordError,
                obscureText: true,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 5),
              _SignUpTextField(
                controller: confirmPasswordController,
                label: 'Confirm Password',
                hintText: 'Repeat Your Password',
                errorText: confirmPasswordError,
                obscureText: true,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => onSubmit(),
              ),
              const Spacer(),
              // Membuat button register utama.
              _SignUpButton(onPressed: onSubmit, isLoading: isLoading),
              if (formError != null) ...[
                const SizedBox(height: 10),
                _InlineFormWarning(text: formError!),
              ],
              const Spacer(),
              // Membuat link kembali ke halaman login.
              _LoginPrompt(onPressed: isLoading ? null : onGoToLogin),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpTextField extends StatelessWidget {
  const _SignUpTextField({
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
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    );

    return Semantics(
      textField: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Membuat label dan warning field di luar container input.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(label, style: ScreenshotTypography.signInFieldLabel),
                const SizedBox(width: 10),
                Expanded(
                  child: hasError
                      ? Text(
                          errorText!,
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: ScreenshotTypography.signInFooter.copyWith(
                            color: const Color(0xFF8C1D18),
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
          // Membuat container input sign up.
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            onSubmitted: onSubmitted,
            cursorColor: Colors.black,
            style: ScreenshotTypography.signInFieldInput,
            decoration: InputDecoration(
              hintText: hintText,
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              hintStyle: ScreenshotTypography.signInFieldHint,
              contentPadding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
              constraints: const BoxConstraints(minHeight: 82),
              border: border,
              enabledBorder: hasError
                  ? border.copyWith(
                      borderSide: const BorderSide(
                        color: Color(0xFF8C1D18),
                        width: 1.2,
                      ),
                    )
                  : border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: hasError ? const Color(0xFF8C1D18) : Colors.black,
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

class _SignUpButton extends StatelessWidget {
  const _SignUpButton({required this.onPressed, required this.isLoading});

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF111111),
          disabledBackgroundColor: const Color(
            0xFF111111,
          ).withValues(alpha: 0.55),
          foregroundColor: const Color(0xFFEDEDED),
          disabledForegroundColor: const Color(
            0xFFEDEDED,
          ).withValues(alpha: 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: ScreenshotTypography.signInButton,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Color(0xFFEDEDED),
                ),
              )
            : const Text('Sign Up'),
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
      // Membuat warning form di bawah button sign up.
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: ScreenshotTypography.signInFooter.copyWith(
            color: const Color(0xFF8C1D18),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: ScreenshotTypography.signInFooter,
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: ScreenshotTypography.signInFooter.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Sign In'),
        ),
      ],
    );
  }
}
