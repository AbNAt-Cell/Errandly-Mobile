import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/shared/presentation/screens/voice_call_screen.dart';
import 'audio_alert_service.dart';
import 'push_notification_service.dart';

/// Real-time WebSockets integration using Pusher Channels for Flutter.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  static bool get isConfigured =>
      AppConstants.pusherKey.isNotEmpty &&
      AppConstants.pusherKey != 'your_pusher_app_key';

  PusherChannelsFlutter? _pusher;
  bool _isInitialized = false;
  final Map<String, List<void Function(String event, dynamic data)>> _listeners = {};

  Future<void> initialize() async {
    if (!isConfigured || _isInitialized) return;

    try {
      _pusher = PusherChannelsFlutter.getInstance();
      await _pusher!.init(
        apiKey: AppConstants.pusherKey,
        cluster: AppConstants.pusherCluster,
        onEvent: _handleEvent,
        onError: (String message, int? code, dynamic e) {
          debugPrint('Pusher error: $message (code: $code)');
        },
        onConnectionStateChange: (String current, String previous) {
          debugPrint('Pusher state: $previous -> $current');
        },
      );
      await _pusher!.connect();
      _isInitialized = true;
    } catch (e) {
      debugPrint('RealtimeService initialization failed: $e');
    }
  }

  void _handleEvent(PusherEvent event) {
    dynamic parsedData = event.data;
    if (event.data is String) {
      try {
        parsedData = jsonDecode(event.data as String);
      } catch (_) {}
    }

    final channel = event.channelName;
    final eventName = event.eventName;

    // Dispatch sound triggers for core events
    if (eventName == 'ErrandCreated' || eventName == 'errand_offer') {
      AudioAlertService.instance.playRunnerDispatchAlarm();
    } else if (eventName == 'RunnerAssigned' || eventName == 'runner.assigned') {
      AudioAlertService.instance.playCustomerChime();
    } else if (eventName == 'CallInitiated' && parsedData is Map<String, dynamic>) {
      _handleIncomingCall(parsedData);
    }

    if (_listeners.containsKey(channel)) {
      for (final callback in List.of(_listeners[channel]!)) {
        try {
          callback(eventName, parsedData);
        } catch (e) {
          debugPrint('Pusher callback error on $channel ($e)');
        }
      }
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    try {
      final callId = data['call_id'] as String?;
      final caller = data['caller'] as Map<String, dynamic>?;
      final callerName = caller?['name']?.toString() ?? 'Errand Contact';
      final callerAvatar = caller?['avatar'] as String?;
      final errandTitle = data['errand_title']?.toString() ?? 'Active Errand';
      final errandId = data['errand_id']?.toString() ?? data['errand_public_id']?.toString() ?? '';
      final offerSdp = data['offer_sdp'] as String?;

      if (callId != null && offerSdp != null) {
        PushNotificationService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => VoiceCallScreen(
              callId: callId,
              errandId: errandId,
              errandTitle: errandTitle,
              contactName: callerName,
              contactAvatar: callerAvatar,
              isIncoming: true,
              initialOfferSdp: offerSdp,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('RealtimeService: Error handling incoming call: $e');
    }
  }

  /// Subscribe to an errand channel (e.g. `errand.123`) for live tracking and status updates.
  Future<void> subscribeErrand({
    required String errandId,
    required void Function(String event, dynamic data) onEvent,
  }) async {
    await subscribeChannel(channelName: 'errand.$errandId', onEvent: onEvent);
  }

  /// Unsubscribe from an errand channel.
  Future<void> unsubscribeErrand({
    required String errandId,
    required void Function(String event, dynamic data) onEvent,
  }) async {
    await unsubscribeChannel(channelName: 'errand.$errandId', onEvent: onEvent);
  }

  /// Subscribe to runner available errands broadcast feed (`errands.available`).
  Future<void> subscribeAvailableErrands({
    required void Function(String event, dynamic data) onEvent,
  }) async {
    await subscribeChannel(channelName: 'errands.available', onEvent: onEvent);
  }

  /// Unsubscribe from runner available errands feed.
  Future<void> unsubscribeAvailableErrands({
    required void Function(String event, dynamic data) onEvent,
  }) async {
    await unsubscribeChannel(channelName: 'errands.available', onEvent: onEvent);
  }

  Future<void> subscribeChannel({
    required String channelName,
    required void Function(String event, dynamic data) onEvent,
  }) async {
    if (!isConfigured) return;
    if (!_isInitialized) {
      await initialize();
    }

    _listeners.putIfAbsent(channelName, () => []).add(onEvent);

    try {
      await _pusher?.subscribe(channelName: channelName);
    } catch (e) {
      debugPrint('Failed to subscribe to $channelName: $e');
    }
  }

  Future<void> unsubscribeChannel({
    required String channelName,
    required void Function(String event, dynamic data) onEvent,
  }) async {
    if (_listeners.containsKey(channelName)) {
      _listeners[channelName]?.remove(onEvent);
      if (_listeners[channelName]?.isEmpty ?? true) {
        _listeners.remove(channelName);
        try {
          await _pusher?.unsubscribe(channelName: channelName);
        } catch (_) {}
      }
    }
  }
}
