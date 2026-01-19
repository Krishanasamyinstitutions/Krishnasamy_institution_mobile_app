import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../widgets/common/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Spacer(),

              SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  'assets/images/welcome.gif',
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: AppSizes.s6),

              const Text(
                'SchoolPay',
                style: TextStyle(
                  fontSize: AppSizes.text3xl,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSizes.s2),

              const Text(
                'Pay school fees with ease',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  color: AppColors.textSecondary,
                ),
              ),

              const Spacer(),

              _buildFeatureItem(
                icon: Icons.speed_rounded,
                text: 'Quick & Easy Payments',
              ),
              const SizedBox(height: AppSizes.s3),
              _buildFeatureItem(
                icon: Icons.security_rounded,
                text: '100% Secure Transactions',
              ),
              const SizedBox(height: AppSizes.s3),
              _buildFeatureItem(
                icon: Icons.receipt_long_rounded,
                text: 'Instant Digital Receipts',
              ),

              const Spacer(),

              AppButton(
                text: 'Sign In',
                onPressed: () => context.push(Routes.signIn),
                isFullWidth: true,
              ),

              const SizedBox(height: AppSizes.s3),

              AppButton(
                text: 'Create Account',
                onPressed: () => context.push(Routes.signUp),
                isFullWidth: true,
                variant: AppButtonVariant.outlined,
              ),

              const SizedBox(height: AppSizes.s4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent2,
            borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppSizes.s3),
        Text(
          text,
          style: const TextStyle(
            fontSize: AppSizes.textSm,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
