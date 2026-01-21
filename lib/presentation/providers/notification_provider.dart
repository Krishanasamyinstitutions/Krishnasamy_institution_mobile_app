import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Mock notifications state provider for development/testing
/// This persists the read state during the app session
class MockNotificationsNotifier extends StateNotifier<List<NotificationModel>> {
  MockNotificationsNotifier() : super(_initialMockNotifications);

  static List<NotificationModel> get _initialMockNotifications => [
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

  void markAsRead(String notificationId) {
    state = [
      for (final notification in state)
        if (notification.id == notificationId)
          notification.copyWith(isRead: true)
        else
          notification
    ];
  }

  void markAllAsRead() {
    state = [
      for (final notification in state)
        notification.copyWith(isRead: true)
    ];
  }
}

final mockNotificationsProvider =
    StateNotifierProvider<MockNotificationsNotifier, List<NotificationModel>>(
        (ref) => MockNotificationsNotifier());

final notificationsProvider =
    FutureProvider<List<NotificationModel>>((ref) async {
  // Use dummy data for development/testing
  if (useDummyData) {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return mock notifications from the persistent provider
    return ref.watch(mockNotificationsProvider);
  }

  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) return [];

  final response = await client
      .from('notifications')
      .select()
      .eq('parent_id', user.id)
      .order('created_at', ascending: false);

  return (response as List<dynamic>)
      .map((e) => NotificationModel.fromJson(e))
      .toList();
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final SupabaseClient _client;
  final Ref _ref;

  NotificationNotifier(this._client, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    state = const AsyncValue.loading();
    try {
      // For mock data, update the mock notifications provider
      if (useDummyData) {
        _ref.read(mockNotificationsProvider.notifier).markAsRead(notificationId);
        state = const AsyncValue.data(null);
        return;
      }

      await _client.from('notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      _ref.invalidate(notificationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAllAsRead() async {
    state = const AsyncValue.loading();
    try {
      // For mock data, update the mock notifications provider
      if (useDummyData) {
        _ref.read(mockNotificationsProvider.notifier).markAllAsRead();
        state = const AsyncValue.data(null);
        return;
      }

      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      await _client
          .from('notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('parent_id', user.id)
          .eq('is_read', false);

      _ref.invalidate(notificationsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final notificationActionsProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
  return NotificationNotifier(
    ref.watch(supabaseClientProvider),
    ref,
  );
});
