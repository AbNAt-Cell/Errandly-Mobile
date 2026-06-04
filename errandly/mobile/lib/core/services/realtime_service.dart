import '../constants/app_constants.dart';

/// Realtime updates: use Pusher when [AppConstants.pusherKey] is configured,
/// otherwise clients poll tracking/status endpoints (see errand detail screens).
class RealtimeService {
  static bool get isConfigured =>
      AppConstants.pusherKey.isNotEmpty;
}
