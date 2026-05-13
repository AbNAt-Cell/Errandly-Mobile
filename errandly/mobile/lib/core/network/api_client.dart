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
          // Navigate to login
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

  // Auth
  Future<Response> login(Map<String, dynamic> data) => _dio.post('/auth/login', data: data);
  Future<Response> registerCustomer(Map<String, dynamic> data) => _dio.post('/auth/register/customer', data: data);
  Future<Response> registerRunner(Map<String, dynamic> data) => _dio.post('/auth/register/runner', data: data);
  Future<Response> logout() => _dio.post('/auth/logout');
  Future<Response> me() => _dio.get('/auth/me');
  Future<Response> updateProfile(Map<String, dynamic> data) => _dio.put('/auth/profile', data: data);
  Future<Response> forgotPassword(Map<String, dynamic> data) => _dio.post('/auth/forgot-password', data: data);
  Future<Response> verifyPhone(Map<String, dynamic> data) => _dio.post('/auth/verify-phone', data: data);
  Future<Response> resendOtp() => _dio.post('/auth/resend-otp');

  // KYC
  Future<Response> kycStatus() => _dio.get('/kyc');
  Future<Response> submitKyc(Map<String, dynamic> data) => _dio.post('/kyc/submit', data: data);

  // Customer errands
  Future<Response> getCustomerErrands({Map<String, dynamic>? params}) => _dio.get('/customer/errands', queryParameters: params);
  Future<Response> createErrand(Map<String, dynamic> data) => _dio.post('/customer/errands', data: data);
  Future<Response> getErrand(int id) => _dio.get('/customer/errands/$id');
  Future<Response> cancelErrand(int id, String reason) => _dio.post('/customer/errands/$id/cancel', data: {'reason': reason});
  Future<Response> confirmCompletion(int id, String otp) => _dio.post('/customer/errands/$id/confirm-completion', data: {'otp': otp});
  Future<Response> trackErrand(int id) => _dio.get('/customer/errands/$id/tracking');
  Future<Response> triggerPanic(int id, Map<String, dynamic> data) => _dio.post('/customer/errands/$id/panic', data: data);
  Future<Response> getProof(int id) => _dio.get('/customer/errands/$id/proof');
  Future<Response> customerDashboard() => _dio.get('/customer/dashboard');

  // Runner
  Future<Response> runnerDashboard() => _dio.get('/runner/dashboard');
  Future<Response> updateAvailability(Map<String, dynamic> data) => _dio.put('/runner/availability', data: data);
  Future<Response> updateRunnerLocation(Map<String, dynamic> data) => _dio.put('/runner/location', data: data);
  Future<Response> getAvailableErrands({Map<String, dynamic>? params}) => _dio.get('/runner/errands/available', queryParameters: params);
  Future<Response> getMyErrands({Map<String, dynamic>? params}) => _dio.get('/runner/errands/my-errands', queryParameters: params);
  Future<Response> acceptErrand(int id) => _dio.post('/runner/errands/$id/accept');
  Future<Response> rejectErrand(int id) => _dio.post('/runner/errands/$id/reject');
  Future<Response> markArrived(int id) => _dio.post('/runner/errands/$id/arrived');
  Future<Response> verifyPickupOtp(int id, String otp) => _dio.post('/runner/errands/$id/pickup-otp', data: {'otp': otp});
  Future<Response> startErrand(int id) => _dio.post('/runner/errands/$id/start');
  Future<Response> submitProof(int id, Map<String, dynamic> data) => _dio.post('/runner/errands/$id/proof', data: data);
  Future<Response> completeErrand(int id) => _dio.post('/runner/errands/$id/complete');
  Future<Response> cancelErrandRunner(int id, String reason) => _dio.post('/runner/errands/$id/cancel', data: {'reason': reason});
  Future<Response> updateErrandLocation(int id, Map<String, dynamic> data) => _dio.put('/runner/errands/$id/location', data: data);
  Future<Response> runnerEarnings() => _dio.get('/runner/earnings');
  Future<Response> withdrawEarnings(int amount) => _dio.post('/runner/earnings/withdraw', data: {'amount': amount});
  Future<Response> updateBankAccount(Map<String, dynamic> data) => _dio.put('/runner/earnings/bank-settings', data: data);
  Future<Response> runnerTrustScore() => _dio.get('/runner/trust-score');

  // Wallet
  Future<Response> getWallet() => _dio.get('/wallet');
  Future<Response> getTransactions({Map<String, dynamic>? params}) => _dio.get('/wallet/transactions', queryParameters: params);
  Future<Response> fundWallet(Map<String, dynamic> data) => _dio.post('/wallet/fund', data: data);

  // Messages
  Future<Response> getConversations() => _dio.get('/messages/conversations');
  Future<Response> getMessages(int errandId) => _dio.get('/messages/conversations/$errandId');
  Future<Response> sendMessage(int errandId, Map<String, dynamic> data) => _dio.post('/messages/conversations/$errandId', data: data);

  // Ratings
  Future<Response> submitRating(Map<String, dynamic> data) => _dio.post('/ratings', data: data);

  // Disputes
  Future<Response> openDispute(Map<String, dynamic> data) => _dio.post('/disputes', data: data);
  Future<Response> getDisputes() => _dio.get('/disputes');

  // Notifications
  Future<Response> getNotifications() => _dio.get('/notifications');
  Future<Response> markNotificationRead(int id) => _dio.put('/notifications/$id/read');
  Future<Response> markAllRead() => _dio.put('/notifications/read-all');
}
