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
import '../../providers/cart_provider.dart';

class AllPendingFeesScreen extends ConsumerStatefulWidget {
  final String? filterGroup;

  const AllPendingFeesScreen({super.key, this.filterGroup});

  @override
  ConsumerState<AllPendingFeesScreen> createState() => _AllPendingFeesScreenState();
}

class _AllPendingFeesScreenState extends ConsumerState<AllPendingFeesScreen> {
  // Track which accordions are expanded
  late Map<String, bool> _expandedSections;

  @override
  void initState() {
    super.initState();
    // Initialize expanded sections based on filter
    final filter = widget.filterGroup?.toLowerCase();
    if (filter != null && (filter.contains('van') || filter.contains('bus') || filter.contains('transport'))) {
      _expandedSections = {
        'term1': false,
        'term2': false,
        'term3': false,
        'bus': true,
      };
    } else if (filter != null && filter.contains('school')) {
      _expandedSections = {
        'term1': true,
        'term2': true,
        'term3': true,
        'bus': false,
      };
    } else {
      _expandedSections = {
        'term1': true,
        'term2': false,
        'term3': false,
        'bus': false,
      };
    }
  }

  /// Check if a fee is a bus/transport/van fee
  bool _isBusFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('bus') || lowerType.contains('transport') || lowerType.contains('van');
  }

  @override
  Widget build(BuildContext context) {
    final allPendingFees = ref.watch(pendingFeesProvider);
    final cartState = ref.watch(cartProvider);

    // Apply filter based on filterGroup parameter
    final filter = widget.filterGroup?.toLowerCase();
    final bool showOnlyBusFees = filter != null &&
        (filter.contains('van') || filter.contains('bus') || filter.contains('transport'));
    final bool showOnlySchoolFees = filter != null && filter.contains('school');

    // Filter fees based on the selected group
    List<FeeModel> filteredFees;
    if (showOnlyBusFees) {
      filteredFees = allPendingFees.where((f) => _isBusFee(f.demfeetype)).toList();
    } else if (showOnlySchoolFees) {
      filteredFees = allPendingFees.where((f) => !_isBusFee(f.demfeetype)).toList();
    } else {
      filteredFees = allPendingFees;
    }

    // Separate fees by category (from filtered fees)
    final termFees = filteredFees.where((f) => !_isBusFee(f.demfeetype)).toList();
    final busFees = filteredFees.where((f) => _isBusFee(f.demfeetype)).toList();

    // Group term fees by term
    final Map<String, List<FeeModel>> feesByTerm = {};
    for (final fee in termFees) {
      final term = fee.demfeeterm;
      feesByTerm.putIfAbsent(term, () => []);
      feesByTerm[term]!.add(fee);
    }

    // Calculate selected amount (from filtered fees only)
    final selectedFees = filteredFees.where((f) => cartState.containsFee(f.id)).toList();
    final selectedAmount = selectedFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: Stack(
        children: [
          Column(
            children: [
              // Header with white SafeArea and subtle shadow
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
                        _buildHeader(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: filteredFees.isEmpty
                    ? _buildEmptyState()
                    : _buildAccordionList(context, feesByTerm, busFees, cartState),
              ),
              // Bottom Bar
              if (selectedAmount > 0)
                _buildBottomBar(context, selectedFees.length, selectedAmount),
            ],
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
          // Back Button - Dark theme
          GestureDetector(
            onTap: () => context.go(Routes.home),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Title
          Text(
            widget.filterGroup != null ? '${_toTitleCase(widget.filterGroup!)} Details' : 'All Pending Fees',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2933),
            ),
          ),

          // Notification Button - Dark theme
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/images/notification.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
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

  Widget _buildAccordionList(
    BuildContext context,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    CartState cartState,
  ) {
    // Sort terms
    final sortedTerms = feesByTerm.keys.toList()..sort((a, b) => a.compareTo(b));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Term fee accordions
        for (int i = 0; i < sortedTerms.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTermAccordion(
              context,
              sortedTerms[i],
              feesByTerm[sortedTerms[i]]!,
              cartState,
              'term${i + 1}',
            ),
          ),

        // Bus fees accordion
        if (busFees.isNotEmpty)
          _buildBusFeesAccordion(context, busFees, cartState),
      ],
    );
  }

  Widget _buildTermAccordion(
    BuildContext context,
    String term,
    List<FeeModel> fees,
    CartState cartState,
    String sectionKey,
  ) {
    final isExpanded = _expandedSections[sectionKey] ?? false;
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getTermMonthRange(term, academicYear);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    return Container(
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
          // Accordion Header (always visible)
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedSections[sectionKey] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Expand/Collapse Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fee Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2933),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          monthRange,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Term Badge
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
                      '$term ($academicYear)',
                      style: const TextStyle(
                        fontSize: AppSizes.textXs,
                        fontWeight: AppSizes.fontSemibold,
                        color: AppColors.textInverse,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox for entire term
                  GestureDetector(
                    onTap: () => _toggleAllFees(fees, allSelected),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: allSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: allSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                      ),
                      child: allSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildTermContent(fees, totalAmount),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildTermContent(List<FeeModel> fees, double totalAmount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Table Header
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Particular',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Fee Items (no individual checkboxes)
          ...fees.map((fee) => _buildFeeRow(fee)),

          // Total
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: const TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(FeeModel fee) {
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fee.demfeetype.toUpperCase(),
                  style: const TextStyle(
                    fontSize: AppSizes.bodyText,
                    fontWeight: AppSizes.fontNormal,
                    color: AppColors.textSecondary,
                    height: 1.47,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: isOverdue ? AppColors.error : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isOverdue ? AppColors.error : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
            style: const TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusFeesAccordion(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final isExpanded = _expandedSections['bus'] ?? false;
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));
    final sortedFees = _getSortedBusFees(fees);

    return Container(
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
          // Accordion Header
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedSections['bus'] = !isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Expand/Collapse Icon
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bus Fee Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2933),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${fees.length} month${fees.length > 1 ? 's' : ''} pending',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bus Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.s3,
                      vertical: AppSizes.s1 + 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_bus,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          academicYear,
                          style: const TextStyle(
                            fontSize: AppSizes.textXs,
                            fontWeight: AppSizes.fontSemibold,
                            color: AppColors.textInverse,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox for entire bus fees section
                  GestureDetector(
                    onTap: () => _toggleAllFees(fees, allSelected),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: allSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: allSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                          width: 1.5,
                        ),
                      ),
                      child: allSelected
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildBusContent(sortedFees, totalAmount),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildBusContent(List<FeeModel> fees, double totalAmount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Divider
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Table Header
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Month',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontSemibold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Amount',
                style: TextStyle(
                  fontSize: AppSizes.textBase,
                  fontWeight: AppSizes.fontSemibold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),

          // Bus Fee Items (no individual checkboxes)
          ...fees.map((fee) => _buildBusFeeRow(fee)),

          // Total
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: AppSizes.textBase,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                  style: const TextStyle(
                    fontSize: AppSizes.textLg,
                    fontWeight: AppSizes.fontBold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusFeeRow(FeeModel fee) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Name with bus icon
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.directions_bus_outlined,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: AppSizes.bodyText,
                          fontWeight: AppSizes.fontMedium,
                          color: AppColors.textPrimary,
                          height: 1.47,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: isOverdue ? AppColors.error : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isOverdue ? AppColors.error : const Color(0xFF9CA3AF),
                            ),
                          ),
                          if (isOverdue) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Overdue',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
            style: const TextStyle(
              fontSize: AppSizes.textBase,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int selectedCount, double selectedAmount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$selectedCount fee${selectedCount > 1 ? 's' : ''} selected',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(selectedAmount.toInt())}',
                    style: const TextStyle(
                      fontSize: AppSizes.text2xl,
                      fontWeight: AppSizes.fontBold,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go(Routes.cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/Cart.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text('View Cart'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Pending Fees',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All your fees are paid. Great job!',
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

  // Helper methods
  void _toggleAllFees(List<FeeModel> fees, bool allSelected) {
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.read(cartProvider);

    if (allSelected) {
      for (final fee in fees) {
        cartNotifier.removeFee(fee.id);
      }
    } else {
      for (final fee in fees) {
        if (!cartState.containsFee(fee.id)) {
          cartNotifier.addFee(fee);
        }
      }
    }
  }

  String _getTermMonthRange(String term, String academicYear) {
    final lowerTerm = term.toLowerCase();
    final years = academicYear.split('-');
    final startYear = years.isNotEmpty ? years[0].trim() : '2025';
    final endYear = years.length > 1 ? years[1].trim() : '2026';

    if (lowerTerm.contains('iii term') || lowerTerm.contains('term 3') || lowerTerm.contains('3rd') || lowerTerm == 'term3') {
      return 'December $startYear - March $endYear';
    } else if (lowerTerm.contains('ii term') || lowerTerm.contains('term 2') || lowerTerm.contains('2nd') || lowerTerm == 'term2') {
      return 'August - November $startYear';
    } else if (lowerTerm.contains('i term') || lowerTerm.contains('term 1') || lowerTerm.contains('1st') || lowerTerm == 'term1') {
      return 'April - July $startYear';
    }
    return 'Academic Year $academicYear';
  }

  List<FeeModel> _getSortedBusFees(List<FeeModel> fees) {
    return List<FeeModel>.from(fees)..sort((a, b) {
      if (a.duedate != null && b.duedate != null) {
        return a.duedate!.compareTo(b.duedate!);
      }
      return a.createdat.compareTo(b.createdat);
    });
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
