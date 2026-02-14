import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/notification_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Tracks which notification IDs have been read (persisted locally per student)
/// State is null while loading from SharedPreferences, then Set<String> when loaded
class ReadNotificationsNotifier extends StateNotifier<Set<String>?> {
  final int? _studentId;

  ReadNotificationsNotifier(this._studentId) : super(null) {
    _load();
  }

  String get _storageKey => 'read_notification_ids_${_studentId ?? 'none'}';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_storageKey) ?? [];
    state = ids.toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, (state ?? {}).toList());
  }

  Future<void> markAsRead(String id) async {
    state = {...(state ?? {}), id};
    await _save();
  }

  Future<void> markAllAsRead(List<String> ids) async {
    state = {...(state ?? {}), ...ids};
    await _save();
  }
}

final readNotificationsProvider =
    StateNotifierProvider<ReadNotificationsNotifier, Set<String>?>((ref) {
  final selectedStudent = ref.watch(selectedStudentProvider);
  return ReadNotificationsNotifier(selectedStudent?.stuId);
});

/// Converts a payment record from Supabase into a NotificationModel
NotificationModel _paymentToNotification(
    Map<String, dynamic> payment, Set<String> readIds) {
  final payId = payment['pay_id'].toString();
  final notificationId = 'pay_$payId';
  final amount = (payment['transtotalamount'] as num?)?.toDouble() ?? 0;
  final status = payment['paystatus'] as String?;
  final paydate = payment['paydate'] != null
      ? DateTime.parse(payment['paydate'])
      : DateTime.parse(payment['createdat']);
  final paynumber = payment['paynumber'] ?? 'PAY${payId.padLeft(6, '0')}';
  final formattedAmount = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  ).format(amount);

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
    isRead: readIds.contains(notificationId),
    createdAt: paydate,
  );
}

final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  List<NotificationModel> notifications = [];
  final readIds = ref.watch(readNotificationsProvider) ?? {};


  try {
    final client = ref.watch(supabaseClientProvider);
    final selectedStudent = ref.watch(selectedStudentProvider);

    if (selectedStudent != null) {
      // Fetch completed/failed payments for the selected student (exclude initiated 'I')
      final response = await client
          .from('payment')
          .select()
          .eq('stu_id', selectedStudent.stuId)
          .eq('activestatus', 1)
          .neq('paystatus', 'I')
          .order('createdat', ascending: false)
          .limit(50);

      notifications = (response as List<dynamic>)
          .map((e) =>
              _paymentToNotification(e as Map<String, dynamic>, readIds))
          .toList();
    }
  } catch (_) {
    // payment table query failed - return empty
  }

  return notifications;
});

/// Unread notification count for badge display
final notificationCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final readIds = ref.watch(readNotificationsProvider) ?? {};
  return notificationsAsync.maybeWhen(
    data: (notifications) =>
        notifications.where((n) => !readIds.contains(n.id)).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    await _ref
        .read(readNotificationsProvider.notifier)
        .markAsRead(notificationId);
    state = const AsyncValue.data(null);
  }

  Future<void> markAllAsRead() async {
    final notifications = _ref.read(notificationsProvider).valueOrNull ?? [];
    final allIds = notifications.map((n) => n.id).toList();
    await _ref
        .read(readNotificationsProvider.notifier)
        .markAllAsRead(allIds);
    state = const AsyncValue.data(null);
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(ref);
});
