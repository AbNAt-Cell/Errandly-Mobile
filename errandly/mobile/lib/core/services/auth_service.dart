import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: AppConstants.userKey, value: jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final raw = await _storage.read(key: AppConstants.userKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> saveRoles(List<String> roles) async {
    await _storage.write(key: AppConstants.roleKey, value: jsonEncode(roles));
  }

  static Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: AppConstants.roleKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  static Future<bool> isRunner() async {
    final roles = await getRoles();
    return roles.contains('runner');
  }

  static Future<bool> isCustomer() async {
    final roles = await getRoles();
    return roles.contains('customer');
  }

  static Future<bool> isAdmin() async {
    final roles = await getRoles();
    return roles.any((r) => ['admin', 'super_admin', 'verification_officer'].contains(r));
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await _storage.delete(key: AppConstants.userKey);
    await _storage.delete(key: AppConstants.roleKey);
  }
}
