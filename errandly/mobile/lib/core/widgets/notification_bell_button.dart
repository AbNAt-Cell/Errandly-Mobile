import 'package:flutter/material.dart';

import '../services/notification_inbox_service.dart';
import '../../features/shared/presentation/screens/notifications_screen.dart';
import '../theme/app_theme.dart';

/// App bar bell with unread badge → opens notifications inbox.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor = Colors.white,
    this.onOpened,
  });

  final Color iconColor;
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationInboxService.unreadCount,
      builder: (context, count, _) {
        return IconButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
            onOpened?.call();
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_outlined, color: iconColor, size: 26),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
