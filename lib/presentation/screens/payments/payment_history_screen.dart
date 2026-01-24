import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/student_avatar.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final paidFees = ref.watch(paidFeesProvider);

    // Status-based filter tabs
    final filters = ['All', 'Paid', 'Failed'];

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
                const SizedBox(height: 24),
                // Filter Tabs
                _buildFilterTabs(filters),
                const SizedBox(height: 16),
              ],
            ),
          ),
            // Transaction List
            Expanded(
              child: _buildTransactionList(paidFees),
            ),
          ],
        ),
    );
  }

  List<FeeModel> _filterFees(List<FeeModel> fees) {
    if (_activeFilter == 'All') return fees;
    if (_activeFilter == 'Paid') {
      return fees.where((f) => f.paidstatus == 'P').toList();
    }
    if (_activeFilter == 'Failed') {
      return fees.where((f) => f.paidstatus != 'P').toList();
    }
    return fees;
  }

  Widget _buildTransactionList(List<FeeModel> fees) {
    final filteredFees = _filterFees(fees);

    if (filteredFees.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildTransactionCard(filteredFees[index]);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final studentName = selectedStudent?.name ?? 'Student';
    final admNo = selectedStudent?.admissionNumber ?? 'N/A';
    final className = selectedStudent?.className ?? 'N/A';
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Profile Image
          StudentAvatar.medium(studentName: studentName),
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
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 24,
                    color: Color(0xFF1F2933),
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

  Widget _buildFilterTabs(List<String> filters) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isActive = _activeFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _activeFilter = filter;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isActive ? const Color(0xFF1F2933) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? null
                      : Border.all(
                          color: const Color(0xFF6B7280),
                          width: 1,
                        ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: isActive
                        ? const Color(0xFFFAFAFA)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTransactionCard(FeeModel fee) {
    final isPaid = fee.paidstatus == 'P';
    final statusColor =
        isPaid ? const Color(0xFF2DBE60) : const Color(0xFFDC2626);

    return GestureDetector(
      onTap: () => context.push('/fees/${fee.demId}'),
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
          children: [
            // Top Row: Icon, Fee Name, Category | Status, Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                _buildTransactionIcon(fee.demfeetype, isPaid),
                const SizedBox(width: 10),
                // Fee Name and Category
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fee.demfeeterm} - ${fee.demfeetype}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF1F2933),
                          height: 1.47,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        fee.demfeecategory ?? fee.demfeeyear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B7280),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status and Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPaid ? 'Paid' : 'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(fee.paidamount.toInt())}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2933),
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom Row: Date | Arrow
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
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF1F2933),
                        height: 1.43,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMM yyyy').format(fee.createdat),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                        height: 1.43,
                      ),
                    ),
                  ],
                ),
                // Arrow Icon (rotated to point right)
                Transform.rotate(
                  angle: 3.14159, // 180 degrees
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 24,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(String feeType, bool isPaid) {
    final bgColor = isPaid ? const Color(0xFF2DBE60) : const Color(0xFFDC2626);
    final lowerType = feeType.toLowerCase();

    IconData iconData;
    if (!isPaid) {
      iconData = Icons.close;
    } else if (lowerType.contains('bus') || lowerType.contains('transport')) {
      iconData = Icons.directions_bus;
    } else if (lowerType.contains('tuition') || lowerType.contains('term')) {
      iconData = Icons.school;
    } else if (lowerType.contains('exam')) {
      iconData = Icons.assignment;
    } else if (lowerType.contains('library')) {
      iconData = Icons.local_library;
    } else if (lowerType.contains('lab')) {
      iconData = Icons.science;
    } else if (lowerType.contains('sports')) {
      iconData = Icons.sports_soccer;
    } else {
      iconData = Icons.description;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 24,
        color: Colors.white,
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_activeFilter) {
      case 'Paid':
        title = 'No Paid Payments';
        subtitle = 'Your successful payments will appear here.';
        icon = Icons.check_circle_outline;
        break;
      case 'Failed':
        title = 'No Failed Payments';
        subtitle = 'Failed payment attempts will appear here.';
        icon = Icons.error_outline;
        break;
      default:
        title = 'No Payments Yet';
        subtitle = 'Your payment history will appear here once you make a payment.';
        icon = Icons.receipt_long_rounded;
    }

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
              child: Icon(
                icon,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSizes.s6),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
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
