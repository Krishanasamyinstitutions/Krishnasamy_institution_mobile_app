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
  final String? filterStatus; // 'overdue', 'dueSoon', or null for all

  const AllPendingFeesScreen({super.key, this.filterGroup, this.filterStatus});

  @override
  ConsumerState<AllPendingFeesScreen> createState() => _AllPendingFeesScreenState();
}

class _AllPendingFeesScreenState extends ConsumerState<AllPendingFeesScreen> {
  String? _selectedSubFilter; // Sub-filter within the current fee group (e.g., "I TERM", "January")
  bool _hasPreselectedFees = false;
  bool _isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    // Initialize with no sub-filter (show all within group)
    _selectedSubFilter = null;

    // Pre-select fees after the first frame when navigating from home screen cards
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preselectFeesForGroup();
    });
  }

  void _preselectFeesForGroup() {
    if (_hasPreselectedFees) return;
    _hasPreselectedFees = true;

    final allPendingFees = ref.read(pendingFeesProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final cartState = ref.read(cartProvider);

    // Determine which fees to pre-select based on filter
    List<FeeModel> feesToSelect;
    final activeFilterGroup = widget.filterGroup;
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));

    if (activeFilterGroup != null && activeFilterGroup.isNotEmpty) {
      // Use the provider to get fees by group
      feesToSelect = ref.read(pendingFeesByGroupNameProvider(activeFilterGroup));
    } else {
      feesToSelect = allPendingFees;
    }

    // Apply status filter if present
    if (widget.filterStatus == 'overdue') {
      feesToSelect = feesToSelect.where((f) => f.dueDate.isBefore(now)).toList();
    } else if (widget.filterStatus == 'dueSoon') {
      feesToSelect = feesToSelect.where((f) =>
        !f.dueDate.isBefore(now) && f.dueDate.isBefore(thirtyDaysFromNow)
      ).toList();
    }

    // Add all fees to cart
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

  /// Check if a fee is a tuition fee
  bool _isTuitionFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('tuition');
  }

  /// Check if a fee is a hostel fee
  bool _isHostelFee(String feeType) {
    final lowerType = feeType.toLowerCase();
    return lowerType.contains('hostel');
  }

  @override
  Widget build(BuildContext context) {
    final allPendingFees = ref.watch(pendingFeesProvider);
    final cartState = ref.watch(cartProvider);

    // Apply filter based on filterGroup parameter (the main group from navigation)
    List<FeeModel> filteredFees;
    final activeFilterGroup = widget.filterGroup;

    if (activeFilterGroup != null && activeFilterGroup.isNotEmpty) {
      // Use the pendingFeesByGroupNameProvider which handles mapping correctly
      filteredFees = ref.watch(pendingFeesByGroupNameProvider(activeFilterGroup));
    } else {
      filteredFees = allPendingFees;
    }

    // Apply status filter (overdue/dueSoon)
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    if (widget.filterStatus == 'overdue') {
      filteredFees = filteredFees.where((f) => f.dueDate.isBefore(now)).toList();
    } else if (widget.filterStatus == 'dueSoon') {
      // Due soon = not overdue AND due within next 30 days (matches fee_provider.dart)
      filteredFees = filteredFees.where((f) =>
        !f.dueDate.isBefore(now) && f.dueDate.isBefore(thirtyDaysFromNow)
      ).toList();
    }

    // Separate fees by category (from filtered fees)
    final termFees = filteredFees.where((f) => !_isBusFee(f.demfeetype) && !_isTuitionFee(f.demfeetype) && !_isHostelFee(f.demfeetype)).toList();
    final busFees = filteredFees.where((f) => _isBusFee(f.demfeetype)).toList();
    final tuitionFees = filteredFees.where((f) => _isTuitionFee(f.demfeetype)).toList();
    final hostelFees = filteredFees.where((f) => _isHostelFee(f.demfeetype)).toList();

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
              // Content with Fee Group Filter inside
              Expanded(
                child: filteredFees.isEmpty
                    ? _buildEmptyState()
                    : _buildContentWithFilter(context, filteredFees, feesByTerm, busFees, tuitionFees, hostelFees, cartState),
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
            _getScreenTitle(),
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

  /// Get sub-filter options based on the current fee group type
  List<String> _getSubFilterOptions(
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
  ) {
    final groupName = widget.filterGroup?.toUpperCase() ?? '';

    // School Fees - show terms (I TERM, II TERM, etc.) and TUITION FEES option
    if (groupName.contains('SCHOOL')) {
      final allTerms = <String>{};
      // Add terms from regular fees
      allTerms.addAll(feesByTerm.keys.where((t) => t.toUpperCase().contains('TERM')));
      // Add terms from tuition fees
      for (final fee in tuitionFees) {
        if (fee.demfeeterm.toUpperCase().contains('TERM')) {
          allTerms.add(fee.demfeeterm);
        }
      }
      // Note: Hostel fees are NOT included in School Fees group
      final terms = allTerms.toList()..sort(); // Sort alphabetically (I TERM before II TERM)
      // Add TUITION FEES as a separate filter option if tuition fees exist
      if (tuitionFees.isNotEmpty) {
        terms.add('TUITION FEES');
      }
      return terms;
    }

    // Van/Bus Fees - show months
    if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TRANSPORT')) {
      return _getUniqueMonths(busFees);
    }

    // Tuition Fees - show months
    if (groupName.contains('TUITION')) {
      return _getUniqueMonths(tuitionFees);
    }

    // Hostel Fees - show months
    if (groupName.contains('HOSTEL')) {
      return _getUniqueMonths(hostelFees);
    }

    // Default - show terms if available
    if (feesByTerm.isNotEmpty) {
      return feesByTerm.keys.toList()..sort();
    }

    return [];
  }

  /// Extract unique months from fees for monthly filters
  List<String> _getUniqueMonths(List<FeeModel> fees) {
    final months = <String>{};
    for (final fee in fees) {
      final date = fee.duedate ?? fee.createdat;
      final monthName = DateFormat('MMMM yyyy').format(date);
      months.add(monthName);
    }
    // Sort by date
    final monthList = months.toList();
    monthList.sort((a, b) {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateA.compareTo(dateB);
    });
    return monthList;
  }

  Widget _buildContentWithFilter(
    BuildContext context,
    List<FeeModel> filteredFees,
    Map<String, List<FeeModel>> feesByTerm,
    List<FeeModel> busFees,
    List<FeeModel> tuitionFees,
    List<FeeModel> hostelFees,
    CartState cartState,
  ) {
    // Get sub-filter options based on the current fee group
    final subFilterOptions = _getSubFilterOptions(feesByTerm, busFees, tuitionFees, hostelFees);

    // Apply sub-filter to the displayed data
    Map<String, List<FeeModel>> displayedFeesByTerm = feesByTerm;
    List<FeeModel> displayedBusFees = busFees;
    List<FeeModel> displayedTuitionFees = tuitionFees;
    List<FeeModel> displayedHostelFees = hostelFees;

    if (_selectedSubFilter != null) {
      final groupName = widget.filterGroup?.toUpperCase() ?? '';

      if (groupName.contains('SCHOOL')) {
        if (_selectedSubFilter == 'TUITION FEES') {
          // Show only tuition fees, hide term cards
          displayedFeesByTerm = {};
          displayedTuitionFees = tuitionFees;
        } else {
          // Filter by term - apply to term fees and tuition fees only
          // Note: Hostel fees are NOT part of School Fees group
          displayedFeesByTerm = {
            if (feesByTerm.containsKey(_selectedSubFilter))
              _selectedSubFilter!: feesByTerm[_selectedSubFilter]!
          };
          // Also filter tuition fees by term
          displayedTuitionFees = tuitionFees.where((fee) {
            return fee.demfeeterm == _selectedSubFilter;
          }).toList();
        }
      } else if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TRANSPORT')) {
        // Filter by month
        displayedBusFees = busFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      } else if (groupName.contains('TUITION')) {
        // Filter by month
        displayedTuitionFees = tuitionFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      } else if (groupName.contains('HOSTEL')) {
        // Filter by month
        displayedHostelFees = hostelFees.where((fee) {
          final date = fee.duedate ?? fee.createdat;
          final monthName = DateFormat('MMMM yyyy').format(date);
          return monthName == _selectedSubFilter;
        }).toList();
      }
    }

    // Sort terms: Term fees first (I TERM, II TERM, etc.), then monthly fees by date
    final sortedTerms = displayedFeesByTerm.keys.toList()
      ..sort((a, b) {
        final aFees = displayedFeesByTerm[a]!;
        final bFees = displayedFeesByTerm[b]!;

        final aIsTerm = a.toUpperCase().contains('TERM');
        final bIsTerm = b.toUpperCase().contains('TERM');

        if (aIsTerm && !bIsTerm) return -1;
        if (!aIsTerm && bIsTerm) return 1;

        final aDate = aFees.first.duedate ?? aFees.first.createdat;
        final bDate = bFees.first.duedate ?? bFees.first.createdat;
        return aDate.compareTo(bDate);
      });

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
              // Sub-Filter Card (shows terms or months based on group type)
              if (subFilterOptions.isNotEmpty)
                _buildSubFilter(subFilterOptions),
              if (subFilterOptions.isNotEmpty)
                const SizedBox(height: 16),

              // Term Fee Cards
              ...sortedTerms.map((term) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTermAccordion(
                  context,
                  term,
                  displayedFeesByTerm[term]!,
                  cartState,
                  'term_$term',
                ),
              )),

              // Tuition fees card
              if (displayedTuitionFees.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildTuitionFeesCard(context, displayedTuitionFees, cartState),
                ),

              // Hostel fees card - only show in Hostel Fees group, not in School Fees
              if (displayedHostelFees.isNotEmpty &&
                  (widget.filterGroup?.toUpperCase().contains('HOSTEL') ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildHostelFeesCard(context, displayedHostelFees, cartState),
                ),

              // Bus fees card
              if (displayedBusFees.isNotEmpty)
                _buildBusFeesCard(context, displayedBusFees, cartState),
            ],
          ),
        ),

        // Floating dropdown overlay
        if (_isDropdownOpen)
          Positioned(
            top: 90,
            left: 16,
            right: 16,
            child: _buildFloatingDropdown(subFilterOptions),
          ),
      ],
    );
  }

  Widget _buildSubFilter(List<String> subFilterOptions) {
    // Show Clear button as active when user has selected a sub-filter
    final hasFilter = _selectedSubFilter != null;

    // Get appropriate label based on group type
    final groupName = widget.filterGroup?.toUpperCase() ?? '';
    String filterLabel = 'Filter';
    if (groupName.contains('SCHOOL')) {
      filterLabel = 'Term';
    } else if (groupName.contains('VAN') || groupName.contains('BUS') || groupName.contains('TUITION') || groupName.contains('HOSTEL')) {
      filterLabel = 'Month';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            filterLabel,
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
                            _selectedSubFilter ?? 'ALL',
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
                onTap: hasFilter
                    ? () {
                        setState(() {
                          _selectedSubFilter = null;
                          _isDropdownOpen = false;
                        });
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: hasFilter ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 18,
                        color: hasFilter ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: hasFilter ? Colors.white : const Color(0xFF9CA3AF),
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

  Widget _buildFloatingDropdown(List<String> subFilterOptions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // All option
          _buildDropdownOption(null, 'All', true),
          // Sub-filter options (terms or months)
          ...subFilterOptions.map((option) => _buildDropdownOption(
            option,
            option,
            option != subFilterOptions.last,
          )),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(String? option, String label, bool showDivider) {
    final isSelected = _selectedSubFilter == option;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedSubFilter = option;
              _isDropdownOpen = false;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: Colors.transparent,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : const Color(0xFF1F2937),
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
        ),
        if (showDivider)
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
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
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                      Text(
                        term,
                        style: const TextStyle(
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
                // Academic Year Badge - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/school Icons/book.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox for entire term
                GestureDetector(
                  onTap: () => _toggleAllFees(fees, allSelected),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 16),

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

            // Divider
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // Fee Items
            ...sortedFees.map((fee) => _buildFeeRow(fee)),

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
    );
  }

  String _getFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    // Check if this is a term-based fee group (I TERM, II TERM, etc.)
    final term = fees.first.demfeeterm.toUpperCase();
    if (term.contains('I TERM') && !term.contains('II')) {
      return 'May - Oct';
    } else if (term.contains('II TERM')) {
      return 'Nov - Apr';
    }

    // For non-term fees, calculate from actual dates
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildFeeRow(FeeModel fee) {
    final feeName = fee.feeTypeName;
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
        children: [
          // Fee Name with icon
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.receipt_outlined,
                    size: 16,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feeName.toUpperCase(),
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

  Widget _buildTuitionFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getTuitionFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        'TUITION FEES',
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
                // Academic Year Badge with school icon - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox for all tuition fees
                GestureDetector(
                  onTap: () => _toggleAllFees(fees, allSelected),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 16),

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
                SizedBox(width: 36), // Space for checkbox
              ],
            ),

            // Divider
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // Fee Items with individual checkboxes
            ...sortedFees.map((fee) => _buildTuitionFeeRow(fee, cartState)),

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
                  const SizedBox(width: 36), // Space for checkbox alignment
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTuitionFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildTuitionFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = cartState.containsFee(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Month Name with book icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 16,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.toUpperCase(),
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
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHostelFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getHostelFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        'HOSTEL FEES',
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
                // Academic Year Badge with hotel icon - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox for all hostel fees
                GestureDetector(
                  onTap: () => _toggleAllFees(fees, allSelected),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 16),

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
                SizedBox(width: 36), // Space for checkbox
              ],
            ),

            // Divider
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // Fee Items with individual checkboxes
            ...sortedFees.map((fee) => _buildHostelFeeRow(fee, cartState)),

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
                  const SizedBox(width: 36), // Space for checkbox alignment
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHostelFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildHostelFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = cartState.containsFee(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Month Name with hotel icon
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.hotel_outlined,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.toUpperCase(),
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
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusFeesCard(BuildContext context, List<FeeModel> fees, CartState cartState) {
    final academicYear = fees.isNotEmpty ? fees.first.demfeeyear : '2025-2026';
    final monthRange = _getBusFeesMonthRange(fees);
    final totalAmount = fees.fold<double>(0, (sum, fee) => sum + fee.balancedue);
    final allSelected = fees.every((f) => cartState.containsFee(f.id));

    // Calculate fee status for badge color
    final now = DateTime.now();
    final hasOverdue = fees.any((f) => f.dueDate.isBefore(now));
    final hasDueSoon = fees.any((f) {
      final daysUntilDue = f.dueDate.difference(now).inDays;
      return daysUntilDue >= 0 && daysUntilDue <= 7;
    });
    final badgeColor = hasOverdue ? AppColors.error : (hasDueSoon ? AppColors.warning : AppColors.primary);

    // Sort fees by due date
    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        if (a.duedate != null && b.duedate != null) {
          return a.duedate!.compareTo(b.duedate!);
        }
        return a.createdat.compareTo(b.createdat);
      });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        'VAN FEES',
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
                // Academic Year Badge with bus icon - color based on fee status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        'assets/school Icons/van.svg',
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        academicYear,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox for all van fees
                GestureDetector(
                  onTap: () => _toggleAllFees(fees, allSelected),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: allSelected ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(6),
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

            const SizedBox(height: 16),

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
                SizedBox(width: 36), // Space for checkbox
              ],
            ),

            // Divider
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 1,
              color: const Color(0xFFE5E7EB),
            ),

            // Fee Items with individual checkboxes
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
                  const SizedBox(width: 36), // Space for checkbox alignment
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getBusFeesMonthRange(List<FeeModel> fees) {
    if (fees.isEmpty) return '';

    final sortedFees = List<FeeModel>.from(fees)
      ..sort((a, b) {
        final aDate = a.duedate ?? a.createdat;
        final bDate = b.duedate ?? b.createdat;
        return aDate.compareTo(bDate);
      });

    final firstDate = sortedFees.first.duedate ?? sortedFees.first.createdat;
    final lastDate = sortedFees.last.duedate ?? sortedFees.last.createdat;

    final firstMonth = DateFormat('MMM').format(firstDate);
    final lastMonth = DateFormat('MMM').format(lastDate);

    if (firstMonth == lastMonth) {
      return firstMonth;
    }
    return '$firstMonth - $lastMonth';
  }

  Widget _buildBusFeeRow(FeeModel fee, CartState cartState) {
    final monthName = _extractMonthFromDate(fee);
    final dueDate = fee.dueDate;
    final isOverdue = dueDate.isBefore(DateTime.now());
    final isSelected = cartState.containsFee(fee.id);

    return GestureDetector(
      onTap: () => _toggleSingleFee(fee, isSelected),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
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
                    child: SvgPicture.asset(
                      'assets/school Icons/van.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFF59E0B),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthName.toUpperCase(),
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
            const SizedBox(width: 12),
            // Individual checkbox
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFD1D5DB),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, int selectedCount, double selectedAmount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => context.go(Routes.cart),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primary600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    const SizedBox(width: 8),
                    const Text(
                      'View Cart',
                      style: TextStyle(
                        fontSize: 16,
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

  void _toggleSingleFee(FeeModel fee, bool isSelected) {
    final cartNotifier = ref.read(cartProvider.notifier);
    if (isSelected) {
      cartNotifier.removeFee(fee.id);
    } else {
      cartNotifier.addFee(fee);
    }
  }

  String _extractMonthFromDate(FeeModel fee) {
    final date = fee.duedate ?? fee.createdat;
    return DateFormat('MMMM yyyy').format(date);
  }

  String _getScreenTitle() {
    String title = '';

    // Add status prefix
    if (widget.filterStatus == 'overdue') {
      title = 'Overdue';
    } else if (widget.filterStatus == 'dueSoon') {
      title = 'Upcoming';
    }

    // Add group name
    if (widget.filterGroup != null) {
      if (title.isNotEmpty) {
        title += ' ${_toTitleCase(widget.filterGroup!)}';
      } else {
        title = '${_toTitleCase(widget.filterGroup!)} Details';
      }
    } else if (title.isEmpty) {
      title = 'All Pending Fees';
    } else {
      title += ' Fees';
    }

    return title;
  }

  String _toTitleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
