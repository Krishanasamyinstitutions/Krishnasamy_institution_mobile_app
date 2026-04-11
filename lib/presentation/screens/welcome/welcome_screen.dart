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

  // ─── Mobile layout — reference image style ───────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F1EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
                  // Title
                  const Text(
                    'Welcome to\nSchoolPay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  const Text(
                    'Your go-to destination for smart, fast, and hassle-free fee payments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9E9E9E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Feature items
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.speed_rounded,
                    text: 'Quick & Easy Payments',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.security_rounded,
                    text: '100% Secure Transactions',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    text: 'Instant Digital Receipts',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 32),
                  // Sign In — dark button
                  _buildSignInButton(context),
                  const SizedBox(height: 12),
                  // Create Account — outlined
                  _buildCreateAccountButton(context),
                  const SizedBox(height: 24),
                ],
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
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign In',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 10),
            Icon(Icons.login_rounded, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    final isMobile = !context.isDesktop;
    return GestureDetector(
      onTap: () => context.push(Routes.signUp),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isMobile ? Colors.white : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMobile ? const Color(0xFFE8E7E4) : AppColors.primary,
            width: isMobile ? 1 : 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isMobile ? const Color(0xFF1A1A1A) : AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.person_add_rounded,
              size: 20,
              color: isMobile ? const Color(0xFF1A1A1A) : AppColors.primary,
            ),
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
        borderRadius: BorderRadius.circular(12),
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
              shape: BoxShape.circle,
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
