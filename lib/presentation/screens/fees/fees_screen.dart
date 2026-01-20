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
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  // Mock data for preview (remove this when real data is available)
  List<FeeModel> get _mockFees => [
    // Mandatory Fees
    FeeModel(
      demId: 1,
      demno: 'DEM001',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Term Fee',
      demfeecategory: 'Mandatory',
      feeamount: 25000,
      conId: 1,
      balancedue: 25000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 2,
      demno: 'DEM002',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Bus Fee',
      demfeecategory: 'Mandatory',
      feeamount: 8000,
      conId: 1,
      balancedue: 8000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    // Secondary Fees
    FeeModel(
      demId: 3,
      demno: 'DEM003',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Uniform & Text Book',
      demfeecategory: 'Secondary',
      feeamount: 4500,
      conId: 1,
      balancedue: 4500,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 4,
      demno: 'DEM004',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Extracurricular',
      demfeecategory: 'Secondary',
      feeamount: 3500,
      conId: 1,
      balancedue: 3500,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
    FeeModel(
      demId: 5,
      demno: 'DEM005',
      insId: 1,
      inscode: 'INS001',
      yrId: 1,
      demseqtype: 'T',
      stuId: 1,
      stuadmno: 'ADM001',
      stuclass: 'Grade 5',
      demfeeyear: '2025-2026',
      demfeeterm: 'Term 1',
      demfeetype: 'Lab Fee',
      demfeecategory: 'Secondary',
      feeamount: 2000,
      conId: 1,
      balancedue: 2000,
      paidstatus: 'U',
      createdby: 'system',
      createdat: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final feesAsync = ref.watch(feesProvider);
    final selectedStudent = ref.watch(selectedStudentProvider);

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
          // Content
          Expanded(
              child: feesAsync.when(
                loading: () => const LoadingIndicator(),
                error: (error, stack) => AppErrorWidget(
                  message: error.toString(),
                  onRetry: () => ref.refresh(feesProvider),
                ),
                data: (fees) {
                  // Use mock data if no real fees exist (for preview)
                  final displayFees = fees.isEmpty ? _mockFees : fees;

                  // Filter pending/overdue fees for selection (exclude zero amounts)
                  final pendingFees = displayFees
                      .where((f) =>
                          (f.status == FeeStatus.pending || f.status == FeeStatus.overdue) &&
                          f.balanceAmount > 0)
                      .toList();

                  if (pendingFees.isEmpty) {
                    return _buildEmptyState();
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildFeeBreakdownCard(pendingFees, selectedStudent?.name),
                  );
                },
              ),
            ),
          ],
        ),
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
      ),
    );
  }

  Widget _buildFeeBreakdownCard(List<FeeModel> fees, String? studentName) {
    // Get cart state for selected fees
    final cartState = ref.watch(cartProvider);

    // Calculate total of selected fees from this screen
    final selectedFees = fees.where((f) => cartState.containsFee(f.id)).toList();
    final totalAmount = selectedFees.fold(0.0, (sum, f) => sum + f.balanceAmount);

    // Get academic year and term from first fee (if available)
    const academicYear = 'Academic Year 2025-2026';
    final term = fees.isNotEmpty ? fees.first.term : 'Term 1';

    // Separate mandatory and secondary fees
    final mandatoryFees = fees.where((f) => f.demfeecategory == 'Mandatory').toList();
    final secondaryFees = fees.where((f) => f.demfeecategory != 'Mandatory').toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildCardHeader(academicYear, term),

            const SizedBox(height: AppSizes.s4),

            // Divider
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Mandatory Fees Section
            if (mandatoryFees.isNotEmpty) ...[
              _buildSectionHeader('Mandatory Fees', AppColors.error),
              const SizedBox(height: AppSizes.s3),
              ...mandatoryFees.map((fee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s2),
                child: _buildFeeItem(fee),
              )),
              const SizedBox(height: AppSizes.s4),
            ],

            // Secondary Fees Section
            if (secondaryFees.isNotEmpty) ...[
              _buildSectionHeader('Secondary Fees', AppColors.primary),
              const SizedBox(height: AppSizes.s3),
              ...secondaryFees.map((fee) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.s2),
                child: _buildFeeItem(fee),
              )),
              const SizedBox(height: AppSizes.s4),
            ],

            // Divider before total
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Total Amount
            _buildTotalRow(totalAmount),

            const SizedBox(height: AppSizes.s4),

            // Divider before button
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // View Cart Button
            _buildViewCartButton(totalAmount),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(String academicYear, String term) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee Breakdown',
              style: TextStyle(
                fontSize: AppSizes.sectionTitle,
                fontWeight: AppSizes.fontSemibold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s1),
            Text(
              academicYear,
              style: const TextStyle(
                fontSize: AppSizes.textXs,
                fontWeight: AppSizes.fontNormal,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.s3,
            vertical: AppSizes.s1 + 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            term,
            style: const TextStyle(
              fontSize: AppSizes.textXs,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textInverse,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppColors.divider,
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: AppSizes.textBase,
            fontWeight: AppSizes.fontSemibold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeItem(FeeModel fee) {
    final isSelected = ref.watch(cartProvider).containsFee(fee.id);

    // Determine subtitle based on fee type
    final isVanFee = fee.feeTypeName.toUpperCase().contains('VAN');
    String subtitle;

    if (isVanFee) {
      // For VAN FEES, show month from due date
      final month = fee.duedate != null
          ? DateFormat('MMMM yyyy').format(fee.duedate!)
          : fee.demfeeterm;
      final dueDate = fee.duedate != null
          ? DateFormat('dd MMM').format(fee.duedate!)
          : '';
      subtitle = dueDate.isNotEmpty ? '$month • Due: $dueDate' : month;
    } else {
      // For other fees, show term and due date
      final dueDate = fee.duedate != null
          ? DateFormat('dd MMM yyyy').format(fee.duedate!)
          : '';
      subtitle = dueDate.isNotEmpty
          ? '${fee.demfeeterm} • Due: $dueDate'
          : fee.demfeeterm;
    }

    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).toggleFee(fee);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Fee details
            Expanded(
              child: Text(
                fee.feeTypeName,
                style: TextStyle(
                  fontSize: AppSizes.bodyText,
                  fontWeight: isSelected ? AppSizes.fontMedium : AppSizes.fontNormal,
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  height: 1.47,
                ),
              ),
            ),
            // Amount and checkbox
            Row(
              children: [
                Text(
                  '₹ ${_formatAmount(fee.balanceAmount)}',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: isSelected ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 30),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(double totalAmount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total Amount',
          style: TextStyle(
            fontSize: AppSizes.sectionTitle,
            fontWeight: AppSizes.fontSemibold,
            color: AppColors.textPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.s2),
          child: Text(
            '₹ ${_formatAmount(totalAmount)}',
            style: const TextStyle(
              fontSize: AppSizes.sectionTitle,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewCartButton(double totalAmount) {
    final isEnabled = totalAmount > 0;
    final cartItemCount = ref.watch(cartItemCountProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () => context.go(Routes.cart) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s2,
              vertical: AppSizes.s3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
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
                const SizedBox(width: AppSizes.s2),
                Text(
                  'View Cart ($cartItemCount)',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: isEnabled ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSizes.s3),
                Icon(
                  Icons.arrow_forward,
                  size: 24,
                  color: isEnabled ? Colors.white : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    // Format with Indian number system (commas)
    if (amount == 0) return '0';

    final parts = amount.toStringAsFixed(0).split('');
    final result = <String>[];

    for (int i = 0; i < parts.length; i++) {
      if (i > 0) {
        final posFromEnd = parts.length - i;
        if (posFromEnd == 3 || (posFromEnd > 3 && (posFromEnd - 3) % 2 == 0)) {
          result.add(',');
        }
      }
      result.add(parts[i]);
    }

    return result.join('');
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
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSizes.s6),
            const Text(
              'No Fees Found',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s2),
            const Text(
              'There are no fees assigned to this student yet.',
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
