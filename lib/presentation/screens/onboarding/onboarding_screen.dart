import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';

class OnboardingData {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final Color iconColor;
  final Color backgroundColor;

  const OnboardingData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.icon,
    this.imagePath,
    required this.iconColor,
    required this.backgroundColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      id: 1,
      title: 'Welcome to SchoolPay',
      subtitle: 'Simplify Your School Payments',
      description:
          'Pay fees, track dues, and get instant receipts—all in one app.',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Payment Information.gif',
      iconColor: AppColors.primary,
      backgroundColor: Color(0xFFE8F4FD),
    ),
    OnboardingData(
      id: 2,
      title: 'Easy, Secure & Instant',
      subtitle: 'Make Payments in Seconds',
      description:
          'Secure UPI & card payments, Instant receipt generation, Late fee alerts and reminders',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Two factor authentication.gif',
      iconColor: AppColors.success,
      backgroundColor: Color(0xFFE8F8F0),
    ),
    OnboardingData(
      id: 3,
      title: 'Stay Notified. Stay Ahead.',
      subtitle: 'Never Miss a Due Date',
      description:
          'Get notified before deadlines, View fee breakdown anytime, Auto-reminders & history log',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Push notifications.gif',
      iconColor: AppColors.warning,
      backgroundColor: Color(0xFFFFF8E8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      context.go(Routes.welcome);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation - Back Button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: AppSizes.s4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  _buildBackButton(),
                  // Empty space for balance
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Main Content with PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _OnboardingPage(data: _pages[index]),
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots
            _buildPaginationDots(),

            const SizedBox(height: AppSizes.s8),

            // Bottom Navigation - Skip and Next
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  _buildSkipButton(),
                  // Next/Get Started Button
                  _buildNextButton(isLastPage),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.s6),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    // Hide completely on first page
    if (_currentPage == 0) {
      return const SizedBox(width: 44, height: 44);
    }

    return GestureDetector(
      onTap: _previousPage,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 1,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: const Color(0xFFE5E7EB).withValues(alpha: 0.8),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: Color(0xFF1F2933),
        ),
      ),
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? AppColors.primary
                  : AppColors.gray300,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _completeOnboarding,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: const Text(
        'Skip',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2933),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isLastPage) {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.24),
              blurRadius: 1,
              offset: Offset.zero,
            ),
            const BoxShadow(
              color: Color(0xFFE5E7EB),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2933),
                height: 1.27,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Image/Icon Container
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 270, maxHeight: 270),
              child: data.imagePath != null
                  ? Image.asset(
                      data.imagePath!,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: data.backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          data.icon,
                          size: 120,
                          color: data.iconColor,
                        ),
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 30),

          // Subtitle and Description
          Container(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                // Subtitle (blue)
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 10),

                // Description
                SizedBox(
                  width: 261,
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                      height: 1.43,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
