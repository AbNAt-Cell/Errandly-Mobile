import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _storage.delete(key: AppConstants.tokenKey);
          await _storage.delete(key: AppConstants.userKey);
        }
        return handler.next(error);
      },
    ));

    if (const bool.fromEnvironment('dart.vm.product') == false) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugLog(obj.toString()),
      ));
    }
  }

  Dio get dio => _dio;

  void debugLog(String message) {
    // ignore: avoid_print
    print('[Errandly API] $message');
  }

  static String formatErrorMessage(dynamic error) {
    if (error is DioException) {
      dynamic responseData = error.response?.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }
      if (responseData is Map) {
        if (responseData['errors'] != null) {
          final errs = responseData['errors'];
          final messages = <String>[];
          if (errs is Map) {
            errs.forEach((key, val) {
              if (val is List && val.isNotEmpty) {
                for (final item in val) {
                  final text = item?.toString().trim();
                  if (text != null && text.isNotEmpty && !messages.contains(text)) {
                    messages.add(text);
                  }
                }
              } else if (val != null) {
                final text = val.toString().trim();
                if (text.isNotEmpty && !messages.contains(text)) {
                  messages.add(text);
                }
              }
            });
          } else if (errs is List) {
            for (final item in errs) {
              final text = item?.toString().trim();
              if (text != null && text.isNotEmpty && !messages.contains(text)) {
                messages.add(text);
              }
            }
          }
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
        final msg = responseData['message']?.toString().trim();
        if (msg != null &&
            msg.isNotEmpty &&
            msg != 'The given data was invalid.' &&
            msg != 'The request contains invalid data.') {
          return msg;
        }
        final err = responseData['error']?.toString().trim();
        if (err != null && err.isNotEmpty) {
          return err;
        }
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please check your internet connection.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Network error. Please check your internet connection.';
      }
      if (error.response?.statusCode == 422) {
        return 'The request contains invalid or missing information. Please check your inputs.';
      }
      if (error.response?.statusCode == 401) {
        return 'Invalid credentials or session expired. Please sign in again.';
      }
      if (error.response?.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }
      if (error.response?.statusCode == 404) {
        return 'The requested resource was not found.';
      }
      if (error.response?.statusCode == 409) {
        return 'This action cannot be completed right now. Please refresh and try again.';
      }
      if (error.response?.statusCode != null) {
        return 'Server error (${error.response!.statusCode}). Please try again later.';
      }
      return 'Network request could not be completed. Please try again.';
    }

    final str = error?.toString().trim() ?? '';
    if (str.isEmpty) return 'An unexpected error occurred.';
    if (str.contains('DioException') ||
        str.contains('validateStatus') ||
        str.contains('status code of 422')) {
      return 'Please check your input details and try again.';
    }
    if (str.contains('SocketException') || str.contains('Failed host lookup')) {
      return 'Network error. Please check your internet connection.';
    }
    if (str.contains('firebase_messaging') ||
        str.contains('SERVICE_NOT_AVAILABLE') ||
        str.contains('ExecutionException')) {
      return 'Notification service is temporarily unavailable. Please try again.';
    }
    if (str.startsWith('Exception: ')) {
      return str.substring(11).trim();
    }
    return str;
  }

  // Auth
  Future<Response> login(Map<String, dynamic> data) => _dio.post('/auth/login', data: data);
  Future<Response> firebaseLogin(Map<String, dynamic> data) => _dio.post('/auth/firebase/login', data: data);
  Future<Response> googleLogin(Map<String, dynamic> data) => _dio.post('/auth/google', data: data);
  Future<Response> registerCustomer(Map<String, dynamic> data) => _dio.post('/auth/register/customer', data: data);
  Future<Response> registerRunner(Map<String, dynamic> data) => _dio.post('/auth/register/runner', data: data);
  Future<Response> logout() => _dio.post('/auth/logout');
  Future<Response> me() => _dio.get('/auth/me');
  Future<Response> updateProfile(Map<String, dynamic> data) => _dio.put('/auth/profile', data: data);
  Future<Response> changePassword(Map<String, dynamic> data) => _dio.put('/auth/password', data: data);
  Future<Response> deleteAccount(Map<String, dynamic> data) => _dio.delete('/auth/account', data: data);
  Future<Response> forgotPassword(Map<String, dynamic> data) => _dio.post('/auth/forgot-password', data: data);
  Future<Response> verifyPhone(Map<String, dynamic> data) => _dio.post('/auth/verify-phone', data: data);
  Future<Response> verifyFirebasePhone(Map<String, dynamic> data) => _dio.post('/auth/firebase/verify-phone', data: data);
  Future<Response> resendOtp() => _dio.post('/auth/resend-otp');

  // KYC
  Future<Response> kycStatus() => _dio.get('/kyc');
  Future<Response> submitKyc(Map<String, dynamic> data) => _dio.post('/kyc/submit', data: data);

  // Customer errands
  Future<Response> getCustomerErrands({Map<String, dynamic>? params}) => _dio.get('/customer/errands', queryParameters: params);
  Future<Response> createErrand(Map<String, dynamic> data) => _dio.post('/customer/errands', data: data);
  Future<Response> getErrand(String publicId) => _dio.get('/customer/errands/$publicId');
  Future<Response> cancelErrand(String publicId, String reason) => _dio.post('/customer/errands/$publicId/cancel', data: {'reason': reason});
  Future<Response> confirmCompletion(String publicId, String otp) => _dio.post('/customer/errands/$publicId/confirm-completion', data: {'otp': otp});
  Future<Response> trackErrand(String publicId) => _dio.get('/customer/errands/$publicId/tracking');
  Future<Response> triggerPanic(String publicId, Map<String, dynamic> data) => _dio.post('/customer/errands/$publicId/panic', data: data);
  Future<Response> getProof(String publicId) => _dio.get('/customer/errands/$publicId/proof');
  Future<Response> customerDashboard() => _dio.get('/customer/dashboard');
  Future<Response> initializeErrandPayment(String publicId, {String paymentMethod = 'paystack', String? gateway}) =>
      _dio.post('/customer/errands/$publicId/pay', data: {'payment_method': gateway ?? paymentMethod});
  Future<Response> verifyErrandPayment(String publicId, {String? reference, String? gateway}) =>
      _dio.post('/customer/errands/$publicId/verify-payment', data: {
        if (reference != null) 'reference': reference,
        if (gateway != null) 'gateway': gateway,
      });

  // Runner
  Future<Response> runnerDashboard() => _dio.get('/runner/dashboard');
  Future<Response> updateAvailability(Map<String, dynamic> data) => _dio.put('/runner/availability', data: data);
  Future<Response> updateRunnerLocation(Map<String, dynamic> data) => _dio.put('/runner/location', data: data);
  Future<Response> getAvailableErrands({Map<String, dynamic>? params}) => _dio.get('/runner/errands/available', queryParameters: params);
  Future<Response> getMyErrands({Map<String, dynamic>? params}) => _dio.get('/runner/errands/my-errands', queryParameters: params);
  Future<Response> getRunnerErrand(String publicId) => _dio.get('/runner/errands/$publicId');
  Future<Response> acceptErrand(String publicId) => _dio.post('/runner/errands/$publicId/accept');
  Future<Response> rejectErrand(String publicId) => _dio.post('/runner/errands/$publicId/reject');
  Future<Response> markArrived(String publicId) => _dio.post('/runner/errands/$publicId/arrived');
  Future<Response> verifyPickupOtp(String publicId, String otp) => _dio.post('/runner/errands/$publicId/pickup-otp', data: {'otp': otp});
  Future<Response> startErrand(String publicId) => _dio.post('/runner/errands/$publicId/start');
  Future<Response> submitProof(String publicId, dynamic data) => _dio.post('/runner/errands/$publicId/proof', data: data);
  Future<Response> submitProofFile(String publicId, {required String filePath, required String type, String? notes}) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'type': type,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _dio.post('/runner/errands/$publicId/proof', data: formData);
  }
  Future<Response> completeErrand(String publicId) => _dio.post('/runner/errands/$publicId/complete');
  Future<Response> cancelErrandRunner(String publicId, String reason) => _dio.post('/runner/errands/$publicId/cancel', data: {'reason': reason});
  Future<Response> updateErrandLocation(String publicId, Map<String, dynamic> data) => _dio.put('/runner/errands/$publicId/location', data: data);
  Future<Response> runnerEarnings() => _dio.get('/runner/earnings');
  Future<Response> withdrawEarnings(int amount) => _dio.post('/runner/earnings/withdraw', data: {'amount': amount});
  Future<Response> updateBankAccount(Map<String, dynamic> data) => _dio.put('/runner/earnings/bank-account', data: data);
  Future<Response> runnerPanic(String publicId, Map<String, dynamic> data) =>
      _dio.post('/runner/errands/$publicId/panic', data: data);

  Future<Response> getPaymentGateways() => _dio.get('/payment/gateways');
  Future<Response> initCustomerPayment(Map<String, dynamic> data) =>
      _dio.post('/customer/payments/initialize', data: data);
  Future<Response> verifyCustomerPayment(Map<String, dynamic> data) =>
      _dio.post('/customer/payments/verify', data: data);
  Future<Response> submitRunnerKyc(Map<String, dynamic> data) => _dio.post('/runner/kyc/submit', data: data);
  Future<Response> runnerVerificationStatus() => _dio.get('/runner/verification-status');
  Future<Response> resetPassword(Map<String, dynamic> data) => _dio.post('/auth/reset-password', data: data);
  Future<Response> runnerTrustScore() => _dio.get('/runner/trust-score');

  // Wallet
  Future<Response> getWallet() => _dio.get('/wallet');
  Future<Response> getTransactions({Map<String, dynamic>? params}) => _dio.get('/wallet/transactions', queryParameters: params);
  Future<Response> fundWallet(Map<String, dynamic> data) => _dio.post('/wallet/fund', data: data);

  // Messages
  Future<Response> getConversations() => _dio.get('/messages/conversations');
  Future<Response> getMessages(String publicId) => _dio.get('/messages/conversations/$publicId');
  Future<Response> sendMessage(String publicId, Map<String, dynamic> data) => _dio.post('/messages/conversations/$publicId', data: data);

  // Ratings
  Future<Response> submitRating(Map<String, dynamic> data) => _dio.post('/ratings', data: data);

  // Disputes
  Future<Response> openDispute(Map<String, dynamic> data) => _dio.post('/disputes', data: data);
  Future<Response> getDisputes() => _dio.get('/disputes');

  // Notifications
  Future<Response> getNotifications() => _dio.get('/notifications');
  Future<Response> markNotificationRead(int id) => _dio.put('/notifications/$id/read');
  Future<Response> markAllRead() => _dio.put('/notifications/read-all');

  Future<Response> aiChat(Map<String, dynamic> data) => _dio.post('/ai/agent', data: data);

  Future<Response> updateDeviceToken(Map<String, dynamic> data) =>
      _dio.post('/auth/device-token', data: data);

  Future<Response> getNotificationPreferences() => _dio.get('/notification-preferences');

  Future<Response> updateNotificationPreferences(Map<String, dynamic> data) =>
      _dio.put('/notification-preferences', data: data);

  Future<Response> uploadFile(String filePath, {String folder = 'general'}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      'folder': folder,
    });
    return _dio.post('/upload', data: formData);
  }

  // In-App WebRTC Voice Calls
  Future<Response> initiateCall(Map<String, dynamic> data) =>
      _dio.post('/calls/initiate', data: data);

  Future<Response> answerCall(String callId, Map<String, dynamic> data) =>
      _dio.post('/calls/$callId/answer', data: data);

  Future<Response> signalCall(String callId, Map<String, dynamic> data) =>
      _dio.post('/calls/$callId/signal', data: data);

  Future<Response> endCall(String callId, [Map<String, dynamic>? data]) =>
      _dio.post('/calls/$callId/end', data: data ?? {});

  Future<Response> rejectCall(String callId, [Map<String, dynamic>? data]) =>
      _dio.post('/calls/$callId/reject', data: data ?? {});

  Future<Response> getCall(String callId) => _dio.get('/calls/$callId');
}
