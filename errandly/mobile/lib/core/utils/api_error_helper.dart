import '../network/api_client.dart';

/// Maps API / network errors to user-friendly messages.
class ApiErrorHelper {
  static String message(Object error) {
    return ApiClient.formatErrorMessage(error);
  }
}
