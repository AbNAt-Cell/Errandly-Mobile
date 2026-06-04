import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Stable per-install device id for multi-device FCM registration.
class DeviceIdService {
  static const _key = 'errandly_device_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final id = '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
    await prefs.setString(_key, id);
    return id;
  }
}
