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
    final feesByGroup = ref.watch(pendingFeesByGroupProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final overdueGroups = ref.watch(overdueByGroupProvider);
    final dueSoonGroups = ref.watch(dueSoonByGroupProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Column(
        children: [
          // Fixed Header with white SafeArea and subtle shadow
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildHeader(context, selectedStudent, cartItemCount),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 28),

                    // Balance Section
                    _buildBalanceSection(feeSummaryAsync),

                    const SizedBox(height: 20),

                    // Action Buttons
                    _buildActionButtons(context),

                    const SizedBox(height: 20),

                    // School Info Widget
                    _buildSchoolInfoWidget(),

                    const SizedBox(height: 28),

                    // Spending/Fee Categories Section
                    _buildSpendingSection(context, feesByGroup),

                    const SizedBox(height: 28),

                    // Activity Section - Overdue & Due Soon
                    _buildActivitySection(context, overdueGroups, dueSoonGroups),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic selectedStudent, int cartItemCount) {
    final studentName = selectedStudent?.name ?? 'Student';
    final className = selectedStudent?.className ?? 'N/A';
    final admissionNumber = selectedStudent?.admissionNumber ?? 'N/A';

    return Row(
      children: [
        // Profile Avatar
        GestureDetector(
          onTap: () => context.go(Routes.profile),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary600],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitials(studentName),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Student Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text(
                    'Adm No: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    admissionNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Text(
                    ' | Class: ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    className,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Cart Icon - Dark theme (same as View Details button)
        GestureDetector(
          onTap: () => context.push(Routes.cart),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/Cart.svg',
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                if (cartItemCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1F2937), width: 2),
                      ),
                      child: Text(
                        cartItemCount > 9 ? '9+' : '$cartItemCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
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
        const SizedBox(width: 10),
        // Notification Icon - Dark theme (same as View Details button)
        GestureDetector(
          onTap: () => context.go(Routes.notifications),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/notification.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceSection(AsyncValue<FeeSummary> feeSummaryAsync) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalPending = feeSummary?.totalPending ?? 0;

    // Get current academic year
    final now = DateTime.now();
    final academicYear = now.month >= 6
        ? '${now.year}-${now.year + 1}'
        : '${now.year - 1}-${now.year}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Balance Fees Due',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${NumberFormat('#,##,###').format(totalPending)}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '/',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              academicYear,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Pay Fees Button (Primary)
        Expanded(
          child: GestureDetector(
            onTap: () => context.push(Routes.payAllFees),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pay All Fees',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_outward_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Paid Fees Button (Secondary)
        Expanded(
          child: GestureDetector(
            onTap: () => context.go(Routes.paymentHistory),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Paid Fees',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolInfoWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // School Logo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardBlue,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/school_logo.png',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.school_rounded,
                    size: 28,
                    color: AppColors.cardBlueDark,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          // School Info
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TBS School',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Chennai, Tamil Nadu',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingSection(BuildContext context, Map<String, double> feesByGroup) {
    final categories = [
      {'name': 'School Fees', 'icon': Icons.school_rounded, 'color': AppColors.cardGreen, 'iconColor': AppColors.cardGreenDark},
      {'name': 'Van Fees', 'icon': Icons.directions_bus_rounded, 'color': AppColors.cardBlue, 'iconColor': AppColors.cardBlueDark},
      {'name': 'Exam Fees', 'icon': Icons.menu_book_rounded, 'color': AppColors.cardOrange, 'iconColor': AppColors.cardOrangeDark},
      {'name': 'Other', 'icon': Icons.more_horiz_rounded, 'color': AppColors.cardPurple, 'iconColor': AppColors.cardPurpleDark},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Dues',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(Routes.payAllFees),
              child: Text(
                'Show all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: feesByGroup.isEmpty ? categories.length : feesByGroup.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (feesByGroup.isEmpty) {
                final cat = categories[index];
                return _buildSpendingCard(
                  context: context,
                  icon: cat['icon'] as IconData,
                  label: cat['name'] as String,
                  groupName: cat['name'] as String,
                  amount: 0,
                  bgColor: cat['color'] as Color,
                  iconColor: cat['iconColor'] as Color,
                );
              }

              final entry = feesByGroup.entries.elementAt(index);
              final cat = categories[index % categories.length];
              return _buildSpendingCard(
                context: context,
                icon: cat['icon'] as IconData,
                label: _toTitleCase(entry.key),
                groupName: entry.key,
                amount: entry.value,
                bgColor: cat['color'] as Color,
                iconColor: cat['iconColor'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String groupName,
    required double amount,
    required Color bgColor,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(groupName)}'),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: iconColor),
                ),
                if (amount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Due',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 1),
              ],
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${NumberFormat('#,##,###').format(amount.toInt())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF1F2937),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context, List<FeeGroupSummary> overdueGroups, List<FeeGroupSummary> dueSoonGroups) {
    final hasOverdue = overdueGroups.isNotEmpty;
    final hasDueSoon = dueSoonGroups.isNotEmpty;
    final hasAnyFees = hasOverdue || hasDueSoon;

    // Calculate totals
    final totalOverdue = overdueGroups.fold(0.0, (sum, g) => sum + g.totalAmount);
    final totalDueSoon = dueSoonGroups.fold(0.0, (sum, g) => sum + g.totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fee Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            GestureDetector(
              onTap: () => context.push(Routes.allPendingFees),
              child: Text(
                'View all',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textLink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!hasAnyFees)
          _buildEmptyActivity()
        else ...[
          // Overdue Section
          if (hasOverdue) ...[
            _buildSectionTitle(
              title: 'Overdue',
              totalAmount: totalOverdue,
              color: AppColors.error,
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 12),
            ...overdueGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFeeGroupCard(context, group, AppColors.error, filterStatus: 'overdue'),
            )),
          ],
          if (hasOverdue && hasDueSoon)
            const SizedBox(height: 16),
          // Due Soon Section
          if (hasDueSoon) ...[
            _buildSectionTitle(
              title: 'Upcoming Due',
              totalAmount: totalDueSoon,
              color: AppColors.warning,
              icon: Icons.schedule_rounded,
            ),
            const SizedBox(height: 12),
            ...dueSoonGroups.map((group) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildFeeGroupCard(context, group, AppColors.warning, filterStatus: 'dueSoon'),
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required double totalAmount,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const Spacer(),
        Text(
          '₹${NumberFormat('#,##,###').format(totalAmount.toInt())}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeGroupCard(BuildContext context, FeeGroupSummary group, Color statusColor, {required String filterStatus}) {
    final isOverdue = group.isOverdue;
    final now = DateTime.now();
    String timeInfo = '';

    if (group.nearestDueDate != null) {
      if (isOverdue) {
        final days = now.difference(group.nearestDueDate!).inDays;
        timeInfo = '$days days overdue';
      } else {
        final days = group.nearestDueDate!.difference(now).inDays;
        timeInfo = days == 0 ? 'Due today' : 'Due in $days days';
      }
    }

    // Get icon based on group name
    IconData groupIcon = Icons.receipt_rounded;
    Color groupBg = AppColors.cardPurple;
    Color groupIconColor = AppColors.cardPurpleDark;

    final lowerName = group.groupName.toLowerCase();
    if (lowerName.contains('school') || lowerName.contains('tuition')) {
      groupIcon = Icons.school_rounded;
      groupBg = AppColors.cardGreen;
      groupIconColor = AppColors.cardGreenDark;
    } else if (lowerName.contains('van') || lowerName.contains('bus') || lowerName.contains('transport')) {
      groupIcon = Icons.directions_bus_rounded;
      groupBg = AppColors.cardBlue;
      groupIconColor = AppColors.cardBlueDark;
    } else if (lowerName.contains('exam')) {
      groupIcon = Icons.assignment_rounded;
      groupBg = AppColors.cardOrange;
      groupIconColor = AppColors.cardOrangeDark;
    }

    return GestureDetector(
      onTap: () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.15),
            width: 1,
          ),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(groupIcon, size: 22, color: groupIconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toTitleCase(group.groupName),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${group.itemCount} ${group.itemCount == 1 ? 'fee' : 'fees'}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (timeInfo.isNotEmpty) ...[
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.textHint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          timeInfo,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${NumberFormat('#,##,###').format(group.totalAmount.toInt())}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFF1F2937),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardGreen,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 32,
              color: AppColors.cardGreenDark,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No overdue or upcoming fees',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
