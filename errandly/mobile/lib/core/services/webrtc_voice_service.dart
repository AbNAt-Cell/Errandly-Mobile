import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// WebRTC Voice Calling Service for Errandly Mobile.
/// Handles audio stream acquisition, STUN server configuration, SDP offer/answer exchange,
/// and microphone/speaker controls.
class WebRtcVoiceService {
  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  final List<RTCIceCandidate> _bufferedCandidates = [];
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  bool get isMuted => _isMuted;
  bool get isSpeakerOn => _isSpeakerOn;
  MediaStream? get remoteStream => _remoteStream;

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ],
  };

  static const Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
    },
    'video': false,
  };

  Future<MediaStream> _acquireMicrophone() async {
    if (_localStream != null) return _localStream!;

    try {
      final stream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _localStream = stream;
      return stream;
    } catch (e) {
      debugPrint('WebRtcVoiceService: Could not acquire microphone ($e)');
      rethrow;
    }
  }

  Future<RTCPeerConnection> _createPeer({
    required void Function(RTCIceCandidate candidate) onCandidate,
    required void Function(RTCPeerConnectionState state) onStateChange,
  }) async {
    await _cleanupPeer();
    _bufferedCandidates.clear();

    final pc = await createPeerConnection(_iceServers);

    pc.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        onCandidate(candidate);
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('WebRTC Connection state: $state');
      onStateChange(state);
    };

    pc.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
      }
    };

    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        await pc.addTrack(track, _localStream!);
      }
    }

    _peer = pc;
    return pc;
  }

  /// Normalize an SDP string to ensure strict RFC 4566 CRLF (\r\n) termination.
  static String _normalizeSdp(String? sdp) {
    if (sdp == null || sdp.isEmpty) return '';
    final lines = sdp
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);
    return '${lines.join('\r\n')}\r\n';
  }

  /// Caller: Initiate an outgoing call and produce Offer SDP
  Future<String> createOffer({
    required void Function(RTCIceCandidate candidate) onCandidate,
    required void Function(RTCPeerConnectionState state) onStateChange,
  }) async {
    await _acquireMicrophone();
    final pc = await _createPeer(onCandidate: onCandidate, onStateChange: onStateChange);

    final offer = await pc.createOffer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
    await pc.setLocalDescription(offer);

    return _normalizeSdp(offer.sdp);
  }

  /// Callee: Handle incoming Offer SDP and produce Answer SDP
  Future<String> handleIncomingOffer(
    String offerSdp, {
    required void Function(RTCIceCandidate candidate) onCandidate,
    required void Function(RTCPeerConnectionState state) onStateChange,
  }) async {
    await _acquireMicrophone();
    final pc = await _createPeer(onCandidate: onCandidate, onStateChange: onStateChange);

    final cleanOffer = _normalizeSdp(offerSdp);
    final rtcOffer = RTCSessionDescription(cleanOffer, 'offer');
    await pc.setRemoteDescription(rtcOffer);
    await _flushCandidates();

    final answer = await pc.createAnswer({'offerToReceiveAudio': true, 'offerToReceiveVideo': false});
    await pc.setLocalDescription(answer);

    return _normalizeSdp(answer.sdp);
  }

  /// Caller: Apply remote Answer SDP
  Future<void> applyAnswer(String answerSdp) async {
    if (_peer == null) return;
    final cleanAnswer = _normalizeSdp(answerSdp);
    final rtcAnswer = RTCSessionDescription(cleanAnswer, 'answer');
    await _peer!.setRemoteDescription(rtcAnswer);
    await _flushCandidates();
  }

  /// Add ICE Candidate relayed from signaling
  Future<void> addCandidate(Map<String, dynamic> candidateMap) async {
    try {
      final cand = RTCIceCandidate(
        candidateMap['candidate'] ?? candidateMap['candidateInit'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );

      if (_peer == null) {
        _bufferedCandidates.add(cand);
        return;
      }

      final remoteDesc = await _peer!.getRemoteDescription();
      if (remoteDesc == null) {
        _bufferedCandidates.add(cand);
        return;
      }

      await _peer!.addCandidate(cand);
    } catch (e) {
      debugPrint('WebRtcVoiceService: Failed to add candidate ($e)');
    }
  }

  Future<void> _flushCandidates() async {
    if (_peer == null) return;
    while (_bufferedCandidates.isNotEmpty) {
      final cand = _bufferedCandidates.removeAt(0);
      try {
        await _peer!.addCandidate(cand);
      } catch (_) {}
    }
  }

  /// Toggle microphone mute
  bool setMuted(bool muted) {
    _isMuted = muted;
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !muted;
      }
    }
    return _isMuted;
  }

  /// Toggle device loudspeaker
  Future<bool> setSpeaker(bool speakerOn) async {
    _isSpeakerOn = speakerOn;
    try {
      if (_localStream != null) {
        for (final track in _localStream!.getAudioTracks()) {
          track.enableSpeakerphone(speakerOn);
        }
      }
    } catch (e) {
      debugPrint('WebRtcVoiceService: Error toggling speakerphone ($e)');
    }
    return _isSpeakerOn;
  }

  Future<void> _cleanupPeer() async {
    if (_peer != null) {
      try {
        await _peer!.close();
        await _peer!.dispose();
      } catch (_) {}
      _peer = null;
    }
  }

  /// Full teardown of call session
  Future<void> dispose() async {
    await _cleanupPeer();

    if (_localStream != null) {
      try {
        for (final track in _localStream!.getTracks()) {
          await track.stop();
        }
        await _localStream!.dispose();
      } catch (_) {}
      _localStream = null;
    }

    _remoteStream = null;
    _bufferedCandidates.clear();
    _isMuted = false;
    _isSpeakerOn = false;
  }
}
