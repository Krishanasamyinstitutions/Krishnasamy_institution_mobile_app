import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart' show parentAuthStateProvider;
import '../../providers/student_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // Pulse animation for loading
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    // Start logo animation
    _logoController.forward();

    // Wait a bit then start text animation
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();

    // Start pulse animation
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.repeat(reverse: true);

    // Navigate after animations
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // If using dummy data, always show onboarding for testing
    if (useDummyData) {
      if (!mounted) return;
      context.go(Routes.onboarding);
      return;
    }

    // Check parent auth state
    final parentAuthState = ref.read(parentAuthStateProvider);
    final isLoggedIn = parentAuthState.valueOrNull?.isAuthenticated ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      context.go(Routes.studentSelection);
    } else if (hasSeenOnboarding) {
      context.go(Routes.welcome);
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardGreen.withValues(alpha: 0.3),
              ),
            ),
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value,
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppColors.cardBg(context),
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                      spreadRadius: 0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Graduation cap icon
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            AppColors.primary,
                                            AppColors.primary600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: const Icon(
                                        Icons.school_rounded,
                                        size: 36,
                                        color: Colors.white,
                                      ),
                                    ),
                                    // Small payment badge
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF10B981),
                                              Color(0xFF059669),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppColors.cardBg(context),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.currency_rupee_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Animated text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        // App name
                        Text(
                          'SchoolPay',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimaryC(context),
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: AppColors.cardGreenDark,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Secure & Easy Fee Payments',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.cardGreenDark,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom loading indicator
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Column(
                children: [
                  // Loading dots animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final delay = index * 0.2;
                          final value = (_pulseController.value + delay) % 1.0;
                          final opacity = 0.3 + (0.7 * (value < 0.5 ? value * 2 : (1 - value) * 2));
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: opacity),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondaryC(context),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Version at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textOpacity,
              child: Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHintC(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
