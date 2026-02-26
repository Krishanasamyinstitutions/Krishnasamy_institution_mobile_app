import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../config/routes.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/payment_model.dart';
import '../../providers/payment_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/notification_provider.dart';

class PaymentHistoryScreen extends ConsumerStatefulWidget {
  final String? initialTab;

  const PaymentHistoryScreen({super.key, this.initialTab});

  @override
  ConsumerState<PaymentHistoryScreen> createState() =>
      _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends ConsumerState<PaymentHistoryScreen> {
  late String _activeFilter;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
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
    final paymentsAsync = ref.watch(paymentsProvider);
    final filters = ['All', 'Paid', 'Failed'];

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Desktop: no header (MainScaffold top bar handles it) | Mobile: shadow header
          if (!context.isDesktop)
            Container(
              color: AppColors.headerBg(context),
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBg(context),
                    boxShadow: AppColors.cardShadow(context),
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
            child: paymentsAsync.when(
              data: (payments) => _buildTransactionList(payments),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading payments: $e')),
            ),
          ),
        ],
      ),
    );
  }

  List<PaymentModel> _filterPayments(List<PaymentModel> payments) {
    if (_activeFilter == 'All') return payments;
    if (_activeFilter == 'Paid') {
      return payments.where((p) => p.paystatus == 'C').toList();
    }
    if (_activeFilter == 'Failed') {
      return payments.where((p) => p.paystatus == 'F').toList();
    }
    return payments;
  }

  Widget _buildTransactionList(List<PaymentModel> payments) {
    final filtered = _filterPayments(payments);

    if (filtered.isEmpty) {
      return _buildEmptyState();
    }

    const int pageSize = 10;
    final totalPages = (filtered.length / pageSize).ceil();
    final paged = filtered.skip(_currentPage * pageSize).take(pageSize).toList();

    if (context.isDesktop) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(context),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: _buildFilterTabs(['All', 'Paid', 'Failed']),
            ),
            Expanded(child: _buildDesktopTable(paged)),
            _buildPaginationControls(totalPages),
          ],
        ),
      );
    }

    // Mobile: show all filtered items in a scrollable list (no pagination)
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTransactionCard(filtered[index]),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);

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
                Text(
                  'Payment History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track all your fee payments',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryC(context),
                  ),
                ),
              ],
            ),
          ),
          // Cart Icon
          GestureDetector(
            onTap: () => context.push(Routes.cart),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
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
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
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
          // Notification Icon
          GestureDetector(
            onTap: () => context.go(Routes.notifications),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.iconButtonBg(context),
                shape: BoxShape.circle,
              ),
              child: Stack(
                clipBehavior: Clip.none,
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
                  if (notificationCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          notificationCount > 9 ? '9+' : '$notificationCount',
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
          color: AppColors.filterBg(context),
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
                    _currentPage = 0;
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
                        color: isActive ? Colors.white : AppColors.textSecondaryC(context),
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

  Widget _buildTransactionCard(PaymentModel payment) {
    final isSuccess = payment.paystatus == 'C';

    return GestureDetector(
      onTap: () => context.push('/payment-history/${payment.payId}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  const BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
        ),
        child: Column(
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSuccess
                          ? AppColors.cardGreen
                          : AppColors.cardRose,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSuccess ? Icons.check : Icons.close,
                      size: 18,
                      color: isSuccess
                          ? AppColors.cardGreenDark
                          : AppColors.cardRoseDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Payment number + Year + Method
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          payment.paynumber ?? 'PAY/${payment.payId}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payment.yrlabel ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textHintC(context),
                          ),
                        ),
                        if (isSuccess && payment.paymethod != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            payment.paymethod!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textHintC(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status badge + Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? AppColors.cardGreen
                              : AppColors.cardRose,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          payment.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSuccess
                                ? AppColors.cardGreenDark
                                : AppColors.cardRoseDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹ ${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isSuccess
                              ? AppColors.textPrimaryC(context)
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Divider
            Divider(height: 1, color: AppColors.borderC(context).withValues(alpha: 0.3)),
            // Date row with chevron
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textHintC(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(
                      payment.paydate ?? payment.createdat,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHintC(context),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textHintC(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPaginationControls(int totalPages) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Previous
          _buildPageButton(
            icon: Icons.chevron_left,
            enabled: _currentPage > 0,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 8),
          // Page numbers
          for (int i = 0; i < totalPages; i++) ...[
            if (i == 0 || i == totalPages - 1 || (i >= _currentPage - 1 && i <= _currentPage + 1))
              GestureDetector(
                onTap: () => setState(() => _currentPage = i),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: i != _currentPage
                        ? Border.all(color: AppColors.borderC(context))
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: i == _currentPage
                            ? Colors.white
                            : AppColors.textSecondaryC(context),
                      ),
                    ),
                  ),
                ),
              )
            else if ((i == 1 && _currentPage > 2) ||
                (i == totalPages - 2 && _currentPage < totalPages - 3))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('…', style: TextStyle(color: AppColors.textHintC(context))),
              ),
          ],
          const SizedBox(width: 8),
          // Next
          _buildPageButton(
            icon: Icons.chevron_right,
            enabled: _currentPage < totalPages - 1,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderC(context)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textPrimaryC(context) : AppColors.textHintC(context),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(List<PaymentModel> payments) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header row
          Container(
            color: AppColors.filterBg(context),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text('Date', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text('Payment No', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Method', style: _tableHeaderStyle(context)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Amount', style: _tableHeaderStyle(context), textAlign: TextAlign.right),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('Status', style: _tableHeaderStyle(context), textAlign: TextAlign.center),
                  ),
                ],
              ),
            ),
            // Data rows
            ...payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;
              final isSuccess = payment.paystatus == 'C';
              final isLast = index == payments.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () => context.push('/payment-history/${payment.payId}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Row(
                        children: [
                          // Date
                          Expanded(
                            flex: 2,
                            child: Text(
                              DateFormat('dd MMM yyyy').format(payment.paydate ?? payment.createdat),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryC(context),
                              ),
                            ),
                          ),
                          // Payment No
                          Expanded(
                            flex: 3,
                            child: Text(
                              payment.paynumber ?? 'PAY/${payment.payId}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimaryC(context),
                              ),
                            ),
                          ),
                          // Method
                          Expanded(
                            flex: 2,
                            child: Text(
                              isSuccess ? (payment.paymethod ?? '—') : '—',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondaryC(context),
                              ),
                            ),
                          ),
                          // Amount
                          Expanded(
                            flex: 2,
                            child: Text(
                              '₹${NumberFormat('#,##,###').format(payment.transtotalamount.toInt())}',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isSuccess ? AppColors.textPrimaryC(context) : AppColors.error,
                              ),
                            ),
                          ),
                          // Status badge
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSuccess ? AppColors.cardGreen : AppColors.cardRose,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  payment.statusText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSuccess ? AppColors.cardGreenDark : AppColors.cardRoseDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(height: 1, color: AppColors.borderC(context).withValues(alpha: 0.5)),
                ],
              );
            }),
          ],
        ),
    );
  }

  TextStyle _tableHeaderStyle(BuildContext context) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondaryC(context),
        letterSpacing: 0.3,
      );

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
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondaryC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
