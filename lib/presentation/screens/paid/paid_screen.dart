import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';

class PaidScreen extends ConsumerWidget {
  const PaidScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paidFees = ref.watch(paidFeesProvider);

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
          // Paid Fee List
          Expanded(
            child: paidFees.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: paidFees.length,
                    itemBuilder: (context, index) {
                      final fee = paidFees[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPaidCard(context, fee),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
            'Paid',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2933),
            ),
          ),

          // Notification Button
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
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidCard(BuildContext context, FeeModel fee) {
    return GestureDetector(
      onTap: () {
        // Navigate to receipt/details
      },
      child: Container(
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
          children: [
            // Top Row: Icon, Title, Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Green Icon Container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2DBE60),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getFeeIcon(fee.demfeetype),
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                // Title and Category Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fee.demfeeterm} - ${fee.demfeetype}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: AppSizes.fontNormal,
                          color: AppColors.textPrimary,
                          height: 1.47,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fee.demfeecategory ?? fee.demfeeyear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: AppSizes.fontNormal,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Amount and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Paid',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: AppSizes.fontSemibold,
                        color: Color(0xFF2DBE60),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(fee.paidamount.toInt())}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: AppSizes.fontSemibold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Date and Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Row(
                  children: [
                    const Text(
                      'Paid Date:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: AppSizes.fontNormal,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(fee.createdat),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: AppSizes.fontNormal,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                // Arrow
                Transform.rotate(
                  angle: 3.14159,
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon based on fee type
  IconData _getFeeIcon(String feeType) {
    final lowerType = feeType.toLowerCase();
    if (lowerType.contains('bus') || lowerType.contains('transport')) {
      return Icons.directions_bus;
    } else if (lowerType.contains('tuition') || lowerType.contains('term')) {
      return Icons.school;
    } else if (lowerType.contains('exam')) {
      return Icons.assignment;
    } else if (lowerType.contains('library')) {
      return Icons.local_library;
    } else if (lowerType.contains('lab')) {
      return Icons.science;
    } else if (lowerType.contains('sports')) {
      return Icons.sports_soccer;
    } else {
      return Icons.receipt;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Paid Fees',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your paid fee history will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.textSm,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
