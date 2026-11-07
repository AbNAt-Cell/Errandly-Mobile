import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../../../../main.dart';

class AuthConfigService {
  AuthConfigService._();

  static bool passwordEnabled = true;
  static bool phoneOtpEnabled = false;
  static bool googleEnabled = true;
  static bool isLoaded = false;

  static final ValueNotifier<bool> configNotifier = ValueNotifier<bool>(false);

  static Future<void> fetchAuthConfig({bool force = false}) async {
    if (isLoaded && !force) return;

    try {
      final api = getIt<ApiClient>();
      final res = await api.dio.get('/config');
      final data = res.data;
      final authMethods = data is Map ? (data['auth_methods'] ?? (data['data'] != null ? data['data']['auth_methods'] : null)) : null;

      if (authMethods != null && authMethods is Map) {
        passwordEnabled = authMethods['password'] == true;
        phoneOtpEnabled = authMethods['phone_otp'] == true;
        googleEnabled = authMethods['google'] == true;
        isLoaded = true;
        configNotifier.value = !configNotifier.value;
      }
    } catch (e) {
      debugPrint('[AuthConfigService] Error fetching auth config: $e');
    }
  }
}

