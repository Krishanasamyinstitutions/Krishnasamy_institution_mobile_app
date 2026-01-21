import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final feeSummaryAsync = ref.watch(feeSummaryProvider);
    final pendingFees = ref.watch(pendingFeesProvider);

    // Calculate fees by category
    final feesByCategory = _calculateFeesByCategory(pendingFees);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Header with profile and notification
                _buildHeader(context, ref, selectedStudent),

                const SizedBox(height: 24),

                // Balance/Outstanding Amount
                _buildBalanceSection(feeSummaryAsync),

                const SizedBox(height: 16),

                // School name and location
                _buildSchoolInfo(selectedStudent),

                const SizedBox(height: 32),

                // Action Cards Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Fees Due',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(Routes.payAllFees),
                      child: const Text(
                        'Pay All Fees',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF007DFC),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Fee Cards Grid
                _buildFeeCardsGrid(context, feesByCategory),

                const SizedBox(height: 12),

                // Info Note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Color(0xFF0284C7),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on fee cards for details or use "Pay All Fees" to pay everything at once',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF0369A1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Calculate fees grouped by term and bus
  Map<String, double> _calculateFeesByCategory(List<FeeModel> fees) {
    double termFees = 0;
    double busFees = 0;

    for (final fee in fees) {
      final feeType = fee.demfeetype.toLowerCase();

      // Check if it's a bus fee
      if (feeType.contains('bus') || feeType.contains('transport') || feeType.contains('van')) {
        busFees += fee.balancedue;
      } else {
        // All term fees combined
        termFees += fee.balancedue;
      }
    }

    return {
      'termFees': termFees,
      'bus': busFees,
    };
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, dynamic selectedStudent) {
    final studentName = selectedStudent?.name ?? 'Student';
    final admNo = selectedStudent?.admissionNumber ?? 'N/A';
    final className = selectedStudent?.className ?? 'N/A';
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Row(
      children: [
        // Profile Image
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Icon(
            Icons.person,
            size: 28,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(width: 12),
        // Student Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2933),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Admn No: $admNo  |  Class: $className',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Cart Icon
        GestureDetector(
          onTap: () => context.push(Routes.cart),
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
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/Cart.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F2933),
                    BlendMode.srcIn,
                  ),
                ),
                if (cartItemCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        cartItemCount > 9 ? '9+' : '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Notification Icon
        GestureDetector(
          onTap: () => context.go(Routes.notifications),
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/images/notification.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F2933),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInfo(dynamic selectedStudent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // School Logo/Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEBF5FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF007DFC),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // School Name and Location
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ABC Higher Secondary School',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2933),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'No.12, Anna Nagar, 600118',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSection(AsyncValue<FeeSummary> feeSummaryAsync) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalOutstanding = feeSummary?.totalPending ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Amount
        Text(
          NumberFormat('#,##,###.00', 'en_IN').format(totalOutstanding),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2933),
            height: 1.1,
          ),
        ),

        const SizedBox(height: 8),

        // Currency indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFF007DFC),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'INR',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2933),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeeCardsGrid(BuildContext context, Map<String, double> feesByCategory) {
    return Column(
      children: [
        // First Row - Term Fees and Bus Fees
        Row(
          children: [
            Expanded(
              child: _buildFeeCard(
                icon: Icons.school_outlined,
                title: 'Term Fees',
                amount: feesByCategory['termFees'] ?? 0,
                backgroundColor: const Color(0xFFE8E4F3),
                iconColor: const Color(0xFF6B5B95),
                statusTag: 'Pending',
                onTap: () => context.push(Routes.pending, extra: {'feeType': 'term'}),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeeCard(
                svgAsset: 'assets/icons/bus-solid.svg',
                title: 'Bus Fees',
                amount: feesByCategory['bus'] ?? 0,
                backgroundColor: const Color(0xFFD4EDDA),
                iconColor: const Color(0xFF28A745),
                statusTag: 'Pending',
                onTap: () => context.push(Routes.pending, extra: {'feeType': 'bus'}),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second Row - Dummy Cards
        Row(
          children: [
            Expanded(
              child: _buildFeeCard(
                svgAsset: 'assets/nav bar icons/history stroke.svg',
                title: 'History',
                amount: 0,
                backgroundColor: const Color(0xFFFFF3CD),
                iconColor: const Color(0xFFD4A017),
                onTap: () => context.go(Routes.paymentHistory),
                isDummy: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFeeCard(
                icon: Icons.support_agent_outlined,
                title: 'Support',
                amount: 0,
                backgroundColor: const Color(0xFFE2E8F0),
                iconColor: const Color(0xFF64748B),
                onTap: () => context.push(Routes.support),
                isDummy: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeeCard({
    IconData? icon,
    String? svgAsset,
    required String title,
    required double amount,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
    bool isDummy = false,
    String? statusTag,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            // Icon and Status Tag Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with colored background
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: svgAsset != null
                        ? SvgPicture.asset(
                            svgAsset,
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                          )
                        : Icon(
                            icon,
                            size: 24,
                            color: iconColor,
                          ),
                  ),
                ),
                // Status Tag (top right)
                if (statusTag != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      statusTag,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Title and Arrow Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Title and Amount Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Amount or placeholder text
                      Text(
                        isDummy ? 'View details' : '₹ ${NumberFormat('#,##,###').format(amount.toInt())}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
