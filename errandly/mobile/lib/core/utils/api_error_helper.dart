import 'package:dio/dio.dart';

/// Maps API / network errors to user-friendly messages.
class ApiErrorHelper {
  static String message(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timed out. Check your internet and try again.';
        case DioExceptionType.connectionError:
          return 'Unable to reach the server. Check your internet connection.';
        case DioExceptionType.badResponse:
          return _fromResponse(error.response);
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        default:
          return 'Something went wrong. Please try again.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  static String _fromResponse(Response<dynamic>? response) {
    final status = response?.statusCode;
    final data = response?.data;

    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;

      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        if (first is String) return first;
      }
    }

    return switch (status) {
      401 => 'Invalid email/phone or password.',
      403 => 'Your account cannot access this right now.',
      404 => 'The requested resource was not found.',
      409 => 'This action cannot be completed right now.',
      422 => 'Please check your input and try again.',
      >= 500 => 'Server error. Please try again later.',
      _ => 'Request failed. Please try again.',
    };
  }
}
