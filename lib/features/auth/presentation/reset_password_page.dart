import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final AuthService _authService = const AuthService();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  bool _isSuccess = false;
  String? _passwordError;
  String? _confirmError;
  String? _formError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validatePassword(String password) {
    if (password.length < 6) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  Future<void> _submit() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _passwordError = null;
      _confirmError = null;
      _formError = null;
    });

    bool hasError = false;

    if (!_validatePassword(password)) {
      setState(() {
        _passwordError = 'Min 6 chars, 1 upper, 1 lower, 1 number';
      });
      hasError = true;
    }

    if (password != confirm) {
      setState(() {
        _confirmError = 'Passwords do not match';
      });
      hasError = true;
    }

    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await _authService.updatePassword(password);
      if (mounted) {
        setState(() {
          _isSuccess = true;
        });
      }
    } on AuthException catch (error) {
      setState(() => _formError = error.message);
    } catch (_) {
      setState(() => _formError = 'Unable to reset password right now.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewportHeight = constraints.maxHeight;
          final panelHeight = math.max(540.0, viewportHeight * 0.65);
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
                      child: const _ResetPasswordHeader(),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: panelHeight,
                      child: _ResetPasswordPanel(
                        passwordController: _passwordController,
                        confirmController: _confirmController,
                        passwordError: _passwordError,
                        confirmError: _confirmError,
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

class _ResetPasswordHeader extends StatelessWidget {
  const _ResetPasswordHeader();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        'Reset Password.',
        style: TextStyle(
          fontFamily: 'LibreBaskerville',
          fontSize: 48,
          color: ScreenshotColors.onSurface,
        ),
      ),
    );
  }
}

class _ResetPasswordPanel extends StatelessWidget {
  const _ResetPasswordPanel({
    required this.passwordController,
    required this.confirmController,
    required this.passwordError,
    required this.confirmError,
    required this.formError,
    required this.isLoading,
    required this.isSuccess,
    required this.onSubmit,
    required this.onGoToLogin,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String? passwordError;
  final String? confirmError;
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
                  passwordController: passwordController,
                  confirmController: confirmController,
                  passwordError: passwordError,
                  confirmError: confirmError,
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
    required this.passwordController,
    required this.confirmController,
    required this.passwordError,
    required this.confirmError,
    required this.formError,
    required this.isLoading,
    required this.onSubmit,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final String? passwordError;
  final String? confirmError;
  final String? formError;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PasswordTextField(
          controller: passwordController,
          label: 'New Password',
          hintText: 'Create Your Password',
          errorText: passwordError,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        _PasswordTextField(
          controller: confirmController,
          label: 'Confirm New Password',
          hintText: 'Confirm Your Password',
          errorText: confirmError,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        if (formError != null) ...[
          const SizedBox(height: 12),
          _InlineFormWarning(text: formError!),
        ],
        const SizedBox(height: 24),
        _UpdateButton(onPressed: onSubmit, isLoading: isLoading),
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
        const Icon(Icons.check_circle_outline_rounded, size: 48, color: ScreenshotColors.primary),
        const SizedBox(height: 24),
        Text(
          'Password updated successfully.',
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

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final TextInputAction? textInputAction;
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
            obscureText: true,
            textInputAction: textInputAction,
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

class _UpdateButton extends StatelessWidget {
  const _UpdateButton({required this.onPressed, required this.isLoading});

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
            : const Text('Update Password'),
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
