import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screenshots/features/auth/presentation/sign_up_page.dart';
import 'package:screenshots/features/home/presentation/home_page.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
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
    return Scaffold(
      backgroundColor: ScreenshotColors.deepestSurface,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final panelHeight = math.max(600.0, viewportHeight * 0.57);
          final contentHeight = math.max(viewportHeight, panelHeight + 330);

          // Membuat container utama halaman sign in.
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: viewportHeight),
              child: SizedBox(
                height: contentHeight,
                child: Stack(
                  children: [
                    // Membuat header welcome pada area gelap.
                    Positioned(
                      top: viewportHeight * 0.25,
                      left: ScreenshotSpacing.mobileMargin,
                      right: ScreenshotSpacing.mobileMargin,
                      child: const _WelcomeHeader(),
                    ),
                    // Membuat panel utama form sign in.
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
      // Membuat teks welcome back sebagai header visual.
      child: Text('Welcome Back!', style: ScreenshotTypography.signInWelcome),
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

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFD0D0D0),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(76)),
        border: Border.fromBorderSide(
          BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 1.4),
        ),
      ),
      child: SafeArea(
        top: false,
        // Membuat isi panel form sign in.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 52, 28, 30),
          child: Column(
            children: [
              Text('Sign In', style: ScreenshotTypography.signInTitle),
              const SizedBox(height: 52),
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
              const SizedBox(height: 1),
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
              const Spacer(),
              // Membuat button login utama.
              _SignInButton(onPressed: onSubmit, isLoading: isLoading),
              if (formError != null) ...[
                const SizedBox(height: 10),
                _InlineFormWarning(text: formError!),
              ],
              const Spacer(),
              // Membuat link menuju halaman sign up.
              _SignUpPrompt(onPressed: isLoading ? null : onGoToSignUp),
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
                const Spacer(),
                if (hasError)
                  Text(
                    errorText!,
                    textAlign: TextAlign.right,
                    style: ScreenshotTypography.signInFooter.copyWith(
                      color: const Color(0xFF8C1D18),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Membuat container input email atau password.
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
              constraints: const BoxConstraints(minHeight: 70),
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

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.onPressed, required this.isLoading});

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
      // Membuat warning credential di bawah button sign in.
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
          "Don't have any account? ",
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
          child: const Text('Sign Up'),
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
          color: const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isError ? const Color(0xFF8C1D18) : const Color(0xFF8D8D8D),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.md),
          child: Text(
            text,
            style: ScreenshotTypography.metadata.copyWith(
              color: isError ? const Color(0xFF8C1D18) : Colors.black,
              fontFamily: ScreenshotTypography.authBodyFamily,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
