import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

final _currencyFmt = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String _dateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Converts a payment record into a NotificationModel.
/// Read status comes from [notification_read] column in the payment table.
NotificationModel _paymentToNotification(Map<String, dynamic> payment) {
  final payId = payment['pay_id'].toString();
  final notificationId = 'pay_$payId';
  final amount = (payment['transtotalamount'] as num?)?.toDouble() ?? 0;
  final status = payment['paystatus'] as String?;
  final paydate = payment['paydate'] != null
      ? DateTime.parse(payment['paydate'])
      : DateTime.parse(payment['createdat']);
  final paynumber = payment['paynumber'] ?? 'PAY${payId.padLeft(6, '0')}';
  final isRead = payment['notification_read'] as bool? ?? false;
  final formattedAmount = _currencyFmt.format(amount);

  String title;
  String message;
  NotificationType type;

  switch (status) {
    case 'C':
      title = 'Payment Successful';
      message =
          'Your payment of $formattedAmount ($paynumber) was completed successfully.';
      type = NotificationType.paymentSuccess;
      break;
    case 'F':
      title = 'Payment Failed';
      message =
          'Your payment of $formattedAmount ($paynumber) has failed. Please try again.';
      type = NotificationType.paymentFailed;
      break;
    case 'R':
      title = 'Payment Refunded';
      message =
          'Your payment of $formattedAmount ($paynumber) has been refunded.';
      type = NotificationType.alert;
      break;
    default:
      title = 'Payment Initiated';
      message =
          'Your payment of $formattedAmount ($paynumber) has been initiated.';
      type = NotificationType.general;
      break;
  }

  return NotificationModel(
    id: notificationId,
    schoolId: payment['ins_id']?.toString() ?? '',
    parentId: '',
    studentId: payment['stu_id']?.toString(),
    title: title,
    message: message,
    type: type,
    data: {'pay_id': payment['pay_id']},
    isRead: isRead,
    createdAt: paydate,
  );
}


final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) return [];

  List<NotificationModel> notifications = [];

  // 1. Fetch payment notifications (success / failed / refunded)
  try {
    final response = await client
        .from('payment')
        .select()
        .eq('stu_id', selectedStudent.stuId)
        .eq('activestatus', 1)
        .neq('paystatus', 'I')
        .order('createdat', ascending: false)
        .limit(50);

    notifications = (response as List<dynamic>)
        .map((e) => _paymentToNotification(e as Map<String, dynamic>))
        .toList();
  } catch (_) {}

  // 2. Fetch fee reminders and group into summary cards:
  //    - One "Fee Overdue" card  for all overdue unpaid fees
  //    - One "Upcoming Fees"  card for fees due within 10 days
  //    Both repeat daily until fees are paid.
  try {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tenDaysLater = now.add(const Duration(days: 10));

    final feeResponse = await client
        .from('feedemand')
        .select()
        .eq('stu_id', selectedStudent.stuId)
        .eq('activestatus', 1)
        .neq('paidstatus', 'P')
        .not('duedate', 'is', null)
        .lte('duedate', _dateStr(tenDaysLater))
        .gt('balancedue', 0);

    final fees = feeResponse as List<dynamic>;

    // Split into overdue vs upcoming
    final overdueFees = fees.where((f) {
      final due = DateTime.parse(f['duedate']);
      return DateTime(due.year, due.month, due.day).isBefore(today);
    }).toList();

    final upcomingFees = fees.where((f) {
      final due = DateTime.parse(f['duedate']);
      return !DateTime(due.year, due.month, due.day).isBefore(today);
    }).toList();

    // Overdue summary card
    if (overdueFees.isNotEmpty) {
      final totalOverdue = overdueFees.fold(
          0.0, (sum, f) => sum + ((f['balancedue'] as num?)?.toDouble() ?? 0));
      notifications.add(NotificationModel(
        id: 'fee_overdue_summary',
        schoolId: overdueFees.first['ins_id']?.toString() ?? '',
        parentId: '',
        studentId: overdueFees.first['stu_id']?.toString(),
        title: 'Fee Overdue',
        message:
            'Outstanding balance of ${_currencyFmt.format(totalOverdue)}. Please pay immediately.',
        type: NotificationType.feeReminder,
        data: {'dem_ids': overdueFees.map((f) => f['dem_id']).toList()},
        isRead: false,
        createdAt: DateTime.now(),
      ));
    }

    // Upcoming summary card
    if (upcomingFees.isNotEmpty) {
      final totalUpcoming = upcomingFees.fold(
          0.0, (sum, f) => sum + ((f['balancedue'] as num?)?.toDouble() ?? 0));
      // Find the nearest due date for the message
      final nearestDue = upcomingFees
          .map((f) => DateTime.parse(f['duedate']))
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final daysLeft = DateTime(nearestDue.year, nearestDue.month, nearestDue.day)
          .difference(today)
          .inDays;
      final daysText = daysLeft == 0
          ? 'today'
          : daysLeft == 1
              ? 'tomorrow'
              : 'in $daysLeft days';
      notifications.add(NotificationModel(
        id: 'fee_upcoming_summary',
        schoolId: upcomingFees.first['ins_id']?.toString() ?? '',
        parentId: '',
        studentId: upcomingFees.first['stu_id']?.toString(),
        title: 'Upcoming Fee Due',
        message:
            'Total of ${_currencyFmt.format(totalUpcoming)} due $daysText. Please pay within the due date.',
        type: NotificationType.dueDateApproaching,
        data: {'dem_ids': upcomingFees.map((f) => f['dem_id']).toList()},
        isRead: false,
        // 1 second behind overdue so overdue always sorts first
        createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ));
    }
  } catch (_) {}

  // Sort all by date descending — fee reminders appear under "Today", payments under their actual dates
  notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return notifications;
});

/// Unread notification count for badge display.
/// Fee reminders always count as unread until paid.
final notificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.data(null));

  /// Marks a payment notification as read.
  /// Fee notifications ([fee_xxx]) are intentionally skipped — they remain
  /// as daily reminders until the fee is paid.
  Future<void> markAsRead(String notificationId) async {
    if (!notificationId.startsWith('pay_')) return;
    final payId = int.tryParse(notificationId.replaceFirst('pay_', ''));
    if (payId == null) return;

    try {
      final client = _ref.read(supabaseClientProvider);
      await client
          .from('payment')
          .update({'notification_read': true}).eq('pay_id', payId);
      _ref.invalidate(notificationsProvider);
    } catch (_) {}
    state = const AsyncValue.data(null);
  }

  /// Marks all payment notifications as read.
  /// Fee reminders are skipped — they stay unread until the fee is paid.
  Future<void> markAllAsRead() async {
    final notifications = _ref.read(notificationsProvider).valueOrNull ?? [];

    final unreadPayIds = notifications
        .where((n) => !n.isRead && n.id.startsWith('pay_'))
        .map((n) => int.tryParse(n.id.replaceFirst('pay_', '')))
        .whereType<int>()
        .toList();

    if (unreadPayIds.isEmpty) return;

    try {
      final client = _ref.read(supabaseClientProvider);
      await client
          .from('payment')
          .update({'notification_read': true}).inFilter('pay_id', unreadPayIds);
      _ref.invalidate(notificationsProvider);
    } catch (_) {}
    state = const AsyncValue.data(null);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref);
});
