class AppConstants {
  static const String appName = 'Errandly';
  static const String baseUrl = 'http://localhost:8000/api';
  static const String pusherKey = '';
  static const String pusherCluster = 'mt1';

  // Storage keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_roles';

  // Commission
  static const double commissionRate = 0.15;
  static const int minErrandAmount = 500;

  // Map defaults (Lagos, Nigeria)
  static const double defaultLat = 6.5244;
  static const double defaultLng = 3.3792;

  // OTP
  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  // Trust score thresholds
  static const double trustedScore = 80.0;
  static const double warningScore = 50.0;

  // Errand categories
  static const Map<String, String> categoryLabels = {
    'package_pickup': 'Package Pickup',
    'item_delivery': 'Item Delivery',
    'grocery_purchase': 'Grocery Purchase',
    'queue_standing': 'Queue Standing',
    'document_submission': 'Document Submission',
    'document_collection': 'Document Collection',
    'shopping_assistance': 'Shopping Assistance',
    'prescription_pickup': 'Prescription Pickup',
    'personal_assistance': 'Personal Assistance',
    'custom_errand': 'Custom Errand',
  };

  static const Map<String, String> categoryEmojis = {
    'package_pickup': '📦',
    'item_delivery': '🚗',
    'grocery_purchase': '🛒',
    'queue_standing': '🏃',
    'document_submission': '📄',
    'document_collection': '📁',
    'shopping_assistance': '🛍️',
    'prescription_pickup': '💊',
    'personal_assistance': '🤝',
    'custom_errand': '✨',
  };

  // Errand status
  static const Map<String, String> statusLabels = {
    'draft': 'Draft',
    'posted': 'Posted',
    'pending_assignment': 'Finding Runner...',
    'accepted': 'Runner Assigned',
    'runner_en_route': 'Runner En Route',
    'item_picked': 'Item Picked Up',
    'in_progress': 'In Progress',
    'awaiting_confirmation': 'Awaiting Confirmation',
    'completed': 'Completed',
    'cancelled': 'Cancelled',
    'failed': 'Failed',
    'disputed': 'Disputed',
    'refunded': 'Refunded',
  };
}
