import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/audio_alert_service.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/webrtc_voice_service.dart';
import '../../../../main.dart';

enum VoiceCallStatus {
  incoming,
  outgoingRinging,
  connecting,
  connected,
  ended,
}

class VoiceCallScreen extends StatefulWidget {
  final String? callId;
  final String errandId;
  final String errandTitle;
  final String contactName;
  final String? contactAvatar;
  final bool isIncoming;
  final String? initialOfferSdp;

  const VoiceCallScreen({
    super.key,
    this.callId,
    required this.errandId,
    required this.errandTitle,
    required this.contactName,
    this.contactAvatar,
    this.isIncoming = false,
    this.initialOfferSdp,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> with SingleTickerProviderStateMixin {
  final WebRtcVoiceService _webrtc = WebRtcVoiceService();
  final ApiClient _api = getIt<ApiClient>();

  late VoiceCallStatus _status;
  String? _activeCallId;
  bool _isMuted = false;
  bool _isSpeaker = false;

  int _callDurationSeconds = 0;
  Timer? _durationTimer;
  Timer? _timeoutTimer;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _activeCallId = widget.callId;
    _status = widget.isIncoming ? VoiceCallStatus.incoming : VoiceCallStatus.outgoingRinging;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _listenRealtimeEvents();

    if (widget.isIncoming) {
      AudioAlertService.instance.playRunnerDispatchAlarm(loop: true);
      // Callee timeout: 45s
      _timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_status == VoiceCallStatus.incoming) {
          _endCall(reason: 'missed');
        }
      });
    } else {
      _startOutgoingCall();
    }
  }

  void _listenRealtimeEvents() {
    RealtimeService.instance.subscribeErrand(
      errandId: widget.errandId,
      onEvent: (eventName, data) {
        if (!mounted) return;

        if (eventName == 'CallAnswered' && data != null) {
          final answerSdp = data['answer_sdp'] as String?;
          if (answerSdp != null && _status == VoiceCallStatus.outgoingRinging) {
            _handleCalleeAnswered(answerSdp);
          }
        } else if (eventName == 'CallSignal' && data != null) {
          final candidate = data['candidate'];
          if (candidate is Map<String, dynamic>) {
            _webrtc.addCandidate(candidate);
          }
        } else if (eventName == 'CallEnded' || eventName == 'CallRejected') {
          _finishCallLocally();
        }
      },
    );
  }

  Future<void> _startOutgoingCall() async {
    try {
      final offerSdp = await _webrtc.createOffer(
        onCandidate: (candidate) {
          if (_activeCallId != null) {
            _api.signalCall(_activeCallId!, {
              'candidate': candidate.toMap(),
            }).ignore();
          }
        },
        onStateChange: (state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _onCallConnected();
          } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _endCall(reason: 'failed');
          }
        },
      );

      final response = await _api.initiateCall({
        'errand_id': widget.errandId,
        'offer_sdp': offerSdp,
        'type': 'audio',
      });

      final callData = response.data['call'];
      if (mounted) {
        setState(() {
          _activeCallId = callData['public_id'];
        });
      }

      // Outgoing timeout: 45s
      _timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (_status == VoiceCallStatus.outgoingRinging) {
          _endCall(reason: 'timeout');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _answerCall() async {
    if (widget.initialOfferSdp == null || _activeCallId == null) return;

    await AudioAlertService.instance.stop();
    _timeoutTimer?.cancel();

    setState(() {
      _status = VoiceCallStatus.connecting;
    });

    try {
      final answerSdp = await _webrtc.handleIncomingOffer(
        widget.initialOfferSdp!,
        onCandidate: (candidate) {
          if (_activeCallId != null) {
            _api.signalCall(_activeCallId!, {
              'candidate': candidate.toMap(),
            }).ignore();
          }
        },
        onStateChange: (state) {
          if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
            _onCallConnected();
          } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
            _endCall(reason: 'failed');
          }
        },
      );

      await _api.answerCall(_activeCallId!, {
        'answer_sdp': answerSdp,
      });
    } catch (e) {
      _endCall(reason: 'error');
    }
  }

  Future<void> _handleCalleeAnswered(String answerSdp) async {
    _timeoutTimer?.cancel();
    setState(() {
      _status = VoiceCallStatus.connecting;
    });

    try {
      await _webrtc.applyAnswer(answerSdp);
    } catch (e) {
      _endCall(reason: 'connection_error');
    }
  }

  void _onCallConnected() {
    if (!mounted) return;
    setState(() {
      _status = VoiceCallStatus.connected;
    });

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _callDurationSeconds++;
        });
      }
    });
  }

  Future<void> _endCall({String reason = 'hangup'}) async {
    await AudioAlertService.instance.stop();
    _timeoutTimer?.cancel();
    _durationTimer?.cancel();

    if (_activeCallId != null) {
      if (_status == VoiceCallStatus.incoming) {
        _api.rejectCall(_activeCallId!, {'reason': reason}).ignore();
      } else {
        _api.endCall(_activeCallId!, {'reason': reason}).ignore();
      }
    }

    _finishCallLocally();
  }

  void _finishCallLocally() {
    if (!mounted) return;
    setState(() {
      _status = VoiceCallStatus.ended;
    });

    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    _webrtc.dispose();

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  String _formatTimer(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _durationTimer?.cancel();
    _timeoutTimer?.cancel();
    _webrtc.dispose();
    AudioAlertService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121317),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Errand Title Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  widget.errandTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Spacer(),

              // Animated Pulsing Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_status == VoiceCallStatus.incoming || _status == VoiceCallStatus.outgoingRinging)
                    FadeTransition(
                      opacity: Tween<double>(begin: 0.6, end: 0.0).animate(_pulseController),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.5).animate(_pulseController),
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _status == VoiceCallStatus.connected
                            ? const Color(0xFF10B981)
                            : Colors.white24,
                        width: 3,
                      ),
                      color: const Color(0xFF1A1B22),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: widget.contactAvatar != null && widget.contactAvatar!.isNotEmpty
                        ? Image.network(widget.contactAvatar!, fit: BoxFit.cover)
                        : const Icon(Icons.person, size: 64, color: Colors.white38),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Contact Name
              Text(
                widget.contactName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Status / Duration
              if (_status == VoiceCallStatus.connected)
                Text(
                  _formatTimer(_callDurationSeconds),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                )
              else if (_status == VoiceCallStatus.incoming)
                const Text(
                  'Incoming Voice Call...',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 14, fontWeight: FontWeight.w500),
                )
              else if (_status == VoiceCallStatus.outgoingRinging)
                const Text(
                  'Ringing...',
                  style: TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.w500),
                )
              else if (_status == VoiceCallStatus.connecting)
                const Text(
                  'Connecting...',
                  style: TextStyle(color: Colors.lightBlueAccent, fontSize: 14, fontWeight: FontWeight.w500),
                )
              else
                const Text(
                  'Call Ended',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),

              const Spacer(),

              // Bottom Actions Bar
              if (_status == VoiceCallStatus.incoming)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Decline
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _endCall(reason: 'declined'),
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.redAccent,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),

                    // Accept
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _answerCall,
                          borderRadius: BorderRadius.circular(35),
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 30),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Accept', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isMuted = !_isMuted;
                          _webrtc.setMuted(_isMuted);
                        });
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMuted ? Colors.redAccent.withValues(alpha: 0.2) : Colors.white12,
                          border: Border.all(
                            color: _isMuted ? Colors.redAccent : Colors.white24,
                          ),
                        ),
                        child: Icon(
                          _isMuted ? Icons.mic_off : Icons.mic,
                          color: _isMuted ? Colors.redAccent : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // End Call
                    InkWell(
                      onTap: () => _endCall(reason: 'hangup'),
                      borderRadius: BorderRadius.circular(35),
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                      ),
                    ),

                    // Speaker
                    InkWell(
                      onTap: () async {
                        final next = !_isSpeaker;
                        await _webrtc.setSpeaker(next);
                        if (mounted) {
                          setState(() {
                            _isSpeaker = next;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isSpeaker ? Colors.amber.withValues(alpha: 0.2) : Colors.white12,
                          border: Border.all(
                            color: _isSpeaker ? Colors.amber : Colors.white24,
                          ),
                        ),
                        child: Icon(
                          _isSpeaker ? Icons.volume_up : Icons.volume_down,
                          color: _isSpeaker ? Colors.amber : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
