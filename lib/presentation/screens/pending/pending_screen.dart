import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';

class PendingScreen extends ConsumerStatefulWidget {
  final String? feeType;

  const PendingScreen({super.key, this.feeType});

  @override
  ConsumerState<PendingScreen> createState() => _PendingScreenState();
}

class _PendingScreenState extends ConsumerState<PendingScreen> {
  String _selectedFeeGroup = 'ALL';
  bool _isDropdownOpen = false;
  bool _hasPreselectedFees = false;

  @override
  void initState() {
    super.initState();
    // Set default selection based on feeType
    if (widget.feeType == 'term') {
      _selectedFeeGroup = 'ALL';
    } else if (widget.feeType == 'bus') {
      _selectedFeeGroup = 'ALL';
    }

    // Pre-select all fees after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preselectAllFees();
    });
  }

  void _preselectAllFees() {
    if (_hasPreselectedFees) return;
    _hasPreselectedFees = true;

    final allPendingFees = ref.read(pendingFeesProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.read(cartProvider);

    // Filter fees based on feeType (term or bus)
    final feesToSelect = widget.feeType == 'bus'
        ? allPendingFees.where((f) => _isBusFee(f.demfeetype)).toList()
        : widget.feeType == 'term'
            ? allPendingFees.where((f) => !_isBusFee(f.demfeetype)).toList()
            : allPendingFees;

    // Add all filtered fees to cart
    for (final fee in feesToSelect) {
      if (!cartState.containsFee(fee.id)) {
        cartNotifier.addFee(fee);
      }
    }
  }

  /// Check if a fee is a bus/transport/van fee
  bool _isBusFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('bus') || lowerType.contains('transport') || lowerType.contains('van');
  }

  /// Get fee group options based on fee type
  List<String> _getFeeGroupOptions(List<FeeModel> fees) {
    if (widget.feeType == 'term') {
      // For term fees page, show term-based options
      final options = <String>['ALL'];
      final terms = fees.map((f) => f.demfeeterm).toSet().toList();
      terms.sort();
      options.addAll(terms);
      return options;
    } else if (widget.feeType == 'bus') {
      // For bus fees page, show month-based options
      final options = <String>['ALL'];
      final months = fees.map((f) => _extractMonthFromDate(f)).toSet().toList();
      // Sort months chronologically
      months.sort((a, b) {
        final monthOrder = ['APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER',
                           'OCTOBER', 'NOVEMBER', 'DECEMBER', 'JANUARY', 'FEBRUARY', 'MARCH'];
        final aMonth = a.split(' ').first.toUpperCase();
        final bMonth = b.split(' ').first.toUpperCase();
        return monthOrder.indexOf(aMonth).compareTo(monthOrder.indexOf(bMonth));
      });
      options.addAll(months);
      return options;
    }
    return ['ALL'];
  }

  /// Filter fees based on selected group
  List<FeeModel> _getFilteredFees(List<FeeModel> fees) {
    if (_selectedFeeGroup == 'ALL') {
      return fees;
    }

    if (widget.feeType == 'term') {
      return fees.where((f) => f.demfeeterm == _selectedFeeGroup).toList();
    } else if (widget.feeType == 'bus') {
      return fees.where((f) => _extractMonthFromDate(f) == _selectedFeeGroup).toList();
    }
    return fees;
  }

  void _selectFeesForGroup(String group, List<FeeModel> allFees) {
    final cartNotifier = ref.read(cartProvider.notifier);

    // First, clear all fees of this type from cart when selecting a specific group
    if (group != 'ALL') {
      for (final fee in allFees) {
        cartNotifier.removeFee(fee.id);
      }
    }

    List<FeeModel> feesToSelect;
    if (group == 'ALL') {
      feesToSelect = allFees;
    } else if (widget.feeType == 'term') {
      feesToSelect = allFees.where((f) => f.demfeeterm == group).toList();
    } else {
      feesToSelect = allFees.where((f) => _extractMonthFromDate(f) == group).toList();
    }

    for (final fee in feesToSelect) {
      if (!ref.read(cartProvider).containsFee(fee.id)) {
        cartNotifier.addFee(fee);
      }
    }
  }

  void _clearAllFees(List<FeeModel> fees) {
    final cartNotifier = ref.read(cartProvider.notifier);
    for (final fee in fees) {
      cartNotifier.removeFee(fee.id);
    }
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  /// Get month range for a term
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

  /// Sort bus fees by month
  List<FeeModel> _getSortedBusFees(List<FeeModel> fees) {
    final sortedFees = List<FeeModel>.from(fees);
    final monthOrder = ['APRIL', 'MAY', 'JUNE', 'JULY', 'AUGUST', 'SEPTEMBER',
                       'OCTOBER', 'NOVEMBER', 'DECEMBER', 'JANUARY', 'FEBRUARY', 'MARCH'];

    sortedFees.sort((a, b) {
      final aMonth = _extractMonthFromDate(a).split(' ').first.toUpperCase();
      final bMonth = _extractMonthFromDate(b).split(' ').first.toUpperCase();
      return monthOrder.indexOf(aMonth).compareTo(monthOrder.indexOf(bMonth));
    });

    return sortedFees;
  }

  @override
  Widget build(BuildContext context) {
    final allPendingFees = ref.watch(pendingFeesProvider);
    final cartState = ref.watch(cartProvider);

    // Filter fees based on feeType parameter (term or bus)
    final baseFees = widget.feeType == 'bus'
        ? allPendingFees.where((f) => _isBusFee(f.demfeetype)).toList()
        : widget.feeType == 'term'
            ? allPendingFees.where((f) => !_isBusFee(f.demfeetype)).toList()
            : allPendingFees;

    // Further filter based on dropdown selection
    final filteredFees = _getFilteredFees(baseFees);

    // Get fee group options
    final feeGroupOptions = _getFeeGroupOptions(baseFees);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          Column(
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
                child: baseFees.isEmpty
                    ? _buildEmptyState()
                    : _buildContent(
                        context,
                        feeGroupOptions,
                        baseFees,
                        filteredFees,
                        cartState,
                      ),
              ),
            ],
          ),
          // Floating dropdown overlay
          if (_isDropdownOpen)
            Positioned(
              top: MediaQuery.of(context).padding.top + 150,
              left: 0,
              right: 0,
              child: _buildFloatingDropdown(feeGroupOptions, baseFees, filteredFees, cartState),
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
          Text(
            widget.feeType == 'bus'
                ? 'Bus Fees'
                : widget.feeType == 'term'
                    ? 'Term Fees'
                    : 'Pending',
            style: const TextStyle(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<String> feeGroupOptions,
    List<FeeModel> baseFees,
    List<FeeModel> filteredFees,
    CartState cartState,
  ) {
    // Calculate amounts
    final totalAmount = filteredFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final selectedFees = filteredFees.where((f) => cartState.containsFee(f.id)).toList();
    final selectedAmount = selectedFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (_isDropdownOpen) {
                setState(() {
                  _isDropdownOpen = false;
                });
              }
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Fee Group Filter Card
                _buildFeeGroupFilter(feeGroupOptions, filteredFees, totalAmount),
                const SizedBox(height: 16),

                // Fee cards based on type
                if (widget.feeType == 'term')
                  ..._buildTermFeeCards(filteredFees, cartState)
                else if (widget.feeType == 'bus')
                  _buildBusFeeCard(filteredFees, cartState),
              ],
            ),
          ),
        ),

        // Bottom Bar
        if (selectedAmount > 0)
          _buildBottomBar(context, selectedFees.length, selectedAmount),
      ],
    );
  }

  Widget _buildFeeGroupFilter(List<String> options, List<FeeModel> filteredFees, double totalAmount) {
    final displayText = _selectedFeeGroup == 'ALL'
        ? (widget.feeType == 'term' ? 'ALL TERMS' : 'ALL MONTHS')
        : _selectedFeeGroup;

    return Container(
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
          Text(
            widget.feeType == 'term' ? 'Select Term' : 'Select Month',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isDropdownOpen = !_isDropdownOpen;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            displayText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2933),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          _isDropdownOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: const Color(0xFF6B7280),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Clear Button
              GestureDetector(
                onTap: () => _clearAllFees(filteredFees),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B7280),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.clear_all_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingDropdown(List<String> options, List<FeeModel> allFees, List<FeeModel> filteredFees, CartState cartState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fee Group Options
          ...options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = _selectedFeeGroup == option;
            final isFirst = index == 0;
            final isLast = index == options.length - 1;
            final displayText = option == 'ALL'
                ? (widget.feeType == 'term' ? 'ALL TERMS' : 'ALL MONTHS')
                : option;
            return GestureDetector(
              onTap: () {
                // Auto-select fees for this group
                _selectFeesForGroup(option, allFees);
                setState(() {
                  _selectedFeeGroup = option;
                  _isDropdownOpen = false;
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
                        ),
                  borderRadius: isFirst && isLast
                      ? BorderRadius.circular(11)
                      : isFirst
                          ? const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              topRight: Radius.circular(11),
                            )
                          : isLast
                              ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(11),
                                  bottomRight: Radius.circular(11),
                                )
                              : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : const Color(0xFF1F2933),
                        ),
                      ),
                    ),
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<Widget> _buildTermFeeCards(List<FeeModel> fees, CartState cartState) {
    // Group fees by term
    final Map<String, List<FeeModel>> feesByTerm = {};
    for (final fee in fees) {
      final term = fee.demfeeterm;
      feesByTerm.putIfAbsent(term, () => []);
      feesByTerm[term]!.add(fee);
    }

    final sortedTerms = feesByTerm.keys.toList()..sort((a, b) => a.compareTo(b));

    return sortedTerms.map((term) {
      final termFees = feesByTerm[term]!;
      final academicYear = termFees.isNotEmpty ? termFees.first.demfeeyear : '2025-2026';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTermCard(term, academicYear, termFees, cartState),
      );
    }).toList();
  }

  Widget _buildTermCard(String term, String academicYear, List<FeeModel> fees, CartState cartState) {
    final monthRange = _getTermMonthRange(term, academicYear);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

    return GestureDetector(
      onTap: () {
        if (allSelected) {
          for (final fee in fees) {
            ref.read(cartProvider.notifier).removeFee(fee.id);
          }
        } else {
          for (final fee in fees) {
            if (!cartState.containsFee(fee.id)) {
              ref.read(cartProvider.notifier).addFee(fee);
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: allSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: allSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        const SizedBox(height: 4),
                        Text(
                          monthRange,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$term ($academicYear)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox
                  Container(
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
                ],
              ),
              const SizedBox(height: 16),

              // Table Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Particular',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ),
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE5E7EB)),

              // Fee Items (no individual checkboxes for term fees)
              ...fees.map((fee) => Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        fee.demfeetype.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              )),

              // Total Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusFeeCard(List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final allSelected = fees.every((f) => cartState.containsFee(f.id));
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final sortedFees = _getSortedBusFees(fees);

    return GestureDetector(
      onTap: () {
        if (allSelected) {
          for (final fee in fees) {
            ref.read(cartProvider.notifier).removeFee(fee.id);
          }
        } else {
          for (final fee in fees) {
            if (!cartState.containsFee(fee.id)) {
              ref.read(cartProvider.notifier).addFee(fee);
            }
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: allSelected ? AppColors.primary : const Color(0xFFE5E7EB),
            width: allSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bus Fee Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2933),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Monthly breakdown',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          academicYear,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Checkbox
                  Container(
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
                ],
              ),
              const SizedBox(height: 16),

              // Table Header
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Month',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ),
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE5E7EB)),

              // Fee Items with individual checkboxes
              ...sortedFees.map((fee) {
                final monthName = _extractMonthFromDate(fee);
                final isSelected = cartState.containsFee(fee.id);
                return GestureDetector(
                  onTap: () {
                    if (isSelected) {
                      ref.read(cartProvider.notifier).removeFee(fee.id);
                    } else {
                      ref.read(cartProvider.notifier).addFee(fee);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
                    ),
                    child: Row(
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
                          child: Text(
                            monthName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1F2933),
                            ),
                          ),
                        ),
                        Text(
                          '₹ ${NumberFormat('#,##,###').format(fee.balancedue.toInt())}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2933),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Individual month checkbox
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Total Row
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F2933),
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2933),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
                    '$selectedCount ${widget.feeType == 'bus' ? 'month' : 'fee'}${selectedCount > 1 ? 's' : ''} selected',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹ ${NumberFormat('#,##,###').format(selectedAmount.toInt())}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => context.push(Routes.cart),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.feeType == 'bus' ? Icons.directions_bus_outlined : Icons.receipt_long_outlined,
            size: 64,
            color: const Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          Text(
            widget.feeType == 'bus' ? 'No bus fees pending' : 'No term fees pending',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'All fees have been paid',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
