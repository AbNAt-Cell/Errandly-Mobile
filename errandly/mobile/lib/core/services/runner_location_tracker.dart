import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../network/api_client.dart';
import '../../main.dart';
import 'location_service.dart';

/// Service responsible for streaming the runner's live GPS coordinates
/// to the backend and customer during an active delivery/errand.
class RunnerLocationTracker {
  RunnerLocationTracker._();
  static final RunnerLocationTracker instance = RunnerLocationTracker._();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  String? _activeErrandPublicId;
  DateTime? _lastSentAt;
  Position? _lastPosition;

  final ValueNotifier<bool> isTrackingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<Position?> currentPositionNotifier = ValueNotifier<Position?>(null);

  bool get isTracking => _activeErrandPublicId != null;
  String? get activeErrandPublicId => _activeErrandPublicId;
  Position? get lastPosition => _lastPosition;

  /// Start streaming live GPS coordinates for the specified active errand.
  Future<void> startTracking({required String errandPublicId}) async {
    if (_activeErrandPublicId == errandPublicId && _positionSubscription != null) {
      return;
    }

    if (_activeErrandPublicId != null && _activeErrandPublicId != errandPublicId) {
      stopTracking();
    }

    final hasPermission = await LocationService.requestPermission();
    if (!hasPermission) {
      debugPrint('RunnerLocationTracker: Location permission denied or restricted.');
      return;
    }

    _activeErrandPublicId = errandPublicId;
    isTrackingNotifier.value = true;
    debugPrint('RunnerLocationTracker: Started live tracking for errand: $errandPublicId');

    // 1. Immediately send current position snapshot
    try {
      final initial = await LocationService.getCurrentPosition();
      if (initial != null) {
        _lastPosition = initial;
        currentPositionNotifier.value = initial;
        await _sendLocationUpdate(errandPublicId, initial);
      }
    } catch (e) {
      debugPrint('RunnerLocationTracker: Error obtaining initial location: $e');
    }

    // 2. Stream GPS location changes
    _positionSubscription?.cancel();
    _positionSubscription = LocationService.getPositionStream().listen(
      (pos) {
        _lastPosition = pos;
        currentPositionNotifier.value = pos;
        final now = DateTime.now();
        // Send if at least 4 seconds have elapsed since last network post
        if (_lastSentAt == null || now.difference(_lastSentAt!).inSeconds >= 4) {
          _sendLocationUpdate(errandPublicId, pos);
        }
      },
      onError: (err) {
        debugPrint('RunnerLocationTracker stream error: $err');
      },
    );

    // 3. Periodic fallback timer: guarantees customer receives fresh updates
    // every 10 seconds even if the runner is stationary (e.g. at a traffic light or pickup queue)
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (_activeErrandPublicId == null) return;
      try {
        final pos = await LocationService.getCurrentPosition();
        if (pos != null) {
          _lastPosition = pos;
          currentPositionNotifier.value = pos;
          final now = DateTime.now();
          if (_lastSentAt == null || now.difference(_lastSentAt!).inSeconds >= 8) {
            await _sendLocationUpdate(_activeErrandPublicId!, pos);
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _sendLocationUpdate(String errandPublicId, Position pos) async {
    _lastSentAt = DateTime.now();
    try {
      final api = getIt<ApiClient>();
      await api.updateErrandLocation(
        errandPublicId,
        {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed': pos.speed,
          'heading': pos.heading,
          'accuracy': pos.accuracy,
        },
      );
      debugPrint(
        'RunnerLocationTracker: Location sent -> ($errandPublicId, lat: ${pos.latitude}, lng: ${pos.longitude}, acc: ${pos.accuracy}m)',
      );
    } catch (e) {
      debugPrint('RunnerLocationTracker: Failed to send location update: $e');
    }
  }

  /// Stop tracking when the errand finishes, cancels, or when runner goes offline.
  void stopTracking() {
    if (_activeErrandPublicId != null) {
      debugPrint('RunnerLocationTracker: Stopped tracking for errand: $_activeErrandPublicId');
    }
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _activeErrandPublicId = null;
    _lastSentAt = null;
    _lastPosition = null;
    isTrackingNotifier.value = false;
    currentPositionNotifier.value = null;
  }
}

