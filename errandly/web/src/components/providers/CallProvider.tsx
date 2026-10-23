'use client';

import React, { createContext, useContext, useState, useEffect, useRef, useCallback } from 'react';
import toast from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';
import { callApi } from '@/lib/api';
import { subscribeUserChannel, onCallEvent } from '@/lib/pusher';
import { soundService } from '@/lib/sound';
import { webrtcVoiceService } from '@/lib/webrtc';
import CallModal from '@/components/shared/CallModal';

export type CallState =
  | 'idle'
  | 'outgoing_ringing'
  | 'incoming_ringing'
  | 'connecting'
  | 'connected'
  | 'ended';

export interface IncomingCallData {
  call_id: string;
  errand_id: number | string;
  errand_public_id?: string;
  errand_title?: string;
  offer_sdp: string;
  type?: string;
  caller: {
    id?: number | string;
    name: string;
    avatar?: string;
    phone?: string;
  };
}

export interface ActiveCallData {
  callId: string;
  errandId: string | number;
  errandTitle: string;
  recipientName: string;
  recipientAvatar?: string;
  isCaller: boolean;
}

interface CallContextType {
  callState: CallState;
  incomingCall: IncomingCallData | null;
  activeCall: ActiveCallData | null;
  callDuration: number;
  isMuted: boolean;
  toggleMute: () => void;
  initiateCall: (params: {
    errandId: string | number;
    errandPublicId?: string;
    errandTitle: string;
    recipientName: string;
    recipientAvatar?: string;
  }) => Promise<void>;
  answerCall: () => Promise<void>;
  rejectCall: (reason?: string) => Promise<void>;
  endCall: (reason?: string) => Promise<void>;
}

const CallContext = createContext<CallContextType | null>(null);

export function useCall() {
  const ctx = useContext(CallContext);
  if (!ctx) {
    throw new Error('useCall must be used within a CallProvider');
  }
  return ctx;
}

