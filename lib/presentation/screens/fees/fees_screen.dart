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
import '../../providers/drawer_provider.dart';
import '../../widgets/common/loading_indicator.dart';
import '../../widgets/common/error_widget.dart';

class FeesScreen extends ConsumerStatefulWidget {
  const FeesScreen({super.key});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  final Set<String> _selectedFeeIds = {};

  // Mock data for preview (remove this when real data is available)
  List<FeeModel> get _mockFees => [
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
      demfeetype: 'Uniform & Text Book',
      feeamount: 4500,
      conId: 1,
      balancedue: 4500,
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
      demfeetype: 'Extracurricular',
      feeamount: 4500,
      conId: 1,
      balancedue: 4500,
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
      backgroundColor: AppColors.bgSecondary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Custom Header
            _buildHeader(context),
            const SizedBox(height: 10),
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
                    padding: const EdgeInsets.all(AppSizes.s6),
                    child: _buildFeeBreakdownCard(pendingFees, selectedStudent?.name),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Menu Button
          GestureDetector(
            onTap: () => openMainDrawer(ref),
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF808087).withValues(alpha: 0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 5),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0051C6).withValues(alpha: 0.75),
                    blurRadius: 1,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/menu.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF1F2933),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Title
          const Text(
            'Fees Details',
            style: TextStyle(
              fontSize: AppSizes.sectionTitle,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),

          // Notification Button
          GestureDetector(
            onTap: () => context.push(Routes.notifications),
            child: Stack(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF808087).withValues(alpha: 0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0051C6).withValues(alpha: 0.75),
                        blurRadius: 1,
                        offset: Offset.zero,
                      ),
                    ],
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/images/notification.svg',
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF1F2933),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 24,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
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

  Widget _buildFeeBreakdownCard(List<FeeModel> fees, String? studentName) {
    // Calculate total of selected fees
    final totalAmount = fees
        .where((f) => _selectedFeeIds.contains(f.id))
        .fold(0.0, (sum, f) => sum + f.balanceAmount);

    // Get academic year and term from first fee (if available)
    final academicYear = 'Academic Year 2025-2026';
    final term = fees.isNotEmpty ? fees.first.term : 'Term 1';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.roundedXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF808087).withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFF0051C6).withOpacity(0.75),
            blurRadius: 1,
            spreadRadius: 0,
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

            // Table Header
            _buildTableHeader(),

            const SizedBox(height: AppSizes.s4),

            // Fee Items
            ...fees.map((fee) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.s2),
              child: _buildFeeItem(fee),
            )),

            // Divider before total
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Total Amount
            _buildTotalRow(totalAmount),

            const SizedBox(height: AppSizes.s4),

            // Divider before button
            _buildDivider(),

            const SizedBox(height: AppSizes.s4),

            // Pay Now Button
            _buildPayNowButton(totalAmount),
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
            borderRadius: BorderRadius.circular(5),
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

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.s2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Particular',
            style: TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
          // Add padding to align with amount values (checkbox 24px + gap 30px + container padding 12px)
          Padding(
            padding: const EdgeInsets.only(right: 66),
            child: const Text(
              'Amount',
              style: TextStyle(
                fontSize: AppSizes.textBase,
                fontWeight: AppSizes.fontSemibold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeItem(FeeModel fee) {
    final isSelected = _selectedFeeIds.contains(fee.id);

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
        setState(() {
          if (isSelected) {
            _selectedFeeIds.remove(fee.id);
          } else {
            _selectedFeeIds.add(fee.id);
          }
        });
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fee.feeTypeName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? AppSizes.fontMedium : AppSizes.fontNormal,
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      height: 1.47,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.textXs,
                      fontWeight: AppSizes.fontNormal,
                      color: isSelected ? AppColors.accent : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
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

  Widget _buildPayNowButton(double totalAmount) {
    final isEnabled = totalAmount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.accent : AppColors.bgTertiary,
        borderRadius: BorderRadius.circular(AppSizes.roundedLg),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? () => _handlePayNow() : null,
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.s2,
              vertical: AppSizes.s3,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Pay Now',
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

  void _handlePayNow() {
    // TODO: Implement payment flow
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.s6),
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
