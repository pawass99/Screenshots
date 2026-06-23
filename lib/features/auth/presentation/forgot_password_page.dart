import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final AuthService _authService = const AuthService();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _emailError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();

    setState(() {
      _emailError = email.isEmpty ? 'Email is required' : null;
      _formError = null;
    });

    if (_emailError != null) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(email);
      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
      }
    } on AuthException catch (error) {
      setState(() => _formError = error.message);
    } catch (_) {
      setState(() => _formError = 'Unable to send reset instructions right now.');
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
                      top: MediaQuery.paddingOf(context).top + 12,
                      left: ScreenshotSpacing.mobileMargin,
                      child: _BackArrowButton(
                        onPressed: _isLoading ? null : _goToLogin,
                      ),
                    ),
                    Positioned(
                      top: viewportHeight * 0.15,
                      left: ScreenshotSpacing.mobileMargin,
                      right: ScreenshotSpacing.mobileMargin,
                      child: const _ForgotPasswordHeader(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: panelHeight,
                      child: _ForgotPasswordPanel(
                        emailController: _emailController,
                        emailError: _emailError,
                        formError: _formError,
                        isLoading: _isLoading,
                        isSuccess: _isSuccess,
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
            foregroundColor: ScreenshotColors.onSurface,
            disabledForegroundColor: ScreenshotColors.onSurface.withValues(alpha: 0.45),
            backgroundColor: ScreenshotColors.surfaceLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: ScreenshotColors.outlineVariant),
            ),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
      ),
    );
  }
}

class _ForgotPasswordHeader extends StatelessWidget {
  const _ForgotPasswordHeader();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Forgot Password.',
        style: TextStyle(
          fontFamily: 'LibreBaskerville',
          fontSize: 48,
          color: ScreenshotColors.onSurface,
        ),
      ),
    );
  }
}

class _ForgotPasswordPanel extends StatelessWidget {
  const _ForgotPasswordPanel({
    required this.emailController,
    required this.emailError,
    required this.formError,
    required this.isLoading,
    required this.isSuccess,
    required this.onSubmit,
    required this.onGoToLogin,
  });

  final TextEditingController emailController;
  final String? emailError;
  final String? formError;
  final bool isLoading;
  final bool isSuccess;
  final VoidCallback onSubmit;
  final VoidCallback onGoToLogin;

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
          child: isSuccess
              ? _SuccessState(onGoToLogin: onGoToLogin)
              : _FormState(
                  emailController: emailController,
                  emailError: emailError,
                  formError: formError,
                  isLoading: isLoading,
                  onSubmit: onSubmit,
                ),
        ),
      ),
    );
  }
}

class _FormState extends StatelessWidget {
  const _FormState({
    required this.emailController,
    required this.emailError,
    required this.formError,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final String? emailError;
  final String? formError;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EmailTextField(
          controller: emailController,
          label: 'Email',
          hintText: 'Your Account Email',
          errorText: emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => onSubmit(),
        ),
        if (formError != null) ...[
          const SizedBox(height: 12),
          _InlineFormWarning(text: formError!),
        ],
        const SizedBox(height: 24),
        _SendResetButton(onPressed: onSubmit, isLoading: isLoading),
      ],
    );
  }
}

class _SuccessState extends StatelessWidget {
  const _SuccessState({required this.onGoToLogin});

  final VoidCallback onGoToLogin;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_rounded, size: 48, color: ScreenshotColors.primary),
        const SizedBox(height: 24),
        Text(
          'Password reset instructions have been sent to your email.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Satoshi',
            fontSize: 16,
            height: 1.5,
            color: ScreenshotColors.onSurface,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: onGoToLogin,
            style: OutlinedButton.styleFrom(
              backgroundColor: ScreenshotColors.surfaceLow,
              foregroundColor: ScreenshotColors.onSurface,
              side: BorderSide(color: ScreenshotColors.outlineVariant, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }
}

class _EmailTextField extends StatelessWidget {
  const _EmailTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: ScreenshotColors.outlineVariant,
        width: 1,
      ),
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
                  color: hasError ? ScreenshotColors.error : ScreenshotColors.onSurfaceVariant,
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

class _SendResetButton extends StatelessWidget {
  const _SendResetButton({required this.onPressed, required this.isLoading});

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
          disabledBackgroundColor: ScreenshotColors.primary.withValues(alpha: 0.34),
          foregroundColor: ScreenshotColors.onPrimary,
          disabledForegroundColor: ScreenshotColors.onPrimary.withValues(alpha: 0.56),
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
            : const Text('Send Reset Link'),
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
