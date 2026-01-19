import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart';

class CountryCode {
  final String flag;
  final String code;
  final String country;
  final int phoneLength;
  final String pattern;

  const CountryCode({
    required this.flag,
    required this.code,
    required this.country,
    required this.phoneLength,
    required this.pattern,
  });
}

const _countryCodes = [
  CountryCode(
    flag: '🇮🇳',
    code: '+91',
    country: 'India',
    phoneLength: 10,
    pattern: r'^[6-9][0-9]{9}$',
  ),
  CountryCode(
    flag: '🇦🇪',
    code: '+971',
    country: 'UAE',
    phoneLength: 9,
    pattern: r'^5[0-9]{8}$',
  ),
  CountryCode(
    flag: '🇸🇦',
    code: '+966',
    country: 'Saudi Arabia',
    phoneLength: 9,
    pattern: r'^5[0-9]{8}$',
  ),
  CountryCode(
    flag: '🇸🇬',
    code: '+65',
    country: 'Singapore',
    phoneLength: 8,
    pattern: r'^[89][0-9]{7}$',
  ),
  CountryCode(
    flag: '🇦🇺',
    code: '+61',
    country: 'Australia',
    phoneLength: 9,
    pattern: r'^4[0-9]{8}$',
  ),
  CountryCode(
    flag: '🇺🇸',
    code: '+1',
    country: 'USA / Canada',
    phoneLength: 10,
    pattern: r'^[2-9][0-9]{2}[2-9][0-9]{6}$',
  ),
  CountryCode(
    flag: '🇬🇧',
    code: '+44',
    country: 'United Kingdom',
    phoneLength: 10,
    pattern: r'^7[0-9]{9}$',
  ),
];

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _mobileFocusNode = FocusNode();
  bool _isLoading = false;
  int _selectedCountryIndex = 0;

  @override
  void dispose() {
    _mobileController.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Country',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2933),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _countryCodes.length,
                itemBuilder: (context, index) {
                  final country = _countryCodes[index];
                  return ListTile(
                    leading: Text(
                      country.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      country.country,
                      style: const TextStyle(
                        fontSize: AppSizes.textSm,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: Text(
                      country.code,
                      style: const TextStyle(
                        fontSize: AppSizes.textSm,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCountryIndex = index;
                        _mobileController.clear();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).requestOtp(
        mobile: _mobileController.text,
      );

      if (mounted) {
        context.push(
          Routes.forgotPasswordOtp,
          extra: _mobileController.text,
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                  child: Form(
                    key: _formKey,
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

                        // Mobile Number Field
                        _buildMobileField(),

                        const SizedBox(height: AppSizes.s8),

                        // Get OTP Button
                        _buildGetOtpButton(),
                      ],
                    ),
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forgot Password',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2933),
                  height: 1.27,
                ),
              ),
              SizedBox(height: AppSizes.s2),
              Text(
                'Enter your mobile number to reset your password',
                style: TextStyle(
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

  Widget _buildMobileField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _mobileController,
          focusNode: _mobileFocusNode,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2933),
          ),
          decoration: InputDecoration(
            hintText: 'Enter mobile number',
            hintStyle: const TextStyle(
              fontSize: 15,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF007DFC), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            prefixIcon: GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _countryCodes[_selectedCountryIndex].flag,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _countryCodes[_selectedCountryIndex].code,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(_countryCodes[_selectedCountryIndex].phoneLength),
          ],
          validator: (value) {
            final selectedCountry = _countryCodes[_selectedCountryIndex];

            if (value == null || value.isEmpty) {
              return 'Please enter your mobile number';
            }

            if (value.length != selectedCountry.phoneLength) {
              return 'Please enter a valid ${selectedCountry.phoneLength}-digit ${selectedCountry.country} number';
            }

            final regex = RegExp(selectedCountry.pattern);
            if (!regex.hasMatch(value)) {
              return 'Please enter a valid ${selectedCountry.country} mobile number';
            }

            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGetOtpButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleRequestOtp,
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
                'Get OTP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.verified_user_outlined,
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
