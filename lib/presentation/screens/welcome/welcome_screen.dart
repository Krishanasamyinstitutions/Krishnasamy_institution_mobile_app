import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../widgets/common/desktop_left_panel.dart';
import '../../widgets/common/screen_illustrations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: context.isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ─── Mobile layout (existing design) ───────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                _buildLogo(context, 180),
                const SizedBox(height: 32),
                Text(
                  'SchoolPay',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pay school fees with ease',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
                const Spacer(),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.speed_rounded,
                  text: 'Quick & Easy Payments',
                  color: AppColors.cardPurple,
                  iconColor: AppColors.cardPurpleDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.security_rounded,
                  text: '100% Secure Transactions',
                  color: AppColors.cardGreen,
                  iconColor: AppColors.cardGreenDark,
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(
                  context: context,
                  icon: Icons.receipt_long_rounded,
                  text: 'Instant Digital Receipts',
                  color: AppColors.cardBlue,
                  iconColor: AppColors.cardBlueDark,
                ),
                const Spacer(),
                _buildSignInButton(context),
                const SizedBox(height: 12),
                _buildCreateAccountButton(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Desktop layout (split-screen) ─────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel — dark branding
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: 'Welcome to SchoolPay',
            subtitle: 'Pay school fees with ease',
            centerContent: ScreenIllustrations.welcomeDark(size: 360),
          ),
        ),

        // Right panel — features + actions
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get started with secure and hassle-free school fee payments.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryC(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.speed_rounded,
                      text: 'Quick & Easy Payments',
                      color: AppColors.cardPurple,
                      iconColor: AppColors.cardPurpleDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.security_rounded,
                      text: '100% Secure Transactions',
                      color: AppColors.cardGreen,
                      iconColor: AppColors.cardGreenDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context: context,
                      icon: Icons.receipt_long_rounded,
                      text: 'Instant Digital Receipts',
                      color: AppColors.cardBlue,
                      iconColor: AppColors.cardBlueDark,
                    ),
                    const SizedBox(height: 40),
                    _buildSignInButton(context),
                    const SizedBox(height: 12),
                    _buildCreateAccountButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────

  Widget _buildLogo(BuildContext context, double size) {
    return ScreenIllustrations.welcome(size: size);
  }

  Widget _buildSignInButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.signIn),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primary600],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.login_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(Routes.signUp),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.person_add_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String text,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: 20,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}
