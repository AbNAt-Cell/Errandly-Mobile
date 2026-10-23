'use client';

import React, { useState } from 'react';
import {
  Phone,
  PhoneOff,
  Mic,
  MicOff,
  Volume2,
  VolumeX,
  Minimize2,
  Maximize2,
  Radio,
  User as UserIcon,
} from 'lucide-react';
import { useCall } from '@/components/providers/CallProvider';

export default function CallModal() {
  const {
    callState,
    incomingCall,
    activeCall,
    callDuration,
    isMuted,
    toggleMute,
    answerCall,
    rejectCall,
    endCall,
  } = useCall();

  const [isMinimized, setIsMinimized] = useState(false);
  const [isSpeakerMuted, setIsSpeakerMuted] = useState(false);

  const formatDuration = (totalSecs: number) => {
    const mins = Math.floor(totalSecs / 60);
    const secs = totalSecs % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  // 1. Incoming Call Dialog / Notification
  if (callState === 'incoming_ringing' && incomingCall) {
    const callerName = incomingCall.caller?.name || 'Errand Contact';
    const callerAvatar = incomingCall.caller?.avatar;
    const errandTitle = incomingCall.errand_title || 'Active Errand';

    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-in fade-in duration-200">
        <div className="w-full max-w-sm bg-[#121317] border border-white/10 rounded-3xl p-6 shadow-2xl flex flex-col items-center text-center relative overflow-hidden">
          {/* Pulsing ring background glow */}
          <div className="absolute top-1/3 w-40 h-40 bg-emerald-500/20 rounded-full blur-3xl animate-pulse pointer-events-none" />

          {/* Caller Avatar with animated radar ripples */}
          <div className="relative mb-4 mt-2">
            <span className="absolute -inset-2 rounded-full border-2 border-emerald-500/40 animate-ping" />
            <span className="absolute -inset-5 rounded-full border border-emerald-500/20 animate-pulse" />
            <div className="relative w-24 h-24 rounded-full overflow-hidden border-2 border-emerald-500 bg-[#1A1B22] flex items-center justify-center shadow-lg">
              {callerAvatar ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={callerAvatar}
                  alt={callerName}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              ) : (
                <UserIcon className="w-12 h-12 text-gray-400" />
              )}
            </div>
          </div>

          {/* Caller Details */}
          <h2 className="text-xl font-bold text-white mb-1">{callerName}</h2>
          <p className="text-xs font-medium text-emerald-400 flex items-center gap-1.5 mb-2">
            <Radio className="w-3.5 h-3.5 animate-pulse" /> Incoming Voice Call
          </p>
          <div className="px-3 py-1 bg-white/5 border border-white/5 rounded-full text-xs text-gray-300 max-w-[220px] truncate mb-6">
            Errand: {errandTitle}
          </div>

          {/* Accept / Decline Action Buttons */}
          <div className="flex items-center justify-center gap-8 w-full">
            {/* Decline Button */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                onClick={() => rejectCall('declined')}
                className="w-14 h-14 rounded-full bg-red-600 hover:bg-red-500 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-red-600/30 transition duration-150"
                title="Decline Call"
              >
                <PhoneOff className="w-6 h-6" />
              </button>
              <span className="text-xs text-gray-400">Decline</span>
            </div>

            {/* Accept Button */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                onClick={answerCall}
                className="w-14 h-14 rounded-full bg-emerald-500 hover:bg-emerald-400 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-emerald-500/30 transition duration-150 animate-bounce"
                title="Accept Call"
              >
                <Phone className="w-6 h-6" />
              </button>
              <span className="text-xs text-gray-400">Accept</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // 2. Outgoing Ringing / Connecting / Active Call HUD
  if (
    callState === 'outgoing_ringing' ||
    callState === 'connecting' ||
    callState === 'connected' ||
    callState === 'ended'
  ) {
    const peerName = activeCall?.recipientName || 'Errand Contact';
    const peerAvatar = activeCall?.recipientAvatar;
    const errandTitle = activeCall?.errandTitle || 'Errand Call';

    // Minimized Floating Pill
    if (isMinimized) {
      return (
        <aside 
          aria-label="Active Call Mini HUD"
          className="fixed bottom-20 right-4 sm:bottom-6 sm:right-6 z-[9999] bg-[#121317]/95 border border-emerald-500/40 rounded-2xl p-3 shadow-2xl backdrop-blur-md flex items-center gap-3 animate-in slide-in-from-bottom-4 duration-200"
        >
          <div className="relative w-10 h-10 rounded-full overflow-hidden border border-emerald-500 bg-[#1A1B22] flex-shrink-0 flex items-center justify-center">
            {peerAvatar ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={peerAvatar}
                alt={peerName}
                className="w-full h-full object-cover"
                onError={(e) => {
                  (e.target as HTMLElement).style.display = 'none';
                }}
              />
            ) : (
              <UserIcon className="w-5 h-5 text-gray-400" />
            )}
            {callState === 'connected' && (
              <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-emerald-400 border-2 border-[#121317] rounded-full" />
            )}
          </div>

          <div className="flex flex-col">
            <span className="text-xs font-semibold text-white max-w-[120px] truncate">{peerName}</span>
            <span className="text-[11px] text-emerald-400 font-mono">
              {callState === 'connected'
                ? formatDuration(callDuration)
                : callState === 'outgoing_ringing'
                ? 'Ringing...'
                : 'Connecting...'}
            </span>
          </div>

          <button
            type="button"
            onClick={toggleMute}
            className={`p-2 rounded-xl transition ${
              isMuted ? 'bg-red-500/20 text-red-400' : 'bg-white/5 hover:bg-white/10 text-gray-300'
            }`}
            title={isMuted ? 'Unmute' : 'Mute'}
          >
            {isMuted ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
          </button>

          <button
            type="button"
            onClick={() => endCall('hangup')}
            className="p-2 rounded-xl bg-red-600 hover:bg-red-500 text-white shadow-md transition"
            title="End Call"
          >
            <PhoneOff className="w-4 h-4" />
          </button>

          <button
            type="button"
            onClick={() => setIsMinimized(false)}
            className="p-1.5 rounded-lg text-gray-400 hover:text-white hover:bg-white/5 transition"
            title="Expand"
          >
            <Maximize2 className="w-4 h-4" />
          </button>
        </aside>
      );
    }

    // Full Call Modal HUD
    return (
      <div className="fixed inset-0 z-[9999] flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-in fade-in duration-200">
        <div className="w-full max-w-sm bg-[#121317] border border-white/10 rounded-3xl p-6 shadow-2xl flex flex-col items-center text-center relative overflow-hidden">
          {/* Top Control Bar: Minimize */}
          <div className="w-full flex items-center justify-between mb-4">
            <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/5 border border-white/5 text-[11px] text-gray-300 max-w-[200px] truncate">
              {errandTitle}
            </div>
            <button
              type="button"
              onClick={() => setIsMinimized(true)}
              className="p-1.5 rounded-xl text-gray-400 hover:text-white hover:bg-white/10 transition"
              title="Minimize call"
            >
              <Minimize2 className="w-4 h-4" />
            </button>
          </div>

          {/* Caller / Peer Avatar */}
          <div className="relative mb-4 mt-2">
            {callState === 'connected' && (
              <span className="absolute -inset-3 rounded-full border border-emerald-500/30 animate-pulse pointer-events-none" />
            )}
            <div className="relative w-24 h-24 rounded-full overflow-hidden border-2 border-emerald-500/80 bg-[#1A1B22] flex items-center justify-center shadow-lg">
              {peerAvatar ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img
                  src={peerAvatar}
                  alt={peerName}
                  className="w-full h-full object-cover"
                  onError={(e) => {
                    (e.target as HTMLElement).style.display = 'none';
                  }}
                />
              ) : (
                <UserIcon className="w-12 h-12 text-gray-400" />
              )}
            </div>
          </div>

          {/* Peer Info & Status */}
          <h2 className="text-xl font-bold text-white mb-1">{peerName}</h2>
          <div className="mb-6">
            {callState === 'connected' ? (
              <span className="text-base font-mono font-bold text-emerald-400">
                {formatDuration(callDuration)}
              </span>
            ) : callState === 'outgoing_ringing' ? (
              <span className="text-xs font-medium text-amber-400 flex items-center gap-1.5 justify-center">
                <Radio className="w-3.5 h-3.5 animate-pulse" /> Ringing...
              </span>
            ) : callState === 'connecting' ? (
              <span className="text-xs font-medium text-sky-400 flex items-center gap-1.5 justify-center">
                <Radio className="w-3.5 h-3.5 animate-pulse" /> Connecting WebRTC audio...
              </span>
            ) : (
              <span className="text-xs font-medium text-gray-400">Call Ended</span>
            )}
          </div>

          {/* Controls Bar: Mute, Volume/Speaker, End Call */}
          <div className="flex items-center justify-center gap-6 w-full pt-2 border-t border-white/5">
            {/* Mic Mute Toggle */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                onClick={toggleMute}
                className={`w-12 h-12 rounded-full flex items-center justify-center transition active:scale-95 ${
                  isMuted
                    ? 'bg-red-500/20 text-red-400 border border-red-500/30'
                    : 'bg-white/10 hover:bg-white/20 text-white border border-white/10'
                }`}
                title={isMuted ? 'Unmute Microphone' : 'Mute Microphone'}
              >
                {isMuted ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
              </button>
              <span className="text-[11px] text-gray-400">{isMuted ? 'Unmute' : 'Mute'}</span>
            </div>

            {/* Hangup Button */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                onClick={() => endCall('hangup')}
                className="w-14 h-14 rounded-full bg-red-600 hover:bg-red-500 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-red-600/40 transition duration-150"
                title="Hang Up"
              >
                <PhoneOff className="w-6 h-6" />
              </button>
              <span className="text-[11px] text-gray-400">End</span>
            </div>

            {/* Speaker / Volume Toggle */}
            <div className="flex flex-col items-center gap-1.5">
              <button
                type="button"
                onClick={() => {
                  const next = !isSpeakerMuted;
                  setIsSpeakerMuted(next);
                  // Volume control
                  import('@/lib/webrtc').then(({ webrtcVoiceService }) => {
                    webrtcVoiceService.setVolume(next ? 0 : 1);
                  });
                }}
                className={`w-12 h-12 rounded-full flex items-center justify-center transition active:scale-95 ${
                  isSpeakerMuted
                    ? 'bg-amber-500/20 text-amber-400 border border-amber-500/30'
                    : 'bg-white/10 hover:bg-white/20 text-white border border-white/10'
                }`}
                title={isSpeakerMuted ? 'Unmute Speaker' : 'Mute Speaker'}
              >
                {isSpeakerMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
              </button>
              <span className="text-[11px] text-gray-400">{isSpeakerMuted ? 'Unmute' : 'Speaker'}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return null;
}
