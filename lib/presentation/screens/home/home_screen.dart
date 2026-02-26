import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/fee_model.dart';
import '../../providers/student_provider.dart';
import '../../providers/fee_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/notification_provider.dart';
import '../../../core/utils/extensions.dart';
import '../../widgets/common/desktop_content_card.dart';
import '../../../core/utils/birthday_utils.dart';
import '../../widgets/common/birthday_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _birthdayChecked = false;
  ProviderSubscription? _studentSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowBirthdayDialog();
      _studentSubscription = ref.listenManual(selectedStudentProvider, (previous, next) {
        if (previous == null && next != null && !_birthdayChecked) {
          _checkAndShowBirthdayDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _studentSubscription?.close();
    super.dispose();
  }

  Future<void> _checkAndShowBirthdayDialog() async {
    if (_birthdayChecked) return;

    final student = ref.read(selectedStudentProvider);
    final shouldShow = await BirthdayUtils.shouldShowBirthdayDialog(student);

    if (shouldShow && mounted) {
      _birthdayChecked = true;
      await BirthdayUtils.markAsShown(student!.stuId);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => BirthdayDialog(
          studentName: student.name,
          onDismiss: () => Navigator.of(dialogContext).pop(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    ref.watch(cartRestorerProvider); // Restore cart from DB on startup
    final feeSummaryAsync = ref.watch(feeSummaryProvider);
    final feesByGroup = ref.watch(pendingFeesByGroupProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);
    final notificationCount = ref.watch(notificationCountProvider);
    final overdueGroups = ref.watch(overdueByGroupProvider);
    final dueSoonGroups = ref.watch(dueSoonByGroupProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
          // Desktop: no page title (shown in top bar) | Mobile: header with nav icons
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildHeader(context, selectedStudent, cartItemCount, notificationCount),
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
              padding: context.isDesktop
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!context.isDesktop) const SizedBox(height: 28),
                  if (context.isDesktop) const SizedBox(height: 4),

                  // Desktop: summary stat cards
                  if (context.isDesktop) ...[
                    _buildDesktopStatCards(context, feeSummaryAsync, overdueGroups, dueSoonGroups),
                    const SizedBox(height: 20),
                  ],

                  // Mobile only: balance
                  if (!context.isDesktop) ...[
                    _buildBalanceSection(context, feeSummaryAsync),
                    const SizedBox(height: 28),
                  ],

                  // Spending/Fee Categories Section
                  _buildSpendingSection(context, feesByGroup),

                  const SizedBox(height: 20),

                  // Activity Section - Overdue & Due Soon
                  _buildActivitySection(context, overdueGroups, dueSoonGroups),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, dynamic selectedStudent, int cartItemCount, int notificationCount) {
    final studentName = selectedStudent?.name ?? 'Student';
    final className = selectedStudent?.className ?? 'N/A';
    final admissionNumber = selectedStudent?.admissionNumber ?? 'N/A';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile Avatar
        GestureDetector(
          onTap: () => context.go(Routes.profile),
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primary600],
              ),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: (selectedStudent?.photoUrl != null && selectedStudent!.photoUrl!.trim().isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: selectedStudent.photoUrl!,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    errorWidget: (context, url, error) => Center(
                      child: Text(
                        _getInitials(studentName),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Center(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                studentName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryC(context),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              RichText(
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Adm No: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryC(context),
                      ),
                    ),
                    TextSpan(
                      text: admissionNumber,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                    TextSpan(
                      text: ' | Class: ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryC(context),
                      ),
                    ),
                    TextSpan(
                      text: className,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                  ],
                ),
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
        // Notification Icon - Dark theme with badge
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
    );
  }

  Widget _buildBalanceSection(BuildContext context, AsyncValue<FeeSummary> feeSummaryAsync) {
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
        Text(
          'Balance Fees Due',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryC(context),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹${NumberFormat('#,##,###').format(totalPending.clamp(0, double.infinity))}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '/',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: AppColors.textHintC(context),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              academicYear,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondaryC(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpendingSection(BuildContext context, Map<String, double> feesByGroup) {
    final categories = [
      {'name': 'School Fees', 'icon': Icons.school_rounded, 'color': const Color(0xFF22C55E), 'iconBgColor': const Color(0xFFDCFCE7)},
      {'name': 'Van Fees', 'icon': Icons.directions_bus_rounded, 'color': const Color(0xFFF59E0B), 'iconBgColor': const Color(0xFFFEF3C7)},
      {'name': 'Exam Fees', 'icon': Icons.assignment_rounded, 'color': const Color(0xFF06B6D4), 'iconBgColor': const Color(0xFFCFFAFE)},
      {'name': 'Other', 'icon': Icons.more_horiz_rounded, 'color': AppColors.cardPurple, 'iconBgColor': const Color(0xFFF3E8FF)},
    ];

    // Sort fee groups by amount in descending order
    final sortedEntries = feesByGroup.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: [
        if (!context.isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fees Breakup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryC(context),
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
        if (!context.isDesktop) const SizedBox(height: 16),
        if (context.isDesktop)
          DesktopContentCard(
            title: 'Fees Breakup',
            trailing: GestureDetector(
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
            child: SizedBox(
              height: 165,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < (feesByGroup.isEmpty ? categories.length : sortedEntries.length).clamp(0, 4); i++) ...[
                    if (i > 0) const SizedBox(width: 12),
                    if (feesByGroup.isEmpty)
                      Expanded(
                        child: _buildSpendingCard(
                          context: context,
                          icon: categories[i]['icon'] as IconData?,
                          svgPath: categories[i]['svgPath'] as String?,
                          label: categories[i]['name'] as String,
                          groupName: categories[i]['name'] as String,
                          amount: 0,
                          primaryColor: categories[i]['color'] as Color,
                          iconBgColor: categories[i]['iconBgColor'] as Color,
                          isFirst: i == 0,
                          fixedWidth: false,
                        ),
                      )
                    else
                      Expanded(
                        child: _buildSpendingCard(
                          context: context,
                          icon: _getIconForFeeGroup(sortedEntries[i].key)['icon'] as IconData?,
                          svgPath: _getIconForFeeGroup(sortedEntries[i].key)['svgPath'] as String?,
                          label: _toTitleCase(sortedEntries[i].key),
                          groupName: sortedEntries[i].key,
                          amount: sortedEntries[i].value,
                          primaryColor: _getIconForFeeGroup(sortedEntries[i].key)['color'] as Color,
                          iconBgColor: _getIconForFeeGroup(sortedEntries[i].key)['iconBgColor'] as Color,
                          isFirst: i == 0,
                          fixedWidth: false,
                        ),
                      ),
                  ],
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 165,
            child: ListView.separated(
              clipBehavior: Clip.none,
              scrollDirection: Axis.horizontal,
              itemCount: feesByGroup.isEmpty ? categories.length : sortedEntries.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                if (feesByGroup.isEmpty) {
                  final cat = categories[index];
                  return _buildSpendingCard(
                    context: context,
                    icon: cat['icon'] as IconData?,
                    svgPath: cat['svgPath'] as String?,
                    label: cat['name'] as String,
                    groupName: cat['name'] as String,
                    amount: 0,
                    primaryColor: cat['color'] as Color,
                    iconBgColor: cat['iconBgColor'] as Color,
                    isFirst: index == 0,
                  );
                }
                final entry = sortedEntries[index];
                final iconData = _getIconForFeeGroup(entry.key);
                return _buildSpendingCard(
                  context: context,
                  icon: iconData['icon'] as IconData?,
                  svgPath: iconData['svgPath'] as String?,
                  label: _toTitleCase(entry.key),
                  groupName: entry.key,
                  amount: entry.value,
                  primaryColor: iconData['color'] as Color,
                  iconBgColor: iconData['iconBgColor'] as Color,
                  isFirst: index == 0,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSpendingCard({
    required BuildContext context,
    IconData? icon,
    String? svgPath,
    required String label,
    required String groupName,
    required double amount,
    required Color primaryColor,
    required Color iconBgColor,
    required bool isFirst,
    bool fixedWidth = true,
  }) {
    // First card has colored background, others have white background
    final bool hasColoredBg = isFirst && amount > 0;

    return GestureDetector(
      onTap: () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(groupName)}'),
      child: Container(
        width: fixedWidth ? 160 : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasColoredBg ? primaryColor : AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: hasColoredBg
              ? null
              : Border.all(
                  color: AppColors.borderC(context),
                  width: 1,
                ),
          boxShadow: hasColoredBg
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : AppColors.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Icon and Due badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasColoredBg
                        ? Colors.white.withValues(alpha: 0.2)
                        : iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: svgPath != null
                        ? SvgPicture.asset(
                            svgPath,
                            width: 22,
                            height: 22,
                            colorFilter: ColorFilter.mode(
                              hasColoredBg ? Colors.white : primaryColor,
                              BlendMode.srcIn,
                            ),
                          )
                        : Icon(
                            icon,
                            size: 22,
                            color: hasColoredBg ? Colors.white : primaryColor,
                          ),
                  ),
                ),
                // Due badge
                if (amount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasColoredBg
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFFEF3C7),
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
                            color: hasColoredBg
                                ? Colors.white
                                : const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_upward_rounded,
                          size: 12,
                          color: hasColoredBg
                              ? Colors.white
                              : const Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Spacer(),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: hasColoredBg
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.textSecondaryC(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Amount and arrow row
            Row(
              children: [
                Expanded(
                  child: Text(
                    NumberFormat('#,##,###').format(amount.toInt()),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: hasColoredBg ? Colors.white : AppColors.textPrimaryC(context),
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: hasColoredBg ? Colors.white : AppColors.textSecondaryC(context),
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
        if (!context.isDesktop) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryC(context),
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
        ],
        if (!hasAnyFees)
          _buildEmptyActivity(context)
        else if (context.isDesktop)
          DesktopContentCard(
            title: 'Fee Status',
            trailing: GestureDetector(
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
            hasPadding: false,
            child: _buildDesktopFeeTable(context, overdueGroups, dueSoonGroups, hasOverdue, hasDueSoon),
          )
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
              child: _buildFeeGroupCard(context, group, AppColors.warning, filterStatus: 'dueSoon', isDisabled: hasOverdue),
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildDesktopFeeTable(BuildContext context, List<FeeGroupSummary> overdueGroups, List<FeeGroupSummary> dueSoonGroups, bool hasOverdue, bool hasDueSoon) {
    final headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryC(context), letterSpacing: 0.5);
    final allRows = <Widget>[];

    if (hasOverdue) {
      for (final group in overdueGroups) {
        allRows.add(_buildDesktopFeeRow(context, group, AppColors.error, filterStatus: 'overdue'));
        allRows.add(Divider(height: 1, color: AppColors.borderC(context)));
      }
    }
    if (hasDueSoon) {
      for (final group in dueSoonGroups) {
        allRows.add(_buildDesktopFeeRow(context, group, AppColors.warning, filterStatus: 'dueSoon', isDisabled: hasOverdue));
        allRows.add(Divider(height: 1, color: AppColors.borderC(context)));
      }
    }
    if (allRows.isNotEmpty) allRows.removeLast(); // remove trailing divider

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.scaffoldBg(context),
          child: Row(
            children: [
              const SizedBox(width: 56), // icon (44) + gap (12)
              Expanded(flex: 3, child: Text('Fee Group', style: headerStyle)),
              Expanded(flex: 2, child: Text('Period', style: headerStyle)),
              SizedBox(width: 140, child: Text('Status', style: headerStyle)),
              SizedBox(width: 100, child: Text('Amount', textAlign: TextAlign.right, style: headerStyle)),
              const SizedBox(width: 32),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.borderC(context)),
        // Data rows
        ...allRows,
      ],
    );
  }

  Widget _buildDesktopFeeRow(BuildContext context, FeeGroupSummary group, Color statusColor, {required String filterStatus, bool isDisabled = false}) {
    final now = DateTime.now();
    String timeInfo = '';
    if (group.nearestDueDate != null) {
      if (group.isOverdue) {
        final days = now.difference(group.nearestDueDate!).inDays;
        timeInfo = '$days days overdue';
      } else {
        final days = group.nearestDueDate!.difference(now).inDays;
        timeInfo = days == 0 ? 'Due today' : 'Due in $days days';
      }
    }

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
      groupBg = const Color(0xFFFEF3C7);
      groupIconColor = const Color(0xFFF59E0B);
    } else if (lowerName.contains('hostel')) {
      groupIcon = Icons.hotel_rounded;
      groupBg = const Color(0xFFDBEAFE);
      groupIconColor = const Color(0xFF3B82F6);
    } else if (lowerName.contains('exam')) {
      groupIcon = Icons.assignment_rounded;
      groupBg = const Color(0xFFCFFAFE);
      groupIconColor = const Color(0xFF06B6D4);
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: InkWell(
        onTap: isDisabled ? null : () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}&status=$filterStatus'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: groupBg, borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Icon(groupIcon, size: 22, color: groupIconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  _toTitleCase(group.groupName),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryC(context)),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  group.periodText,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondaryC(context)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 140,
                child: timeInfo.isNotEmpty
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          timeInfo,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  '₹${NumberFormat('#,##,###').format(group.totalAmount.toInt())}',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimaryC(context)),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHintC(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required double totalAmount,
    required Color color,
    IconData? icon,
    String? svgPath,
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
          child: Center(
            child: svgPath != null
                ? SvgPicture.asset(
                    svgPath,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                  )
                : Icon(icon, size: 16, color: color),
          ),
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

  Widget _buildFeeGroupCard(BuildContext context, FeeGroupSummary group, Color statusColor, {required String filterStatus, bool isDisabled = false}) {
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
      groupBg = const Color(0xFFFEF3C7);
      groupIconColor = const Color(0xFFF59E0B);
    } else if (lowerName.contains('hostel')) {
      groupIcon = Icons.hotel_rounded;
      groupBg = const Color(0xFFDBEAFE);
      groupIconColor = const Color(0xFF3B82F6);
    } else if (lowerName.contains('exam')) {
      groupIcon = Icons.assignment_rounded;
      groupBg = const Color(0xFFCFFAFE);
      groupIconColor = const Color(0xFF06B6D4);
    }

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: GestureDetector(
      onTap: isDisabled ? null : () => context.push('${Routes.allPendingFees}?group=${Uri.encodeComponent(group.groupName)}&status=$filterStatus'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: AppColors.cardShadow(context),
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
              child: Center(
                child: Icon(groupIcon, size: 22, color: groupIconColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _toTitleCase(group.groupName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          group.periodText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondaryC(context),
                          ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.textPrimaryC(context),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildEmptyActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.cardGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              size: 32,
              color: AppColors.cardGreenDark,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No overdue or upcoming fees',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondaryC(context),
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

  Map<String, dynamic> _getIconForFeeGroup(String groupName) {
    final lowerName = groupName.toLowerCase();

    if (lowerName.contains('school') || lowerName.contains('tuition')) {
      return {
        'icon': Icons.school_rounded,
        'color': const Color(0xFF22C55E),
        'iconBgColor': const Color(0xFFDCFCE7),
      };
    } else if (lowerName.contains('van') || lowerName.contains('bus') || lowerName.contains('transport')) {
      return {
        'icon': Icons.directions_bus_rounded,
        'color': const Color(0xFFF59E0B),
        'iconBgColor': const Color(0xFFFEF3C7),
      };
    } else if (lowerName.contains('hostel')) {
      return {
        'icon': Icons.hotel_rounded,
        'color': const Color(0xFF3B82F6),
        'iconBgColor': const Color(0xFFDBEAFE),
      };
    } else if (lowerName.contains('exam') || lowerName.contains('test')) {
      return {
        'icon': Icons.assignment_rounded,
        'color': const Color(0xFF06B6D4),
        'iconBgColor': const Color(0xFFCFFAFE),
      };
    } else {
      return {
        'icon': Icons.receipt_rounded,
        'color': AppColors.cardPurple,
        'iconBgColor': const Color(0xFFF3E8FF),
      };
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  // ────────────────────────────────────────────────────────────────
  // Desktop-only widgets
  // ────────────────────────────────────────────────────────────────

  Widget _buildDesktopStatCards(
    BuildContext context,
    AsyncValue<FeeSummary> feeSummaryAsync,
    List<FeeGroupSummary> overdueGroups,
    List<FeeGroupSummary> dueSoonGroups,
  ) {
    final feeSummary = feeSummaryAsync.valueOrNull;
    final totalPending = feeSummary?.totalPending ?? 0;
    final totalOverdue = overdueGroups.fold(0.0, (sum, g) => sum + g.totalAmount);
    final totalDueSoon = dueSoonGroups.fold(0.0, (sum, g) => sum + g.totalAmount);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Dues',
            amount: totalPending,
            icon: Icons.account_balance_wallet_rounded,
            iconBg: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            onTap: () => context.push(Routes.payAllFees),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Overdue',
            amount: totalOverdue,
            icon: Icons.warning_amber_rounded,
            iconBg: AppColors.errorLight,
            iconColor: AppColors.error,
            onTap: () => context.push('${Routes.allPendingFees}?status=overdue'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Total Paid',
            amount: feeSummary?.totalPaid ?? 0,
            icon: Icons.check_circle_rounded,
            iconBg: AppColors.primary.withValues(alpha: 0.12),
            iconColor: AppColors.primary,
            onTap: () => context.push(Routes.paidFees),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context: context,
            label: 'Due Soon',
            amount: totalDueSoon,
            icon: Icons.schedule_rounded,
            iconBg: AppColors.warningLight,
            iconColor: AppColors.warning,
            onTap: () => context.push('${Routes.allPendingFees}?status=dueSoon'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required double amount,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryC(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '₹${NumberFormat('#,##,###').format(amount.clamp(0, double.infinity).toInt())}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textHintC(context),
            ),
          ],
        ),
      ),
    );
  }
}
