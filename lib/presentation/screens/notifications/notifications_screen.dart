import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/cart_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final readIdsLoaded = ref.watch(readNotificationsProvider) != null;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Column(
        children: [
            // Fixed Header with white SafeArea and subtle shadow
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
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: !readIdsLoaded
                ? const Center(child: CircularProgressIndicator())
                : notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return _buildEmptyState();
                  }
                  final groupedNotifications = _groupNotificationsByDate(notifications);
                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                    itemCount: groupedNotifications.length,
                    itemBuilder: (context, index) {
                      final group = groupedNotifications[index];
                      return _buildNotificationGroup(group);
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  List<_NotificationGroup> _groupNotificationsByDate(List<NotificationModel> notifications) {
    final Map<String, List<NotificationModel>> grouped = {};
    for (final notification in notifications) {
      final dateKey = _getDateGroup(notification.createdAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(notification);
    }
    return grouped.entries
        .map((e) => _NotificationGroup(date: e.key, notifications: e.value))
        .toList();
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
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
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryC(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stay updated with alerts',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondaryC(context),
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
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.iconButtonBg(context), width: 2),
                        ),
                        child: Text(
                          cartItemCount > 9 ? '9+' : '$cartItemCount',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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

  Widget _buildNotificationGroup(_NotificationGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            group.date,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimaryC(context),
            ),
          ),
        ),
        ...group.notifications.map((notification) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildNotificationCard(notification),
        )),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final readIds = ref.watch(readNotificationsProvider) ?? {};
    final isUnread = !readIds.contains(notification.id);

    return GestureDetector(
      onTap: () async {
        if (isUnread) {
          ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);
        }
        await context.push('/notifications/${notification.id}', extra: notification);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? []
              : [
                  BoxShadow(
                    color: isUnread ? AppColors.shadowPurple : AppColors.shadowLight,
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationIcon(notification.type, isUnread),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.w500,
                            color: AppColors.textPrimaryC(context),
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondaryC(context),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimestamp(notification.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.textHintC(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(NotificationType type, bool isUnread) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        icon = Icons.notifications_active_rounded;
        bgColor = AppColors.cardOrange;
        iconColor = AppColors.cardOrangeDark;
        break;
      case NotificationType.paymentSuccess:
        icon = Icons.check_circle_rounded;
        bgColor = AppColors.cardGreen;
        iconColor = AppColors.cardGreenDark;
        break;
      case NotificationType.paymentFailed:
      case NotificationType.alert:
        icon = Icons.warning_rounded;
        bgColor = AppColors.cardRose;
        iconColor = AppColors.cardRoseDark;
        break;
      case NotificationType.newFeeAdded:
        icon = Icons.add_circle_rounded;
        bgColor = AppColors.cardPurple;
        iconColor = AppColors.cardPurpleDark;
        break;
      case NotificationType.announcement:
        icon = Icons.campaign_rounded;
        bgColor = AppColors.cardBlue;
        iconColor = AppColors.cardBlueDark;
        break;
      case NotificationType.general:
        icon = Icons.info_rounded;
        bgColor = AppColors.cardCyan;
        iconColor = AppColors.cardCyanDark;
        break;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24, color: iconColor),
    );
  }

  String _getTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return _formatDate(date);
    }
  }

  Widget _buildEmptyState() {
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
                color: AppColors.cardPurple,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 48,
                color: AppColors.cardPurpleDark,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryC(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! Check back later for updates.',
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

class _NotificationGroup {
  final String date;
  final List<NotificationModel> notifications;

  _NotificationGroup({required this.date, required this.notifications});
}
