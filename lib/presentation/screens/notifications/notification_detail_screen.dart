import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationDetailScreen extends ConsumerStatefulWidget {
  final String notificationId;
  final NotificationModel? notification;

  const NotificationDetailScreen({
    super.key,
    required this.notificationId,
    this.notification,
  });

  @override
  ConsumerState<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends ConsumerState<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read when viewing
    if (widget.notification != null && !widget.notification!.isRead) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notificationActionsProvider.notifier)
            .markAsRead(widget.notificationId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final notification = widget.notification;

    if (notification == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('Notification not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            _buildHeader(context),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      // Type Badge
                      _buildTypeBadge(notification.type),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Date & Time
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Message Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
                            _buildNotificationIcon(notification.type),
                            const SizedBox(height: 20),

                            // Message
                            Text(
                              notification.body,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textPrimary,
                                height: 1.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Action Button (if applicable)
                      if (_hasAction(notification.type))
                        _buildActionButton(notification),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF5F7FA),
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
      title: const Text(
        'Notification',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData icon;
    Color bgColor;
    Color iconColor;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        icon = Icons.notifications_active_rounded;
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFF59E0B);
        break;
      case NotificationType.paymentSuccess:
        icon = Icons.check_circle_rounded;
        bgColor = const Color(0xFFD1FAE5);
        iconColor = const Color(0xFF10B981);
        break;
      case NotificationType.paymentFailed:
        icon = Icons.error_rounded;
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFEF4444);
        break;
      case NotificationType.alert:
        icon = Icons.warning_rounded;
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFEF4444);
        break;
      case NotificationType.announcement:
        icon = Icons.campaign_rounded;
        bgColor = const Color(0xFFDBEAFE);
        iconColor = const Color(0xFF3B82F6);
        break;
      default:
        icon = Icons.notifications_rounded;
        bgColor = const Color(0xFFF3F4F6);
        iconColor = const Color(0xFF6B7280);
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        icon,
        size: 28,
        color: iconColor,
      ),
    );
  }

  Widget _buildTypeBadge(NotificationType type) {
    String label;
    Color bgColor;
    Color textColor;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        label = 'Fee Reminder';
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        break;
      case NotificationType.paymentSuccess:
        label = 'Payment Success';
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF047857);
        break;
      case NotificationType.paymentFailed:
        label = 'Payment Failed';
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      case NotificationType.alert:
        label = 'Alert';
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        break;
      case NotificationType.announcement:
        label = 'Announcement';
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF1D4ED8);
        break;
      default:
        label = 'Notification';
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final notificationDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (notificationDate == today) {
      dateStr = 'Today';
    } else if (notificationDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = DateFormat('d MMMM yyyy').format(dateTime);
    }

    final timeStr = DateFormat('h:mm a').format(dateTime);
    return '$dateStr at $timeStr';
  }

  bool _hasAction(NotificationType type) {
    return type == NotificationType.feeReminder ||
        type == NotificationType.dueDateApproaching ||
        type == NotificationType.paymentSuccess;
  }

  Widget _buildActionButton(NotificationModel notification) {
    String buttonText;
    IconData buttonIcon;
    VoidCallback onTap;

    switch (notification.type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        buttonText = 'Pay Now';
        buttonIcon = Icons.payment_rounded;
        onTap = () => context.go('/home');
        break;
      case NotificationType.paymentSuccess:
        buttonText = 'View Receipt';
        buttonIcon = Icons.receipt_long_rounded;
        onTap = () => context.go('/payment-history');
        break;
      default:
        return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(buttonIcon, size: 20),
            const SizedBox(width: 10),
            Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
