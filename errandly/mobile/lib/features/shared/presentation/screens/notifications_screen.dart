import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/network/api_client.dart';
import '../../../../core/routing/notification_router.dart';
import '../../../../core/services/notification_inbox_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../main.dart';

/// In-app notification inbox (customer and runner).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api = getIt<ApiClient>();
      final res = await api.getNotifications();
      final data = res.data;
      if (mounted) {
        setState(() {
          _items = data['notifications']?['data'] ?? [];
          _loading = false;
        });
      }
      NotificationInboxService.unreadCount.value =
          (data['unread_count'] as num?)?.toInt() ?? 0;
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await getIt<ApiClient>().markAllRead();
    NotificationInboxService.clear();
    await _load();
  }

  Future<void> _onTap(Map<String, dynamic> n) async {
    final id = n['id'] as int?;
    if (n['read_at'] == null && id != null) {
      await getIt<ApiClient>().markNotificationRead(id);
      NotificationInboxService.decrement();
    }

    final payload = <String, dynamic>{};
    final stored = n['data'];
    if (stored is Map) {
      payload.addAll(stored.map((k, v) => MapEntry(k.toString(), v)));
    }
    if (n['type'] != null) {
      payload['type'] = n['type'].toString();
    }

    if (!mounted) return;
    await NotificationRouter.openFromPayload(context, payload);
    await _load();
  }

  IconData _iconForType(String? type) {
    return switch (type) {
      'errand_offer' || 'errand_assigned' => Icons.local_shipping_outlined,
      'runner_arrived' || 'task_started' => Icons.directions_run,
      'task_completed' || 'payment_released' => Icons.check_circle_outline,
      'kyc_approved' || 'kyc_rejected' => Icons.verified_user_outlined,
      'panic_alert' => Icons.warning_amber_rounded,
      'dispute_opened' || 'dispute_resolved' => Icons.gavel_outlined,
      _ => Icons.notifications_none_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: AppColors.primary)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final n = _items[i] as Map<String, dynamic>;
                      final read = n['read_at'] != null;
                      final created = n['created_at']?.toString() ?? '';
                      final type = n['type']?.toString();

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: read ? AppColors.surface : AppColors.primaryFaded,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: read ? AppColors.background : AppColors.primary.withOpacity(0.15),
                            child: Icon(_iconForType(type), color: AppColors.primary, size: 22),
                          ),
                          title: Text(
                            n['title']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(n['body']?.toString() ?? ''),
                          trailing: Text(
                            created.isNotEmpty
                                ? timeago.format(DateTime.parse(created), locale: 'en_short')
                                : '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          onTap: () => _onTap(n),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
