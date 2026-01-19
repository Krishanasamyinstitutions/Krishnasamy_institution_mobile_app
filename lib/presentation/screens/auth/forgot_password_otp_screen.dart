import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String mobile;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.mobile,
  });

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends ConsumerState<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).verifyOtp(
        mobile: widget.mobile,
        otp: _otpController.text,
      );

      if (mounted) {
        // Navigate to reset password screen
        context.push(Routes.resetPassword, extra: widget.mobile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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

  Future<void> _handleResendOtp() async {
    if (_resendTimer > 0) return;

    try {
      await ref.read(authProvider.notifier).requestOtp(
        mobile: widget.mobile,
      );
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSizes.s2),

                      // Back Button
                      _buildBackButton(),

                      const SizedBox(height: AppSizes.s6),

                      // Header with title and illustration
                      _buildHeader(),

                      const SizedBox(height: AppSizes.s10),

                      // OTP Input
                      _buildOtpInput(),

                      const SizedBox(height: AppSizes.s6),

                      // Resend Timer
                      _buildResendTimer(),

                      const SizedBox(height: AppSizes.s8),

                      // Verify Button
                      _buildVerifyButton(),
                    ],
                  ),
                ),
              ),
            ),
            // Back to Sign In Link at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s6),
              child: _buildSignInLink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2933),
                  height: 1.27,
                ),
              ),
              const SizedBox(height: AppSizes.s2),
              Text(
                'Enter the 6-digit code sent to\n+91 ${widget.mobile}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                  height: 1.47,
                ),
              ),
            ],
          ),
        ),
        // Illustration
        SizedBox(
          width: 120,
          height: 120,
          child: Image.asset(
            'assets/Authendication gif/Sign up.gif',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2933),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.accent, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: const Color(0xFFF1F6FD),
        border: Border.all(color: AppColors.accent),
      ),
    );

    return Center(
      child: Pinput(
        controller: _otpController,
        length: 6,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        onCompleted: (_) => _handleVerifyOtp(),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Widget _buildResendTimer() {
    return Center(
      child: _resendTimer > 0
          ? RichText(
              text: TextSpan(
                text: 'Resend OTP in ',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                children: [
                  TextSpan(
                    text: '${_resendTimer}s',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: _handleResendOtp,
              child: const Text(
                'Resend OTP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
    );
  }

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleVerifyOtp,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3D75FC).withValues(alpha: 0.24),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else ...[
              const Text(
                'Verify OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.check_circle_outline,
                size: 24,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Remember your password ?',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.go(Routes.signIn),
          child: const Text(
            'Sign In',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.accent,
            ),
          ),
        ),
      ],
    );
  }
}
