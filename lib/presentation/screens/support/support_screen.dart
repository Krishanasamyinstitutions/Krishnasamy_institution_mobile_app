import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  int _openFaqIndex = 0;

  final List<Map<String, String>> _faqs = [
    {
      'question': "How do I pay my child's fees online?",
      'answer':
          "Go to the \"Fee Details\" page, review the pending dues, and click on the 'Pay Now' button. Choose your preferred payment method and complete the transaction.",
    },
    {
      'question': 'What payment methods are accepted?',
      'answer':
          'We accept various payment methods including credit/debit cards, net banking, UPI, and digital wallets.',
    },
    {
      'question': 'Will I receive a receipt after payment?',
      'answer':
          'Yes, you will receive a digital receipt via email immediately after successful payment completion.',
    },
    {
      'question': 'What happens if I miss a payment due date?',
      'answer':
          'Late fees may apply if payment is not received by the due date. Please contact the school administration for assistance.',
    },
  ];

  // Mock contact info
  final String _schoolEmail = 'johnson@gmail.com';
  final String _schoolPhone = '+84 414 323 567';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          // Header with SafeArea
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contact School Card
                      _buildContactCard(),
                      const SizedBox(height: 24),
                      // FAQ's Title
                      const Text(
                        "FAQ's",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: AppSizes.fontSemibold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // FAQ Items
                      ..._faqs.asMap().entries.map((entry) {
                        final index = entry.key;
                        final faq = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFaqItem(
                            question: faq['question']!,
                            answer: faq['answer']!,
                            isOpen: _openFaqIndex == index,
                            onToggle: () {
                              setState(() {
                                _openFaqIndex = _openFaqIndex == index ? -1 : index;
                              });
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.go(Routes.home),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Color(0xFF1F2933),
                ),
              ),
            ),
          ),

          // Title
          const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2933),
            ),
          ),

          // Empty space for alignment
          const SizedBox(width: 44, height: 44),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Contact School',
            style: TextStyle(
              fontSize: 18,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          // Divider
          Container(
            height: 1,
            color: const Color(0xFFAAD4FD),
          ),
          const SizedBox(height: 20),
          // Email Row
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppSizes.fontNormal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                _schoolEmail,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: AppSizes.fontNormal,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Phone Row
          Row(
            children: [
              const SizedBox(
                width: 60,
                child: Padding(
                  padding: EdgeInsets.only(left: 9),
                  child: Text(
                    'Phone',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppSizes.fontNormal,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                _schoolPhone,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: AppSizes.fontNormal,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required String question,
    required String answer,
    required bool isOpen,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: const Color(0xFF808087).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0051C6).withValues(alpha: 0.5),
                    blurRadius: 1,
                    offset: Offset.zero,
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF005FCC).withValues(alpha: 0.12),
                    blurRadius: 2,
                    spreadRadius: 1,
                    offset: Offset.zero,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child: Column(
            children: [
              // Question Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 2, right: 16),
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: AppSizes.fontSemibold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: isOpen ? 3.14159 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 24,
                      color: Color(0xFF1F2933),
                    ),
                  ),
                ],
              ),
              // Answer (shown when open)
              if (isOpen) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0051C6).withValues(alpha: 0.35),
                        blurRadius: 1,
                        spreadRadius: 0,
                        offset: Offset.zero,
                      ),
                      BoxShadow(
                        color: const Color(0xFF0051C6).withValues(alpha: 0.2),
                        blurRadius: 2,
                        spreadRadius: 0,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                  child: Text(
                    answer,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: AppSizes.fontNormal,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
