import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final String pattern; // Regex pattern for validation

  const CountryCode({
    required this.flag,
    required this.code,
    required this.country,
    required this.phoneLength,
    required this.pattern,
  });
}

// Countries where parents might be located (NRI parents, etc.)
// Note: Some countries have overlapping number formats, OTP verification confirms validity
const _countryCodes = [
  CountryCode(
    flag: '🇮🇳',
    code: '+91',
    country: 'India',
    phoneLength: 10,
    pattern: r'^[6-9][0-9]{9}$', // Indian mobile: starts with 6, 7, 8, or 9
  ),
  CountryCode(
    flag: '🇦🇪',
    code: '+971',
    country: 'UAE',
    phoneLength: 9,
    pattern: r'^5[0-9]{8}$', // UAE mobile: starts with 5
  ),
  CountryCode(
    flag: '🇸🇦',
    code: '+966',
    country: 'Saudi Arabia',
    phoneLength: 9,
    pattern: r'^5[0-9]{8}$', // Saudi mobile: starts with 5
  ),
  CountryCode(
    flag: '🇸🇬',
    code: '+65',
    country: 'Singapore',
    phoneLength: 8,
    pattern: r'^[89][0-9]{7}$', // Singapore mobile: starts with 8 or 9
  ),
  CountryCode(
    flag: '🇦🇺',
    code: '+61',
    country: 'Australia',
    phoneLength: 9,
    pattern: r'^4[0-9]{8}$', // Australian mobile: starts with 4
  ),
  CountryCode(
    flag: '🇺🇸',
    code: '+1',
    country: 'USA / Canada',
    phoneLength: 10,
    pattern: r'^[2-9][0-9]{2}[2-9][0-9]{6}$', // NANP format
  ),
  CountryCode(
    flag: '🇬🇧',
    code: '+44',
    country: 'United Kingdom',
    phoneLength: 10,
    pattern: r'^7[0-9]{9}$', // UK mobile: starts with 7
  ),
];

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
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

  /// Cross-check if the entered number looks like it belongs to a different country
  /// Returns an error message if mismatch detected, null otherwise
  String? _crossCheckCountryNumber(String number, int selectedIndex) {
    final selectedCountry = _countryCodes[selectedIndex];

    // Check against other countries with same phone length
    for (int i = 0; i < _countryCodes.length; i++) {
      if (i == selectedIndex) continue;

      final otherCountry = _countryCodes[i];

      // Only cross-check countries with the same phone length
      if (otherCountry.phoneLength != number.length) continue;

      final otherRegex = RegExp(otherCountry.pattern);
      if (otherRegex.hasMatch(number)) {
        // Special case: Indian numbers are very distinctive (start with 6-9)
        // If user selected non-India but number matches Indian pattern
        if (otherCountry.code == '+91' && selectedCountry.code != '+91') {
          return 'This looks like an Indian number. Please select India (+91) as your country';
        }

        // Special case: UAE/Saudi numbers both start with 5
        // Don't warn between these two as they're similar
        if ((selectedCountry.code == '+971' && otherCountry.code == '+966') ||
            (selectedCountry.code == '+966' && otherCountry.code == '+971')) {
          continue;
        }

        // For other mismatches where the number clearly matches another country's pattern
        // but doesn't match selected country's pattern well
        final selectedRegex = RegExp(selectedCountry.pattern);
        if (!selectedRegex.hasMatch(number) && otherRegex.hasMatch(number)) {
          return 'This number appears to be from ${otherCountry.country}. Please select the correct country';
        }
      }
    }

    return null;
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
                        // Clear mobile input when country changes
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
      final selectedCountry = _countryCodes[_selectedCountryIndex];
      await ref.read(authProvider.notifier).requestOtp(
            mobile: _mobileController.text,
            countryCode: selectedCountry.code,
          );

      if (mounted) {
        context.push(
          Routes.otpVerification,
          extra: _mobileController.text,
        );
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
            duration: const Duration(seconds: 4),
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
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),

                          // Back Button
                          _buildBackButton(),

                          const SizedBox(height: 24),

                          // Header with title and illustration
                          _buildHeader(),

                          const SizedBox(height: 32),

                          // Mobile Number Field
                          _buildMobileField(),

                          const SizedBox(height: 32),

                          // Get OTP Button
                          _buildGetOtpButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Sign In Link at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
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
        decoration: const BoxDecoration(
          color: Color(0xFF1F2937),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: Colors.white,
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
              Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your Account !',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textTertiary,
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

            // Validate against country-specific pattern
            final regex = RegExp(selectedCountry.pattern);
            if (!regex.hasMatch(value)) {
              return 'Please enter a valid ${selectedCountry.country} mobile number';
            }

            // Cross-country validation: Check if number looks like it belongs to another country
            final crossCheckResult = _crossCheckCountryNumber(value, _selectedCountryIndex);
            if (crossCheckResult != null) {
              return crossCheckResult;
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
              SvgPicture.asset(
                'assets/school Icons/shield-tick.svg',
                width: 22,
                height: 22,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
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
        Text(
          'Already have an Account ?',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.push(Routes.signIn),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
