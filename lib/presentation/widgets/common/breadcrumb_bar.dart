import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';

/// A breadcrumb navigation bar with a back button and path segments.
///
/// Shows: [←] Parent / Current Page
///
/// Used as the `toolbar` parameter in [DesktopDetailScaffold] so it
/// renders **outside** the body card on both desktop and mobile.
class BreadcrumbBar extends StatelessWidget {
  /// Label of the parent page (e.g. "Dashboard", "Payment History").
  final String parentLabel;

  /// Route to navigate when tapping the parent label.
  /// Defaults to [Routes.home].
  final String? parentRoute;

  /// Current page title shown as the last breadcrumb segment.
  final String currentLabel;

  const BreadcrumbBar({
    super.key,
    this.parentLabel = 'Dashboard',
    this.parentRoute,
    required this.currentLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => _goBack(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.textLink.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: AppColors.textLink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Parent label (tappable)
          GestureDetector(
            onTap: () => context.go(parentRoute ?? Routes.home),
            child: Text(
              parentLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textLink,
              ),
            ),
          ),
          Text(
            '  /  ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: AppColors.textHintC(context),
            ),
          ),
          // Current page label
          Flexible(
            child: Text(
              currentLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _goBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(parentRoute ?? Routes.home);
    }
  }
}
