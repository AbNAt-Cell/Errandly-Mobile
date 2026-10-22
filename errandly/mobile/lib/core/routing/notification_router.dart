import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/realtime_service.dart';
import '../../features/shared/presentation/screens/notifications_screen.dart';
import '../../features/shared/presentation/screens/voice_call_screen.dart';
import '../../features/customer/presentation/screens/errand_detail_screen.dart';
import '../../features/customer/presentation/screens/customer_kyc_screen.dart';
import '../../features/runner/presentation/screens/runner_errand_detail_screen.dart';
import '../../features/runner/presentation/screens/runner_kyc_screen.dart';
import '../../features/runner/presentation/screens/runner_main_screen.dart';

/// Routes the user when they open a push notification.
class NotificationRouter {
  static Future<void> openFromPayload(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final type = data['type']?.toString() ?? '';
    final publicId = data['public_id']?.toString();

    if (type == 'incoming_call') {
      final callId = data['call_id']?.toString();
      final errandId = data['errand_id']?.toString() ?? '';
      final errandTitle = data['errand_title']?.toString() ?? 'Active Errand';
      final callerName = data['caller_name']?.toString() ?? 'Errand Contact';
      final offerSdp = data['offer_sdp']?.toString();

      if (callId != null && !RealtimeService.isCallScreenActive) {
        RealtimeService.isCallScreenActive = true;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              callId: callId,
              errandId: errandId,
              errandTitle: errandTitle,
              contactName: callerName,
              isIncoming: true,
              initialOfferSdp: offerSdp,
            ),
          ),
        );
        return;
      }
    }

    if (publicId != null && publicId.isNotEmpty && _isErrandType(type)) {
      final isRunner = await AuthService.isRunner();
      if (!context.mounted) return;

      if (isRunner) {
        if (type == 'errand_offer') {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RunnerMainScreen()),
          );
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RunnerErrandDetailScreen(errandPublicId: publicId),
          ),
        );
      } else {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ErrandDetailScreen(errandPublicId: publicId),
          ),
        );
      }
      return;
    }

    if (type == 'kyc_approved' || type == 'kyc_rejected') {
      final isRunner = await AuthService.isRunner();
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => isRunner ? const RunnerKycScreen() : const CustomerKycScreen(),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  static bool _isErrandType(String type) {
    const errandTypes = {
      'errand_offer',
      'errand_assigned',
      'runner_arrived',
      'task_started',
      'task_completed',
      'payment_released',
      'panic_alert',
      'dispute_opened',
      'dispute_resolved',
      'test',
    };
    return errandTypes.contains(type);
  }
}
