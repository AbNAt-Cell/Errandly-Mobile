import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

/// Tracks in-app notification unread count for badges.
class NotificationInboxService {
  NotificationInboxService._();

  static final ValueNotifier<int> unreadCount = ValueNotifier(0);

  static Future<void> refresh(ApiClient api) async {
    try {
      final res = await api.getNotifications();
      unreadCount.value = (res.data['unread_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Keep last known count on network errors.
    }
  }

  static void decrement() {
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }
  }

  static void clear() {
    unreadCount.value = 0;
  }
}
