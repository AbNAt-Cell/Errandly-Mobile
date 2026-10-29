import 'dart:async';
import 'package:geolocator/geolocator.dart';

enum LocationFixStatus {
  success,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  error,
}

class LocationFixResult {
  final LocationFixStatus status;
  final Position? position;
  final String? message;
  final double? accuracy; // Accuracy radius in meters
  final bool isExactGps;
  final DateTime timestamp;

  LocationFixResult({
    required this.status,
    this.position,
    this.message,
    this.accuracy,
    this.isExactGps = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isSuccess => status == LocationFixStatus.success && position != null;

  @override
  String toString() =>
      'LocationFixResult(status: $status, pos: ${position?.latitude},${position?.longitude}, accuracy: ${accuracy}m, isExact: $isExactGps)';
}

class LocationService {
  /// Check and request location permission with granular status reporting.
  static Future<LocationFixStatus> checkAndRequestPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationFixStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return LocationFixStatus.permissionDenied;
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationFixStatus.permissionDeniedForever;
    }

    return LocationFixStatus.success;
  }

  /// Simple boolean permission check for backward compatibility.
  static Future<bool> requestPermission() async {
    final status = await checkAndRequestPermission();
    return status == LocationFixStatus.success;
  }

  /// Request a high-accuracy native GPS fix with timeout and fallback to recent fix.
  static Future<LocationFixResult> getHighAccuracyPosition({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final permStatus = await checkAndRequestPermission();
    if (permStatus != LocationFixStatus.success) {
      String msg = 'Location permission is required.';
      if (permStatus == LocationFixStatus.serviceDisabled) {
        msg = 'Location services are turned off on your device. Please turn on GPS in settings.';
      } else if (permStatus == LocationFixStatus.permissionDeniedForever) {
        msg = 'Location permission is permanently denied. Please grant permission in application settings.';
      }
      return LocationFixResult(
        status: permStatus,
        message: msg,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: timeout,
      );
      return LocationFixResult(
        status: LocationFixStatus.success,
        position: position,
        accuracy: position.accuracy,
        isExactGps: true,
      );
    } on TimeoutException {
      // Try fetching the last known position to prevent blocking the user
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          return LocationFixResult(
            status: LocationFixStatus.success,
            position: last,
            accuracy: last.accuracy,
            isExactGps: false,
            message: 'Using recent location fix (GPS timed out).',
          );
        }
      } catch (_) {}

      return LocationFixResult(
        status: LocationFixStatus.timeout,
        message: 'GPS acquisition timed out. Please verify your GPS is active or pick on map.',
      );
    } catch (e) {
      return LocationFixResult(
        status: LocationFixStatus.error,
        message: 'Error acquiring location: $e',
      );
    }
  }

  /// Direct position getter for legacy callers.
  static Future<Position?> getCurrentPosition() async {
    final res = await getHighAccuracyPosition();
    return res.position;
  }

  /// Stream position updates for real-time tracking.
  static Stream<Position> getPositionStream({int distanceFilter = 15}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  /// Calculate distance between two coordinates in kilometers.
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000;
  }

  /// Validate latitude and longitude coordinates.
  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat < -90.0 || lat > 90.0) return false;
    if (lng < -180.0 || lng > 180.0) return false;
    // Reject Null Island (0,0) as an invalid placeholder
    if (lat == 0.0 && lng == 0.0) return false;
    return true;
  }

  /// Format coordinates into structured readable notation.
  static String formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(5)}° $latDir, ${lng.abs().toStringAsFixed(5)}° $lngDir';
  }
}
