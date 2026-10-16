import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Audio alerting service for dispatch sounds, new errand alarms, and completion chimes.
class AudioAlertService {
  AudioAlertService._();
  static final AudioAlertService instance = AudioAlertService._();

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  /// Plays the urgent runner dispatch alarm (repeats or plays alert tone).
  Future<void> playRunnerDispatchAlarm({bool loop = false}) async {
    try {
      await _player.stop();
      await _player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/errand_alert.wav'));
      _isPlaying = true;
    } catch (e) {
      debugPrint('AudioAlertService: failed to play dispatch alarm ($e)');
    }
  }

  /// Plays the customer celebration chime when an errand is accepted.
  Future<void> playCustomerChime() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setVolume(0.9);
      await _player.play(AssetSource('sounds/errand_accepted.wav'));
      _isPlaying = false;
    } catch (e) {
      debugPrint('AudioAlertService: failed to play customer chime ($e)');
    }
  }

  /// Plays the admin or order alert sound.
  Future<void> playOrderAlert() async {
    try {
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.setVolume(0.85);
      await _player.play(AssetSource('sounds/admin_order_alert.wav'));
      _isPlaying = false;
    } catch (e) {
      debugPrint('AudioAlertService: failed to play order alert ($e)');
    }
  }

  /// Stops any currently playing alarm or sound.
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('AudioAlertService: error stopping audio ($e)');
    }
  }
}