export function CallProvider({ children }: { children: React.ReactNode }) {
  const { user, isAuthenticated } = useAuthStore();

  const [callState, setCallState] = useState<CallState>('idle');
  const [incomingCall, setIncomingCall] = useState<IncomingCallData | null>(null);
  const [activeCall, setActiveCall] = useState<ActiveCallData | null>(null);
  const [callDuration, setCallDuration] = useState<number>(0);
  const [isMuted, setIsMuted] = useState<boolean>(false);

  // References for timeouts, intervals, and state access inside listeners
  const activeCallRef = useRef<ActiveCallData | null>(null);
  const incomingCallRef = useRef<IncomingCallData | null>(null);
  const callStateRef = useRef<CallState>('idle');
  const durationTimerRef = useRef<NodeJS.Timeout | null>(null);
  const ringingTimeoutRef = useRef<NodeJS.Timeout | null>(null);

  // Keep refs in sync with state
  useEffect(() => {
    activeCallRef.current = activeCall;
  }, [activeCall]);

  useEffect(() => {
    incomingCallRef.current = incomingCall;
  }, [incomingCall]);

  useEffect(() => {
    callStateRef.current = callState;
  }, [callState]);

  // Clean up duration timer helper
  const stopDurationTimer = useCallback(() => {
    if (durationTimerRef.current) {
      clearInterval(durationTimerRef.current);
      durationTimerRef.current = null;
    }
  }, []);

  // Clean up ringing timeout helper
  const stopRingingTimeout = useCallback(() => {
    if (ringingTimeoutRef.current) {
      clearTimeout(ringingTimeoutRef.current);
      ringingTimeoutRef.current = null;
    }
  }, []);

  // Full reset to idle
  const resetCallState = useCallback(() => {
    stopDurationTimer();
    stopRingingTimeout();
    try {
      soundService.stopRingtone();
      soundService.stopDialtone();
    } catch {}
    try {
      webrtcVoiceService.cleanup();
    } catch {}
    setCallDuration(0);
    setIsMuted(false);
    setActiveCall(null);
    setIncomingCall(null);
    setCallState('idle');
  }, [stopDurationTimer, stopRingingTimeout]);

  // End active call gracefully
  const endCall = useCallback(
    async (reason = 'hangup') => {
      const current = activeCallRef.current;
      try {
        soundService.stopDialtone();
        soundService.stopRingtone();
        soundService.playCallEndedTone();
      } catch {}

      if (current?.callId) {
        try {
          await callApi.end(current.callId, { reason });
        } catch {}
      }

      setCallState('ended');
      setTimeout(() => {
        resetCallState();
      }, 1200);
    },
    [resetCallState]
  );

  // Decline or reject incoming call
  const rejectCall = useCallback(
    async (reason = 'declined') => {
      const inc = incomingCallRef.current;
      try {
        soundService.stopRingtone();
        soundService.playCallEndedTone();
      } catch {}

      if (inc?.call_id) {
        try {
          await callApi.reject(inc.call_id, { reason });
        } catch {}
      }

      resetCallState();
    },
    [resetCallState]
  );

  // Answer incoming call
  const answerCall = useCallback(async () => {
    const inc = incomingCallRef.current;
    if (!inc) return;

    try {
      soundService.stopRingtone();
    } catch {}
    stopRingingTimeout();
    setCallState('connecting');

    const callId = inc.call_id;
    const callerName = inc.caller?.name || 'Errand Contact';
    const callerAvatar = inc.caller?.avatar;
    const errandTitle = inc.errand_title || 'Active Errand';

    try {
      const answerSdp = await webrtcVoiceService.handleIncomingOffer(inc.offer_sdp, {
        onIceCandidate: (candidate) => {
          callApi.signal(callId, { candidate }).catch(() => {});
        },
        onConnectionStateChange: (state) => {
          console.log('[WebRTC] Callee connection state:', state);
          if (state === 'connected') {
            setCallState('connected');
          } else if (state === 'failed' || state === 'disconnected') {
            toast.error('Voice call disconnected');
            endCall('connection_failed');
          }
        },
      });

      await callApi.answer(callId, { answer_sdp: answerSdp });

      setActiveCall({
        callId,
        errandId: inc.errand_id,
        errandTitle,
        recipientName: callerName,
        recipientAvatar: callerAvatar,
        isCaller: false,
      });

      setIncomingCall(null);
    } catch (err: any) {
      console.error('[WebRTC] Answer call error:', err);
      toast.error(err.message || 'Failed to answer call');
      rejectCall('error');
    }
  }, [stopRingingTimeout, endCall, rejectCall]);

  // Initiate an outgoing call
  const initiateCall = useCallback(
    async ({
      errandId,
      errandPublicId,
      errandTitle,
      recipientName,
      recipientAvatar,
    }: {
      errandId: string | number;
      errandPublicId?: string;
      errandTitle: string;
      recipientName: string;
      recipientAvatar?: string;
    }) => {
      if (callStateRef.current !== 'idle') {
        toast.error('You are already on a call');
        return;
      }

      setCallState('outgoing_ringing');
      try {
        soundService.startDialtone();
      } catch {}

      try {
        let currentCallId: string | null = null;

        const offerSdp = await webrtcVoiceService.createOffer({
          onIceCandidate: (candidate) => {
            if (currentCallId) {
              callApi.signal(currentCallId, { candidate }).catch(() => {});
            }
          },
          onConnectionStateChange: (state) => {
            console.log('[WebRTC] Caller connection state:', state);
            if (state === 'connected') {
              try {
                soundService.stopDialtone();
              } catch {}
              setCallState('connected');
            } else if (state === 'failed' || state === 'disconnected') {
              toast.error('Voice connection lost');
              endCall('connection_failed');
            }
          },
        });

        const targetId = errandPublicId || errandId;
        const res = await callApi.initiate({
          errand_id: targetId,
          offer_sdp: offerSdp,
          type: 'audio',
        });

        const callData = res.data?.call;
        currentCallId = callData?.public_id;

        if (!currentCallId) {
          throw new Error('Call creation failed on server');
        }

        setActiveCall({
          callId: currentCallId,
          errandId: targetId,
          errandTitle,
          recipientName,
          recipientAvatar,
          isCaller: true,
        });

        // 45-second timeout if no answer
        stopRingingTimeout();
        ringingTimeoutRef.current = setTimeout(() => {
          if (callStateRef.current === 'outgoing_ringing') {
            toast('No answer', { icon: '📞' });
            endCall('timeout');
          }
        }, 45000);
      } catch (err: any) {
        try {
          soundService.stopDialtone();
          soundService.playCallEndedTone();
        } catch {}
        resetCallState();
        toast.error(err.response?.data?.message || err.message || 'Could not start call');
      }
    },
    [endCall, resetCallState, stopRingingTimeout]
  );

  // Toggle microphone mute
  const toggleMute = useCallback(() => {
    setIsMuted((prev) => {
      const next = !prev;
      webrtcVoiceService.setMuted(next);
      return next;
    });
  }, []);

  // Duration timer tracking when connected
  useEffect(() => {
    if (callState === 'connected') {
      try {
        soundService.stopDialtone();
        soundService.stopRingtone();
      } catch {}
      stopDurationTimer();
      setCallDuration(0);

      durationTimerRef.current = setInterval(() => {
        setCallDuration((d) => d + 1);
      }, 1000);
    } else if (callState !== 'connecting') {
      stopDurationTimer();
    }
    return () => {
      stopDurationTimer();
    };
  }, [callState, stopDurationTimer]);

  // Resolve user id from auth store or fallback to stored user in localStorage
  const getEffectiveUserId = useCallback((): string | number | null => {
    if (user?.id) return user.id;
    if (typeof window !== 'undefined') {
      try {
        const stored = localStorage.getItem('errand_user');
        if (stored) {
          const parsed = JSON.parse(stored);
          if (parsed?.id) return parsed.id;
        }
      } catch {}
    }
    return null;
  }, [user?.id]);

  const effectiveUserId = getEffectiveUserId();

  // Central call event handler invoked from personal channel or errand channel
  const handleCallEvent = useCallback(
    async (eventName: string, rawData: any) => {
      console.log(`[CallProvider] Received call event: "${eventName}"`, rawData);

      let payload = rawData;
      if (typeof payload === 'string') {
        try {
          payload = JSON.parse(payload);
        } catch {}
      }
      if (payload?.call && typeof payload.call === 'object') {
        payload = payload.call;
      }

      if (!payload) return;

      const isCallInitiated =
        eventName === 'CallInitiated' ||
        eventName === '.CallInitiated' ||
        eventName.endsWith('CallInitiated') ||
        eventName === 'call.initiated';

      const isCallAnswered =
        eventName === 'CallAnswered' ||
        eventName === '.CallAnswered' ||
        eventName.endsWith('CallAnswered') ||
        eventName === 'call.answered';

      const isCallSignal =
        eventName === 'CallSignal' ||
        eventName === '.CallSignal' ||
        eventName.endsWith('CallSignal') ||
        eventName === 'call.signal';

      const isCallEnded =
        eventName === 'CallEnded' ||
        eventName === '.CallEnded' ||
        eventName.endsWith('CallEnded') ||
        eventName === 'call.ended';

      const isCallRejected =
        eventName === 'CallRejected' ||
        eventName === '.CallRejected' ||
        eventName.endsWith('CallRejected') ||
        eventName === 'call.rejected';

      // 1. Incoming Call Initiated
      if (isCallInitiated) {
        const callerId = payload.caller?.id;
        // Don't ring self if sender
        if (effectiveUserId && callerId && String(callerId) === String(effectiveUserId)) {
          console.log('[CallProvider] Ignoring CallInitiated: caller is self');
          return;
        }

        const callId = payload.call_id || payload.id || payload.public_id;

        // If this exact call is already ringing or active, ignore duplicate event
        if (incomingCallRef.current && incomingCallRef.current.call_id === callId) {
          console.log('[CallProvider] Ignoring duplicate CallInitiated for incoming call:', callId);
          return;
        }

        // Busy if already in another call
        if (callStateRef.current !== 'idle' && callStateRef.current !== 'incoming_ringing') {
          console.log('[CallProvider] Rejecting call as busy (state is', callStateRef.current, ')');
          if (callId) {
            callApi.reject(callId, { reason: 'busy' }).catch(() => {});
          }
          return;
        }

        const callerName =
          payload.caller?.name ||
          [payload.caller?.first_name, payload.caller?.last_name].filter(Boolean).join(' ').trim() ||
          'Errand Contact';

        const normalized: IncomingCallData = {
          call_id: payload.call_id || payload.id || payload.public_id,
          errand_id: payload.errand_id,
          errand_public_id: payload.errand_public_id,
          errand_title: payload.errand_title || 'Active Errand',
          offer_sdp: payload.offer_sdp || payload.sdp,
          type: payload.type || 'audio',
          caller: {
            id: payload.caller?.id,
            name: callerName,
            avatar: payload.caller?.avatar || payload.caller?.profile_image,
            phone: payload.caller?.phone,
          },
        };

        console.log('[CallProvider] Showing Incoming Call UI:', normalized);
        setIncomingCall(normalized);
        setCallState('incoming_ringing');

        try {
          soundService.startRingtone();
        } catch (e) {
          console.warn('[CallProvider] Autoplay ringtone prevented by browser:', e);
        }

        // 45s ringing timeout for callee
        stopRingingTimeout();
        ringingTimeoutRef.current = setTimeout(() => {
          if (callStateRef.current === 'incoming_ringing') {
            try {
              soundService.stopRingtone();
            } catch {}
            resetCallState();
          }
        }, 45000);
        return;
      }

      // 2. Call Answered by callee
      if (isCallAnswered) {
        const current = activeCallRef.current;
        const callId = payload.call_id || payload.id || payload.public_id;
        if (current && current.callId === callId && current.isCaller) {
          if ((current as any)._answerProcessed) {
            console.log('[CallProvider] Duplicate CallAnswered ignored for call:', callId);
            return;
          }
          (current as any)._answerProcessed = true;

          console.log('[CallProvider] Peer answered call, applying remote SDP');
          try {
            soundService.stopDialtone();
          } catch {}
          stopRingingTimeout();
          setCallState('connecting');

          try {
            await webrtcVoiceService.applyAnswer(payload.answer_sdp);
          } catch (err: any) {
            console.error('[CallProvider] Error applying answer SDP:', err);
            if (callStateRef.current !== 'connected') {
              toast.error('Failed to establish WebRTC connection');
              endCall('webrtc_error');
            }
          }
        }
        return;
      }

      // 3. ICE Candidate Signal relayed
      if (isCallSignal) {
        const current = activeCallRef.current || incomingCallRef.current;
        const currentCallId = (current as any)?.callId || (current as any)?.call_id;
        const callId = payload.call_id || payload.id || payload.public_id;

        if (
          currentCallId &&
          currentCallId === callId &&
          (!effectiveUserId || String(payload.sender_id) !== String(effectiveUserId))
        ) {
          if (payload.candidate) {
            try {
              await webrtcVoiceService.addIceCandidate(payload.candidate);
            } catch (err) {
              console.warn('[CallProvider] Error adding ICE candidate:', err);
            }
          }
        }
        return;
      }

      // 4. Call Ended
      if (isCallEnded) {
        const current = activeCallRef.current || incomingCallRef.current;
        const currentCallId = (current as any)?.callId || (current as any)?.call_id;
        const callId = payload.call_id || payload.id || payload.public_id;

        if (currentCallId && currentCallId === callId) {
          console.log('[CallProvider] Call ended by peer');
          try {
            soundService.stopDialtone();
            soundService.stopRingtone();
            soundService.playCallEndedTone();
          } catch {}
          setCallState('ended');
          setTimeout(() => {
            resetCallState();
          }, 1200);
        }
        return;
      }

      // 5. Call Rejected / Declined
      if (isCallRejected) {
        const current = activeCallRef.current || incomingCallRef.current;
        const currentCallId = (current as any)?.callId || (current as any)?.call_id;
        const callId = payload.call_id || payload.id || payload.public_id;

        if (currentCallId && currentCallId === callId) {
          console.log('[CallProvider] Call rejected by peer:', payload.reason);
          try {
            soundService.stopDialtone();
            soundService.stopRingtone();
            soundService.playCallEndedTone();
          } catch {}

          if (payload.reason === 'busy') {
            toast('User is currently busy on another call', { icon: '📞' });
          } else if (payload.reason === 'declined') {
            toast('Call was declined', { icon: '📞' });
          }

          resetCallState();
        }
        return;
      }
    },
    [effectiveUserId, endCall, resetCallState, stopRingingTimeout]
  );

  // Persistent Real-time Pusher listener
  useEffect(() => {
    if (!effectiveUserId) return;

    console.log(`[CallProvider] Setting up realtime listeners for user ${effectiveUserId}`);
    const unsubUser = subscribeUserChannel(effectiveUserId, handleCallEvent);
    const unsubGlobalCall = onCallEvent(handleCallEvent);

    return () => {
      console.log(`[CallProvider] Cleaning up realtime listeners for user ${effectiveUserId}`);
      if (unsubUser) unsubUser();
      unsubGlobalCall();
    };
  }, [effectiveUserId, handleCallEvent]);

  return (
    <CallContext.Provider
      value={{
        callState,
        incomingCall,
        activeCall,
        callDuration,
        isMuted,
        toggleMute,
        initiateCall,
        answerCall,
        rejectCall,
        endCall,
      }}
    >
      {children}
      <CallModal />
    </CallContext.Provider>
  );
}
