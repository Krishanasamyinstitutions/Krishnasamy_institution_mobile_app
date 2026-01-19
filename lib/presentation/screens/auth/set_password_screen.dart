import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  final String mobile;
  final bool isResetPassword;

  const SetPasswordScreen({
    super.key,
    required this.mobile,
    this.isResetPassword = false,
  });

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.isResetPassword) {
        // Reset password flow
        await ref.read(authProvider.notifier).resetPassword(
          mobile: widget.mobile,
          newPassword: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go(Routes.signIn);
        }
      } else {
        // Sign up flow - use completeAccountCreation to UPDATE existing parent record
        await ref.read(authProvider.notifier).completeAccountCreation(
          mobile: widget.mobile,
          password: _passwordController.text,
        );

        if (mounted) {
          context.go(Routes.studentSelection);
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        // Clean up exception prefix for user-friendly display
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isResetPassword ? 'Reset Password' : 'Set Password',
                  style: const TextStyle(
                    fontSize: AppSizes.text2xl,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSizes.s2),
                Text(
                  widget.isResetPassword
                      ? 'Create a new password for your account'
                      : 'Create a secure password for your account',
                  style: const TextStyle(
                    fontSize: AppSizes.textBase,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSizes.s8),

                AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  isPassword: true,
                  prefixIcon: Icons.lock_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.s4),

                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  isPassword: true,
                  prefixIcon: Icons.lock_rounded,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSizes.s4),

                Container(
                  padding: const EdgeInsets.all(AppSizes.s4),
                  decoration: BoxDecoration(
                    color: AppColors.gray50,
                    borderRadius: BorderRadius.circular(AppSizes.roundedLg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password must:',
                        style: TextStyle(
                          fontSize: AppSizes.textSm,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.s2),
                      _buildRequirement('Be at least 8 characters'),
                      _buildRequirement('Include uppercase & lowercase letters'),
                      _buildRequirement('Include at least one number'),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.s8),

                AppButton(
                  text: widget.isResetPassword ? 'Reset Password' : 'Create Account',
                  onPressed: _handleSetPassword,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.s1),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSizes.s2),
          Text(
            text,
            style: const TextStyle(
              fontSize: AppSizes.textSm,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
