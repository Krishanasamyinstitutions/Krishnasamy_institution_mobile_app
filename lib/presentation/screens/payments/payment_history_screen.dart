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
import '../../providers/cart_provider.dart';
import '../../widgets/student_avatar.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const PaymentHistoryScreen({super.key, this.initialTab});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  late String _activeFilter;

  @override
  void initState() {
    super.initState();
    // Set initial tab based on parameter, default to 'All'
    final tab = widget.initialTab?.toLowerCase();
    if (tab == 'paid') {
      _activeFilter = 'Paid';
    } else if (tab == 'failed') {
      _activeFilter = 'Failed';
    } else {
      _activeFilter = 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paidFees = ref.watch(paidFeesProvider);
    final filters = ['All', 'Paid', 'Failed'];

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
                      _buildHeader(context),
                      const SizedBox(height: 20),
                      _buildFilterTabs(filters),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: filteredFees.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _buildTransactionCard(filteredFees[index]);
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track all your fee payments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // Cart Icon - Dark theme
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
          // Notification Icon - Dark theme
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
      ),
    );
  }

  Widget _buildFilterTabs(List<String> filters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: filters.map((filter) {
            final isActive = _activeFilter == filter;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeFilter = filter;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primary600],
                          )
                        : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? Colors.white : AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(FeeModel fee) {
    final isPaid = fee.paidstatus == 'P';

    return GestureDetector(
      onTap: () => context.push('/fees/${fee.demId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isPaid ? AppColors.shadowGreen : AppColors.shadowPink,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTransactionIcon(fee.demfeetype, isPaid),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${fee.demfeeterm} - ${fee.demfeetype}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fee.demfeecategory ?? fee.demfeeyear,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPaid ? AppColors.cardGreen : AppColors.cardRose,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPaid ? 'Paid' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPaid ? AppColors.cardGreenDark : AppColors.cardRoseDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹ ${NumberFormat('#,##,###').format(fee.paidamount.toInt())}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textTertiary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('dd MMM yyyy').format(fee.createdat),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.textHint,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(String feeType, bool isPaid) {
    final lowerType = feeType.toLowerCase();
    Color bgColor;
    Color iconColor;
    IconData? iconData;

    String? svgPath;
    if (!isPaid) {
      bgColor = AppColors.cardRose;
      iconColor = AppColors.cardRoseDark;
      iconData = Icons.close;
    } else if (lowerType.contains('bus') || lowerType.contains('transport')) {
      bgColor = AppColors.cardGreen;
      iconColor = AppColors.cardGreenDark;
      svgPath = 'assets/icons/bus-solid.svg';
    } else if (lowerType.contains('tuition') || lowerType.contains('term') || lowerType.contains('school')) {
      bgColor = AppColors.cardPurple;
      iconColor = AppColors.cardPurpleDark;
      svgPath = 'assets/school Icons/book.svg';
    } else if (lowerType.contains('exam')) {
      bgColor = AppColors.cardCyan;
      iconColor = AppColors.cardCyanDark;
      svgPath = 'assets/school Icons/book.svg';
    } else {
      bgColor = AppColors.cardBlue;
      iconColor = AppColors.cardBlueDark;
      iconData = Icons.receipt_rounded;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: svgPath != null
            ? SvgPicture.asset(
                svgPath,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              )
            : Icon(iconData!, size: 24, color: iconColor),
      ),
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    Color iconBgColor;
    Color iconColor;

    switch (_activeFilter) {
      case 'Paid':
        title = 'No Paid Payments';
        subtitle = 'Your successful payments will appear here.';
        icon = Icons.check_circle_outline_rounded;
        iconBgColor = AppColors.cardGreen;
        iconColor = AppColors.cardGreenDark;
        break;
      case 'Failed':
        title = 'No Failed Payments';
        subtitle = 'Failed payment attempts will appear here.';
        icon = Icons.error_outline_rounded;
        iconBgColor = AppColors.cardRose;
        iconColor = AppColors.cardRoseDark;
        break;
      default:
        title = 'No Payments Yet';
        subtitle = 'Your payment history will appear here once you make a payment.';
        icon = Icons.receipt_long_rounded;
        iconBgColor = AppColors.cardPurple;
        iconColor = AppColors.cardPurpleDark;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
