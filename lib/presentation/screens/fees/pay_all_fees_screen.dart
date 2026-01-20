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

class PayAllFeesScreen extends ConsumerStatefulWidget {
  const PayAllFeesScreen({super.key});

  @override
  ConsumerState<PayAllFeesScreen> createState() => _PayAllFeesScreenState();
}

class _PayAllFeesScreenState extends ConsumerState<PayAllFeesScreen> {
  String _selectedFeeGroup = 'ALL FEES';
  bool _isDropdownOpen = false;
  bool _hasPreselectedFees = false;

  @override
  void initState() {
    super.initState();
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

    for (final fee in allPendingFees) {
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

  /// Get fee group options based on available fees
  List<String> _getFeeGroupOptions(List<FeeModel> fees) {
    final options = <String>['ALL FEES'];

    // Check if there are term fees (non-bus fees)
    final hasTermFees = fees.any((f) => !_isBusFee(f.demfeetype) && !_isExtraFee(f.demfeetype));
    if (hasTermFees) {
      options.add('Term Fees');
    }

    // Check for bus fees
    final hasBusFees = fees.any((f) => _isBusFee(f.demfeetype));
    if (hasBusFees) {
      options.add('Bus Fees');
    }

    // Check for extra fees (can add more types here in future)
    final hasExtraFees = fees.any((f) => _isExtraFee(f.demfeetype));
    if (hasExtraFees) {
      options.add('Extra Fees');
    }

    return options;
  }

  /// Check if a fee is an extra/miscellaneous fee
  bool _isExtraFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('extra') ||
           lowerType.contains('misc') ||
           lowerType.contains('other') ||
           lowerType.contains('activity') ||
           lowerType.contains('event');
  }

  /// Filter fees based on selected group
  List<FeeModel> _getFilteredFees(List<FeeModel> allFees) {
    if (_selectedFeeGroup == 'ALL FEES') {
      return allFees;
    } else if (_selectedFeeGroup == 'Term Fees') {
      return allFees.where((f) => !_isBusFee(f.demfeetype) && !_isExtraFee(f.demfeetype)).toList();
    } else if (_selectedFeeGroup == 'Bus Fees') {
      return allFees.where((f) => _isBusFee(f.demfeetype)).toList();
    } else if (_selectedFeeGroup == 'Extra Fees') {
      return allFees.where((f) => _isExtraFee(f.demfeetype)).toList();
    }
    return allFees;
  }

  void _selectFeesForGroup(String group, List<FeeModel> allFees) {
    final cartNotifier = ref.read(cartProvider.notifier);

    // First, clear all fees from cart when selecting a specific group
    if (group != 'All Fees') {
      for (final fee in allFees) {
        cartNotifier.removeFee(fee.id);
      }
    }

    List<FeeModel> feesToSelect;
    if (group == 'All Fees') {
      feesToSelect = allFees;
    } else if (group == 'Term Fees') {
      feesToSelect = allFees.where((f) => !_isBusFee(f.demfeetype) && !_isExtraFee(f.demfeetype)).toList();
    } else if (group == 'Bus Fees') {
      feesToSelect = allFees.where((f) => _isBusFee(f.demfeetype)).toList();
    } else if (group == 'Extra Fees') {
      feesToSelect = allFees.where((f) => _isExtraFee(f.demfeetype)).toList();
    } else {
      feesToSelect = allFees;
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

  @override
  Widget build(BuildContext context) {
    final allPendingFees = ref.watch(pendingFeesProvider);
    final cartState = ref.watch(cartProvider);

    // Get filtered fees based on selection
    final filteredFees = _getFilteredFees(allPendingFees);

    // Get fee group options
    final feeGroupOptions = _getFeeGroupOptions(allPendingFees);

    // Separate filtered fees by category for display
    final termFees = filteredFees.where((f) => !_isBusFee(f.demfeetype)).toList();
    final busFees = filteredFees.where((f) => _isBusFee(f.demfeetype)).toList();

    // Group term fees by term
    final Map<String, List<FeeModel>> feesByTerm = {};
    for (final fee in termFees) {
      final term = fee.demfeeterm;
      feesByTerm.putIfAbsent(term, () => []);
      feesByTerm[term]!.add(fee);
    }

    // Calculate selected amount from filtered fees
    final selectedFees = filteredFees.where((f) => cartState.containsFee(f.id)).toList();
    final selectedAmount = selectedFees.fold<double>(0, (sum, fee) => sum + fee.balancedue);

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
            child: allPendingFees.isEmpty
                ? _buildEmptyState()
                : _buildContent(
                    context,
                    feeGroupOptions,
                    allPendingFees,
                    filteredFees,
                    feesByTerm,
                    busFees,
                    cartState,
                  ),
          ),
          // Bottom Bar
          if (selectedAmount > 0)
            _buildBottomBar(context, selectedFees.length, selectedAmount),
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
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(Routes.home);
              }
            },
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
            'Pay All Fees',
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
    List<FeeModel> allFees,
    List<FeeModel> filteredFees,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    CartState cartState,
  ) {
    // Sort terms
    final sortedTerms = feesByTerm.keys.toList()..sort((a, b) => a.compareTo(b));

    return Stack(
      children: [
        // Main content - scrollable list
        GestureDetector(
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
              _buildFeeGroupFilter(feeGroupOptions, filteredFees),
              const SizedBox(height: 16),

              // Term fee cards
              for (int i = 0; i < sortedTerms.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTermCard(
                    sortedTerms[i],
                    feesByTerm[sortedTerms[i]]!,
                    cartState,
                  ),
                ),

              // Bus fees card (grouped by term if showing all)
              if (busFees.isNotEmpty)
                _buildBusFeesCard(busFees, cartState),
            ],
          ),
        ),

        // Floating dropdown overlay
        if (_isDropdownOpen)
          Positioned(
            top: 90, // Position below the filter card
            left: 0,
            right: 0,
            child: _buildFloatingDropdown(feeGroupOptions, allFees, filteredFees, cartState),
          ),
      ],
    );
  }

  Widget _buildFeeGroupFilter(List<String> options, List<FeeModel> filteredFees) {
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
          // Fee Group Label
          const Text(
            'Fee Group',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),

          // Dropdown and Total Amount Row
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
                        Text(
                          _selectedFeeGroup,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2933),
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
                        option,
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

  Widget _buildTermCard(String term, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getTermMonthRange(term, academicYear);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    return GestureDetector(
      onTap: () {
        final cartNotifier = ref.read(cartProvider.notifier);
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
      },
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Fee Breakdown + Term Badge + Checkbox
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
                  const SizedBox(width: 8),
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
                padding: EdgeInsets.symmetric(vertical: AppSizes.s2),
                child: Row(
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
              ),

              // Divider
              Container(height: 1, color: const Color(0xFFE5E7EB)),

              // Fee Items
              ...fees.map((fee) => _buildFeeRow(fee)),

              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: AppSizes.textBase,
                          fontWeight: AppSizes.fontBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                      style: const TextStyle(
                        fontSize: AppSizes.textLg,
                        fontWeight: AppSizes.fontBold,
                        color: AppColors.textPrimary,
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

  Widget _buildFeeRow(FeeModel fee) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fee.demfeetype.toUpperCase(),
              style: const TextStyle(
                fontSize: AppSizes.bodyText,
                fontWeight: AppSizes.fontNormal,
                color: AppColors.textSecondary,
                height: 1.47,
              ),
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

  Widget _buildBusFeesCard(List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));
    final sortedFees = _getSortedBusFees(fees);

    return GestureDetector(
      onTap: () {
        final cartNotifier = ref.read(cartProvider.notifier);
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
      },
      child: Container(
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
                  const SizedBox(width: 8),
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
                padding: EdgeInsets.symmetric(vertical: AppSizes.s2),
                child: Row(
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
              ),

              // Divider
              Container(height: 1, color: const Color(0xFFE5E7EB)),

              // Bus Fee Items
              ...sortedFees.map((fee) => _buildBusFeeRow(fee, cartState)),

              // Total Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'TOTAL',
                        style: TextStyle(
                          fontSize: AppSizes.textBase,
                          fontWeight: AppSizes.fontBold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(totalAmount.toInt())}',
                      style: const TextStyle(
                        fontSize: AppSizes.textLg,
                        fontWeight: AppSizes.fontBold,
                        color: AppColors.textPrimary,
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

  Widget _buildBusFeeRow(FeeModel fee, CartState cartState) {
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
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          children: [
            // Month Name with bus icon
            Expanded(
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
                        fontSize: AppSizes.bodyText,
                        fontWeight: AppSizes.fontMedium,
                        color: AppColors.textPrimary,
                        height: 1.47,
                      ),
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
              onPressed: selectedAmount > 0 ? () => context.go(Routes.cart) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Proceed to Pay',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
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
}
