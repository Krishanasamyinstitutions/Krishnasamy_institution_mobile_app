import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/student_provider.dart';
import '../../providers/notification_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/institution_provider.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.home)) return 0;
    if (location.startsWith(Routes.paymentHistory)) return 1;
    if (location.startsWith(Routes.notifications)) return 2;
    if (location.startsWith(Routes.profile)) return 3;
    // Drill-down routes map to their parent tab
    if (location.startsWith('/transaction')) return 1;
    return 0;
  }

  bool _isDrillDownRoute(String location) {
    return location.startsWith('/support') ||
        location.startsWith('/cart') ||
        location.startsWith('/all-pending-fees') ||
        location.startsWith('/pay-all-fees') ||
        location.startsWith('/paid-fees') ||
        location.startsWith('/switch-student') ||
        location.startsWith('/transaction/') ||
        (location.startsWith('/fees/') && location != '/fees') ||
        (location.startsWith('/payment-history/') &&
            location != '/payment-history') ||
        (location.startsWith('/notifications/') &&
            location != '/notifications');
  }

  String _getPageTitle(String location) {
    if (location.startsWith('/support')) return 'Support';
    if (location.startsWith('/switch-student')) return 'Switch Student';
    if (location.startsWith('/cart')) return 'Payment Queue';
    if (location.startsWith('/all-pending-fees')) return 'All Pending Fees';
    if (location.startsWith('/pay-all-fees')) return 'Pay All Fees';
    if (location.startsWith('/paid-fees')) return 'Paid Fees';
    if (location.startsWith('/transaction')) return 'Transaction Details';
    if (location.startsWith('/fees/')) return 'Fee Details';
    if (location.startsWith('/payment-history/') &&
        location != '/payment-history') return 'Transaction Details';
    if (location.startsWith('/notifications/') &&
        location != '/notifications') return 'Notification';
    if (location.startsWith('/home')) return 'Dashboard';
    if (location.startsWith('/payment-history')) return 'Payment History';
    if (location.startsWith('/notifications')) return 'Notifications';
    if (location.startsWith('/profile')) return 'Profile';
    return 'Dashboard';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (context.isDesktop) {
      return _buildDesktopLayout(context, ref, selectedIndex, isDark);
    }
    return _buildMobileLayout(context, selectedIndex, isDark);
  }

  // ────────────────────────────────────────────────────────────────
  // Desktop: full-height sidebar + (top bar + content)
  // ────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout(
      BuildContext context, WidgetRef ref, int selectedIndex, bool isDark) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Full-height sidebar (floating card)
            _buildDesktopSidebar(context, ref, selectedIndex, isDark),
            const SizedBox(width: 16),
            // Top bar + content (floating card)
            Expanded(
              child: Column(
                children: [
                  // Top bar as rounded card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.cardShadow(context),
                    ),
                    child: _buildDesktopTopBar(context, ref, isDark, selectedIndex),
                  ),
                  const SizedBox(height: 16),
                  // Content area
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Desktop top header bar (page title + search + actions)
  // ────────────────────────────────────────────────────────────────
  Widget _buildDesktopTopBar(
      BuildContext context, WidgetRef ref, bool isDark, int selectedIndex) {
    final selectedStudent = ref.watch(selectedStudentProvider);
    final unreadCount = ref.watch(notificationCountProvider);
    final cartCount = ref.watch(cartItemCountProvider);
    final location = GoRouterState.of(context).matchedLocation;
    final pageTitle = _getPageTitle(location);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Page title
          Text(
            pageTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryC(context),
            ),
          ),
          const SizedBox(width: 32),
          // Search bar
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _TopBarSearchField(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          // Cart icon with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.push(Routes.cart),
                icon: Icon(
                  Icons.shopping_cart_outlined,
                  color: AppColors.textSecondaryC(context),
                  size: 24,
                ),
              ),
              if (cartCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        cartCount > 9 ? '9+' : '$cartCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 4),
          // Notification bell with unread badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () => context.go(Routes.notifications),
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textSecondaryC(context),
                  size: 24,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          // User avatar + student name + dropdown menu
          PopupMenuButton<String>(
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: AppColors.cardBg(context),
            onSelected: (value) {
              if (value == 'switch') {
                context.go(Routes.switchStudent);
              } else if (value == 'logout') {
                _showLogoutDialog(context, ref);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'switch',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.textSecondaryC(context)),
                    const SizedBox(width: 10),
                    Text(
                      'Switch Account',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
                    const SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (selectedStudent?.photoUrl != null && selectedStudent!.photoUrl!.trim().isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: selectedStudent.photoUrl!,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorWidget: (context, url, error) => Center(
                            child: Text(
                              _getInitials(selectedStudent.name),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            _getInitials(selectedStudent?.name ?? 'U'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedStudent?.name ?? '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryC(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Student',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHintC(context),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.textHintC(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  // ────────────────────────────────────────────────────────────────
  // Desktop sidebar — full-height with logo, nav, settings & logout
  // ────────────────────────────────────────────────────────────────
  Widget _buildDesktopSidebar(
      BuildContext context, WidgetRef ref, int selectedIndex, bool isDark) {
    final institutionAsync = ref.watch(selectedStudentInstitutionProvider);
    final institution = institutionAsync.valueOrNull;
    final schoolName = institution?.name ?? 'School Fees';
    final logoUrl = institution?.logoUrl;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // School Logo + Name (64px to align with top bar)
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasLogo
                      ? CachedNetworkImage(
                          imageUrl: logoUrl,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                              Icons.school_rounded,
                              color: Colors.white,
                              size: 20),
                        )
                      : const Icon(Icons.school_rounded,
                          color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    schoolName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryC(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderC(context)),
          const SizedBox(height: 20),
          // Menu label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'MENU',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textHintC(context),
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Nav items
          _buildSidebarItem(
            context: context,
            index: 0,
            selectedIndex: selectedIndex,
            label: 'Dashboard',
            outlinedIcon: Icons.dashboard_outlined,
            filledIcon: Icons.dashboard_rounded,
            onTap: () => context.go(Routes.home),
          ),
          _buildSidebarItem(
            context: context,
            index: 1,
            selectedIndex: selectedIndex,
            label: 'History',
            outlinedIcon: Icons.receipt_long_outlined,
            filledIcon: Icons.receipt_long_rounded,
            onTap: () => context.go(Routes.paymentHistory),
          ),
          _buildSidebarItem(
            context: context,
            index: 2,
            selectedIndex: selectedIndex,
            label: 'Alerts',
            outlinedIcon: Icons.notifications_outlined,
            filledIcon: Icons.notifications_rounded,
            onTap: () => context.go(Routes.notifications),
          ),
          _buildSidebarItem(
            context: context,
            index: 3,
            selectedIndex: selectedIndex,
            label: 'Profile',
            outlinedIcon: Icons.person_outline_rounded,
            filledIcon: Icons.person_rounded,
            onTap: () => context.go(Routes.profile),
          ),
          // School logo watermark in center
          Expanded(
            child: Center(
              child: hasLogo
                  ? Opacity(
                      opacity: isDark ? 0.06 : 0.05,
                      child: CachedNetworkImage(
                        imageUrl: logoUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorWidget: (context, url, error) =>
                            const SizedBox.shrink(),
                      ),
                    )
                  : Opacity(
                      opacity: isDark ? 0.06 : 0.05,
                      child: Icon(
                        Icons.school_rounded,
                        size: 120,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
            ),
          ),
          Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.borderC(context)),
          const SizedBox(height: 8),
          _buildSidebarBottomItem(
            context,
            Icons.logout_rounded,
            'Logout',
            () => _showLogoutDialog(context, ref),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required String label,
    required IconData outlinedIcon,
    required IconData filledIcon,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 20,
              color: isSelected ? AppColors.primary : AppColors.textHintC(context),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primary : AppColors.textHintC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarBottomItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textHintC(context)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textHintC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondaryC(context))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ref.read(authProvider.notifier).signOut();
              context.go(Routes.welcome);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Mobile: existing bottom nav bar layout
  // ────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout(
      BuildContext context, int selectedIndex, bool isDark) {
    final location = GoRouterState.of(context).matchedLocation;
    if (_isDrillDownRoute(location)) {
      return child; // Drill-down screen handles its own Scaffold
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: AppColors.cardBg(context),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBg(context),
        body: child,
        extendBody: false,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg(context),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    context: context,
                    index: 0,
                    selectedIndex: selectedIndex,
                    label: 'Home',
                    outlinedIcon: Icons.dashboard_outlined,
                    filledIcon: Icons.dashboard_rounded,
                    onTap: () => context.go(Routes.home),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 1,
                    selectedIndex: selectedIndex,
                    label: 'History',
                    outlinedIcon: Icons.receipt_long_outlined,
                    filledIcon: Icons.receipt_long_rounded,
                    onTap: () => context.go(Routes.paymentHistory),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 2,
                    selectedIndex: selectedIndex,
                    label: 'Alerts',
                    outlinedIcon: Icons.notifications_outlined,
                    filledIcon: Icons.notifications_rounded,
                    onTap: () => context.go(Routes.notifications),
                  ),
                  _buildNavItem(
                    context: context,
                    index: 3,
                    selectedIndex: selectedIndex,
                    label: 'Profile',
                    outlinedIcon: Icons.person_outline_rounded,
                    filledIcon: Icons.person_rounded,
                    onTap: () => context.go(Routes.profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required String label,
    required IconData outlinedIcon,
    required IconData filledIcon,
    required VoidCallback onTap,
  }) {
    final isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlinedIcon,
              size: 24,
              color: isSelected ? AppColors.primary : AppColors.textHintC(context),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected ? AppColors.primary : AppColors.textHintC(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful search field for the desktop top bar.
class _TopBarSearchField extends StatefulWidget {
  @override
  State<_TopBarSearchField> createState() => _TopBarSearchFieldState();
}

class _TopBarSearchFieldState extends State<_TopBarSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _hasFocus = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;
    if (q.contains('pay') ||
        q.contains('history') ||
        q.contains('receipt') ||
        q.contains('transaction')) {
      context.go(Routes.paymentHistory);
    } else if (q.contains('notif') || q.contains('alert')) {
      context.go(Routes.notifications);
    } else if (q.contains('profile') ||
        q.contains('account') ||
        q.contains('student')) {
      context.go(Routes.profile);
    } else if (q.contains('support') ||
        q.contains('help') ||
        q.contains('contact')) {
      context.go(Routes.support);
    } else if (q.contains('cart') || q.contains('queue')) {
      context.go(Routes.cart);
    } else if (q.contains('paid')) {
      context.go(Routes.paidFees);
    } else {
      context.go(
          '${Routes.allPendingFees}?group=${Uri.encodeComponent(query.trim())}');
    }
    _controller.clear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 42,
      decoration: BoxDecoration(
        color: _hasFocus
            ? AppColors.cardBg(context)
            : AppColors.scaffoldBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasFocus
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.borderC(context).withValues(alpha: 0.5),
          width: _hasFocus ? 1.5 : 1,
        ),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.search_rounded,
            size: 18,
            color: _hasFocus
                ? AppColors.primary
                : AppColors.textHintC(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textAlignVertical: TextAlignVertical.center,
              decoration: InputDecoration(
                hintText: 'Search fees, payments, pages...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textHintC(context),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryC(context),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _onSearch,
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _controller.clear();
                setState(() {});
              },
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: AppColors.textSecondaryC(context),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBg(context),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AppColors.borderC(context).withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  '⏎',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHintC(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
