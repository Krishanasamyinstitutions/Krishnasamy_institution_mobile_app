import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/student_avatar.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  // Mock data for preview (remove when real data is available)
  List<NotificationModel> get _mockNotifications => [
    NotificationModel(
      id: '1',
      schoolId: 'school-1',
      parentId: 'parent-1',
      title: 'Upcoming Fee Due',
      message: 'Term 2 tuition fee of ₹12,000 is due by 20 July 2025. Avoid late charges by paying on time.',
      type: NotificationType.feeReminder,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: '2',
      schoolId: 'school-1',
      parentId: 'parent-1',
      title: 'Payment Successful',
      message: 'Your payment of ₹4,500 for Term 1 was received on 10 July 2025. Receipt is now available to download.',
      type: NotificationType.paymentSuccess,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    ),
    NotificationModel(
      id: '3',
      schoolId: 'school-1',
      parentId: 'parent-1',
      title: 'Late Fee Applied',
      message: 'A late fee of ₹200 has been added to your Transport Fee for Term 1. Please clear dues to avoid further penalties.',
      type: NotificationType.alert,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: '4',
      schoolId: 'school-1',
      parentId: 'parent-1',
      title: 'Parent-Teacher Meeting',
      message: 'PTM for Class 6 will be held on 25 July 2025 at 10:00 AM in the school auditorium. Attendance is encouraged.',
      type: NotificationType.announcement,
      isRead: false,
      createdAt: DateTime(2025, 7, 7, 18, 0),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

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
            // Notification List
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (notifications) {
                  // Use mock data if no real notifications exist
                  final displayNotifications = notifications.isEmpty ? _mockNotifications : notifications;

                  if (displayNotifications.isEmpty) {
                    return _buildEmptyState();
                  }

                  // Group notifications by date
                  final groupedNotifications = _groupNotificationsByDate(displayNotifications);

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
    final selectedStudent = ref.watch(selectedStudentProvider);
    final studentName = selectedStudent?.name ?? 'Student';
    final admNo = selectedStudent?.admissionNumber ?? 'N/A';
    final className = selectedStudent?.className ?? 'N/A';
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Profile Image
          StudentAvatar.medium(studentName: studentName),
          const SizedBox(width: 12),
          // Student Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2933),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Admn No: $admNo  |  Class: $className',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Cart Icon
          GestureDetector(
            onTap: () => context.push(Routes.cart),
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
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.shopping_cart_outlined,
                    size: 24,
                    color: Color(0xFF1F2933),
                  ),
                  if (cartItemCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Text(
                          cartItemCount > 9 ? '9+' : '$cartItemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
          const SizedBox(width: 8),
          // Notification Icon
          Container(
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
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
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
        // Date Header
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            group.date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: AppSizes.fontSemibold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        // Notification Cards
        ...group.notifications.map((notification) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildNotificationCard(notification),
        )),
      ],
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return GestureDetector(
      onTap: () {
        if (!notification.isRead) {
          ref.read(notificationActionsProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.isRead ? const Color(0xFFFAFAFA) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: notification.isRead
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: _buildNotificationIcon(notification.type, notification.isRead),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: AppSizes.fontNormal,
                      color: notification.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                      height: 1.47,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Description
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: AppSizes.fontNormal,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Timestamp and Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTimestamp(notification.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: AppSizes.fontNormal,
                          color: AppColors.accent,
                        ),
                      ),
                      Transform.rotate(
                        angle: 3.14159, // 180 degrees
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
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

  Widget _buildNotificationIcon(NotificationType type, bool isRead) {
    IconData icon;
    Color color = isRead ? AppColors.textSecondary : AppColors.textPrimary;

    switch (type) {
      case NotificationType.feeReminder:
      case NotificationType.dueDateApproaching:
        icon = Icons.notifications_active_outlined;
        break;
      case NotificationType.paymentSuccess:
        icon = Icons.currency_rupee;
        break;
      case NotificationType.paymentFailed:
      case NotificationType.alert:
        icon = Icons.access_time;
        break;
      case NotificationType.newFeeAdded:
        icon = Icons.add_circle_outline;
        break;
      case NotificationType.announcement:
        icon = Icons.people_outline;
        break;
      case NotificationType.general:
        icon = Icons.notifications_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      child: Icon(
        icon,
        size: 24,
        color: color,
      ),
    );
  }

  String _getTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday • ${_formatTime(date)}';
    } else {
      return '${_formatDate(date)} • ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final period = date.hour >= 12 ? 'pm' : 'am';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
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
                Icons.notifications_off_rounded,
                size: 48,
                color: AppColors.gray400,
              ),
            ),
            const SizedBox(height: AppSizes.s6),
            const Text(
              'No Notifications',
              style: TextStyle(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.s2),
            const Text(
              'You\'re all caught up! Check back later for updates.',
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
}

class _NotificationGroup {
  final String date;
  final List<NotificationModel> notifications;

  _NotificationGroup({required this.date, required this.notifications});
}
