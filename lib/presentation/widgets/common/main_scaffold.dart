import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/drawer_provider.dart';
import 'app_drawer.dart';

class MainScaffold extends ConsumerWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith(Routes.home)) return 0;
    if (location.startsWith(Routes.paymentHistory)) return 1;
    if (location.startsWith(Routes.notifications)) return 2;
    if (location.startsWith(Routes.profile)) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final scaffoldKey = ref.watch(mainScaffoldKeyProvider);

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      drawerEnableOpenDragGesture: true,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  selectedIndex: selectedIndex,
                  label: 'Home',
                  strokeIcon: 'assets/nav bar icons/home stroke.svg',
                  filledIcon: 'assets/nav bar icons/home filled.svg',
                  route: Routes.home,
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  selectedIndex: selectedIndex,
                  label: 'History',
                  strokeIcon: 'assets/nav bar icons/history stroke.svg',
                  filledIcon: 'assets/nav bar icons/history filled.svg',
                  route: Routes.paymentHistory,
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  selectedIndex: selectedIndex,
                  label: 'Alerts',
                  strokeIcon: 'assets/nav bar icons/alerts stroke.svg',
                  filledIcon: 'assets/nav bar icons/alerts filled.svg',
                  route: Routes.notifications,
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  selectedIndex: selectedIndex,
                  label: 'Profile',
                  strokeIcon: 'assets/nav bar icons/profile stroke.svg',
                  filledIcon: 'assets/nav bar icons/profile filled.svg',
                  route: Routes.profile,
                ),
              ],
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
    required String strokeIcon,
    required String filledIcon,
    required String route,
  }) {
    final isSelected = index == selectedIndex;
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return GestureDetector(
      onTap: () => context.go(route),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isSelected ? filledIcon : strokeIcon,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
