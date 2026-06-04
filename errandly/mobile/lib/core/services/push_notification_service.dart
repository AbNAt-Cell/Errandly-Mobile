import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../routing/notification_router.dart';
import 'device_id_service.dart';
import 'notification_inbox_service.dart';
import 'auth_service.dart';
import 'fcm_background_handler.dart';

/// Firebase Cloud Messaging + local notifications (foreground).
class PushNotificationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static ApiClient? _api;
  static bool _initialized = false;
  static Map<String, dynamic>? _pendingPayload;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'errandly_high',
    'Errandly',
    description: 'Errand updates, offers, and alerts',
    importance: Importance.high,
  );

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Call once from [main] before [runApp].
  static Future<void> initialize(ApiClient apiClient) async {
    if (_initialized) return;
    _api = apiClient;

    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _setupLocalNotifications();
      await _requestPermission();

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) => _syncToken(token));

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _pendingPayload = Map<String, dynamic>.from(initial.data);
      }

      _initialized = true;
    } catch (e, st) {
      debugPrint('PushNotificationService: Firebase not configured ($e)');
      debugPrint('$st');
    }
  }

  /// Register FCM token with API (after login or on app resume when logged in).
  static Future<void> registerDeviceTokenIfPossible() async {
    if (_api == null || !(await AuthService.isLoggedIn())) return;

    try {
      if (!_initialized) {
        await initialize(_api!);
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;

      await _syncToken(token);
    } catch (e) {
      debugPrint('PushNotificationService: token registration skipped ($e)');
    }
  }

  /// Call when [MaterialApp] is ready (e.g. after first frame).
  static Future<void> handlePendingNotification() async {
    final pending = _pendingPayload;
    if (pending == null) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    _pendingPayload = null;
    await NotificationRouter.openFromPayload(context, _parseData(pending));
  }

  static Future<String?> getToken() async {
    try {
      if (!_initialized) return null;
      return FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  static String get deviceType => Platform.isIOS ? 'ios' : 'android';

  static Future<Map<String, String>> deviceTokenFields() async {
    final token = await getToken();
    final deviceId = await DeviceIdService.getOrCreate();
    return {
      if (token != null && token.isNotEmpty) 'device_token': token,
      'device_id': deviceId,
      'device_type': deviceType,
    };
  }

  static Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handlePayloadString(response.payload!);
        }
      },
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
  }

  static Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (Platform.isIOS) {
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
    }
  }

  static Future<void> _syncToken(String token) async {
    if (_api == null) return;
    try {
      final deviceId = await DeviceIdService.getOrCreate();
      await _api!.updateDeviceToken({
        'device_token': token,
        'device_id': deviceId,
        'device_type': deviceType,
      });
    } catch (e) {
      debugPrint('PushNotificationService: failed to sync token ($e)');
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    if (_api != null) {
      NotificationInboxService.refresh(_api!);
    }

    final notification = message.notification;
    final title = notification?.title ?? 'Errandly';
    final body = notification?.body ?? '';
    final payload = _encodePayload(message.data);

    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static void _onMessageOpened(RemoteMessage message) {
    _handlePayloadMap(message.data);
  }

  static void _handlePayloadString(String payload) {
    try {
      final data = _parseData(Map<String, dynamic>.from(_decodePending(payload)));
      _handlePayloadMap(data);
    } catch (_) {}
  }

  static void _handlePayloadMap(Map<String, dynamic> data) {
    final parsed = _parseData(data);
    final context = navigatorKey.currentContext;
    if (context == null) {
      _pendingPayload = parsed;
      return;
    }
    NotificationRouter.openFromPayload(context, parsed);
  }

  static Map<String, dynamic> _parseData(Map<String, dynamic> raw) {
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  static String _encodePayload(Map<String, dynamic> data) => jsonEncode(data);

  static Map<String, dynamic> _decodePending(String payload) =>
      Map<String, dynamic>.from(jsonDecode(payload) as Map);
}
