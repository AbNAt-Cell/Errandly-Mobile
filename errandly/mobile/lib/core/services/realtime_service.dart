import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/shared/presentation/screens/voice_call_screen.dart';
import 'audio_alert_service.dart';
import 'auth_service.dart';
import 'push_notification_service.dart';

/// Real-time WebSockets integration using Pusher Channels for Flutter.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  static bool isCallScreenActive = false;
  void Function(String eventName, Map<String, dynamic> data)? onActiveCallEvent;

  static bool get isConfigured =>
      AppConstants.pusherKey.isNotEmpty &&
      AppConstants.pusherKey != 'your_pusher_app_key';

  PusherChannelsFlutter? _pusher;
  bool _isInitialized = false;
  String? _currentSubscribedUserId;
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

      // Automatically subscribe to the logged-in user's personal channel
      await syncUserChannel();
    } catch (e) {
      debugPrint('RealtimeService initialization failed: $e');
    }
  }

  /// Subscribe to the logged-in user's personal channel (`user.$userId`)
  /// to receive incoming calls, dispatch alarms, and account updates.
  Future<void> syncUserChannel({String? userId}) async {
    if (!isConfigured) return;
    if (!_isInitialized) {
      await initialize();
    }

    String? targetId = userId;
    if (targetId == null) {
      final user = await AuthService.getUser();
      if (user != null && user['id'] != null) {
        targetId = user['id'].toString();
      }
    }

    if (targetId == null || targetId.isEmpty) return;

    if (_currentSubscribedUserId == targetId) return;

    if (_currentSubscribedUserId != null) {
      await unsubscribeChannel(
        channelName: 'user.$_currentSubscribedUserId',
        onEvent: _userChannelListener,
      );
      _currentSubscribedUserId = null;
    }

    _currentSubscribedUserId = targetId;
    debugPrint('RealtimeService: Subscribing to personal user channel: user.$targetId');
    await subscribeChannel(
      channelName: 'user.$targetId',
      onEvent: _userChannelListener,
    );
  }

  void _userChannelListener(String event, dynamic data) {
    debugPrint('RealtimeService: Event on user channel: $event');
  }

  Future<void> unsubscribeUser() async {
    if (_currentSubscribedUserId != null) {
      await unsubscribeChannel(
        channelName: 'user.$_currentSubscribedUserId',
        onEvent: _userChannelListener,
      );
      _currentSubscribedUserId = null;
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
    debugPrint('RealtimeService: Pusher event "$eventName" on "$channel"');

    final isCallInitiated = eventName == 'CallInitiated' ||
        eventName == '.CallInitiated' ||
        eventName.endsWith('CallInitiated') ||
        eventName == 'call.initiated';

    final isCallSignalEvent = eventName == 'CallAnswered' ||
        eventName.endsWith('CallAnswered') ||
        eventName == 'CallSignal' ||
        eventName.endsWith('CallSignal') ||
        eventName == 'CallEnded' ||
        eventName.endsWith('CallEnded') ||
        eventName == 'CallRejected' ||
        eventName.endsWith('CallRejected');

    // Dispatch sound triggers for core events
    if (eventName == 'ErrandCreated' || eventName == 'errand_offer') {
      AudioAlertService.instance.playRunnerDispatchAlarm();
    } else if (eventName == 'RunnerAssigned' || eventName == 'runner.assigned') {
      AudioAlertService.instance.playCustomerChime();
    } else if (isCallInitiated && parsedData != null) {
      if (parsedData is Map) {
        _handleIncomingCall(Map<String, dynamic>.from(parsedData));
      }
    } else if (isCallSignalEvent && parsedData != null && onActiveCallEvent != null) {
      if (parsedData is Map) {
        try {
          onActiveCallEvent!(eventName, Map<String, dynamic>.from(parsedData));
        } catch (e) {
          debugPrint('RealtimeService: onActiveCallEvent error: $e');
        }
      }
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

  void _handleIncomingCall(Map<String, dynamic> raw) {
    try {
      if (isCallScreenActive) {
        debugPrint('RealtimeService: Call screen active, ignoring duplicate CallInitiated');
        return;
      }

      final data = (raw['call'] is Map)
          ? Map<String, dynamic>.from(raw['call'] as Map)
          : raw;

      final callId = (data['call_id'] ?? data['id'] ?? data['public_id'])?.toString();
      final caller = (data['caller'] is Map)
          ? Map<String, dynamic>.from(data['caller'] as Map)
          : null;
      final callerName = caller?['name']?.toString() ??
          '${caller?['first_name'] ?? ''} ${caller?['last_name'] ?? ''}'.trim();
      final finalCallerName = callerName.isNotEmpty ? callerName : 'Errand Contact';
      final callerAvatar = caller?['avatar']?.toString() ?? caller?['avatar_url']?.toString();
      final errandTitle = data['errand_title']?.toString() ?? 'Active Errand';
      final errandId = (data['errand_public_id'] ?? data['errand_id'])?.toString() ?? '';
      final offerSdp = (data['offer_sdp'] ?? data['sdp'])?.toString();

      debugPrint('RealtimeService: Received incoming call $callId from $finalCallerName for errand $errandTitle');

      if (callId != null && offerSdp != null && offerSdp.isNotEmpty) {
        isCallScreenActive = true;

        void navigateToCallScreen() {
          final nav = PushNotificationService.navigatorKey.currentState;
          if (nav != null) {
            nav.push(
              MaterialPageRoute(
                builder: (_) => VoiceCallScreen(
                  callId: callId,
                  errandId: errandId,
                  errandTitle: errandTitle,
                  contactName: finalCallerName,
                  contactAvatar: callerAvatar,
                  isIncoming: true,
                  initialOfferSdp: offerSdp,
                ),
              ),
            );
          } else {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              PushNotificationService.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (_) => VoiceCallScreen(
                    callId: callId,
                    errandId: errandId,
                    errandTitle: errandTitle,
                    contactName: finalCallerName,
                    contactAvatar: callerAvatar,
                    isIncoming: true,
                    initialOfferSdp: offerSdp,
                  ),
                ),
              );
            });
          }
        }

        navigateToCallScreen();
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
