// WebRTC Audio Peer Connection Service for Errandly VoIP Calls
// Uses standard WebRTC API with Google STUN servers and robust candidate buffering

export interface WebRtcCallbacks {
  onIceCandidate: (candidate: RTCIceCandidate) => void;
  onConnectionStateChange: (state: RTCPeerConnectionState) => void;
  onRemoteStream?: (stream: MediaStream) => void;
  onError?: (error: Error) => void;
}

const RTC_CONFIG: RTCConfiguration = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    { urls: 'stun:stun2.l.google.com:19302' },
    { urls: 'stun:stun3.l.google.com:19302' },
  ],
  iceCandidatePoolSize: 10,
};

export class WebRtcVoiceService {
  private peer: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private remoteStream: MediaStream | null = null;
  private remoteAudio: HTMLAudioElement | null = null;
  private pendingCandidates: RTCIceCandidateInit[] = [];
  private callbacks: WebRtcCallbacks | null = null;
  private isMuted: boolean = false;

  constructor() {
    if (typeof window !== 'undefined') {
      this.remoteAudio = new Audio();
      this.remoteAudio.autoplay = true;
      (this.remoteAudio as any).playsInline = true;
    }
  }

  /**
   * Acquire local microphone audio stream with optimal voice settings.
   */
  public async acquireMicrophone(): Promise<MediaStream> {
    if (this.localStream) {
      return this.localStream;
    }

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: {
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        },
        video: false,
      });

      this.localStream = stream;
      return stream;
    } catch (err: any) {
      throw new Error(
        err?.name === 'NotAllowedError'
          ? 'Microphone permission was denied. Please allow microphone access to make voice calls.'
          : 'Could not access microphone.'
      );
    }
  }

  /**
   * Initialize a new RTCPeerConnection and attach event handlers.
   */
  private createPeerConnection(callbacks: WebRtcCallbacks): RTCPeerConnection {
    this.cleanupPeer();
    this.callbacks = callbacks;
    this.pendingCandidates = [];

    const pc = new RTCPeerConnection(RTC_CONFIG);

    pc.onicecandidate = (event) => {
      if (event.candidate && this.callbacks?.onIceCandidate) {
        this.callbacks.onIceCandidate(event.candidate);
      }
    };

    pc.onconnectionstatechange = () => {
      if (this.callbacks?.onConnectionStateChange) {
        this.callbacks.onConnectionStateChange(pc.connectionState);
      }
    };

    pc.ontrack = (event) => {
      const stream = event.streams[0] || new MediaStream([event.track]);
      this.remoteStream = stream;

      if (this.remoteAudio) {
        this.remoteAudio.srcObject = stream;
        this.remoteAudio.play().catch(() => {
          // In case of browser autoplay policy, will play on user interaction
        });
      }

      if (this.callbacks?.onRemoteStream) {
        this.callbacks.onRemoteStream(stream);
      }
    };

    // Attach local tracks if available
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach((track) => {
        pc.addTrack(track, this.localStream!);
      });
    }

    this.peer = pc;
    return pc;
  }

  /**
   * Normalize an SDP string to ensure strict RFC 4566 compliance.
   * Every SDP line must end with CRLF (\r\n), and the document must have a trailing CRLF.
   * Stripping or missing trailing CRLF causes RTCPeerConnection.setRemoteDescription
   * to fail with 'Invalid SDP line' on the final attribute.
   */
  public static normalizeSdp(sdp: string): string {
    if (!sdp || typeof sdp !== 'string') return '';
    const lines = sdp
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0);
    return lines.join('\r\n') + '\r\n';
  }

  /**
   * Caller: Create WebRTC Offer SDP
   */
  public async createOffer(callbacks: WebRtcCallbacks): Promise<string> {
    await this.acquireMicrophone();
    const pc = this.createPeerConnection(callbacks);

    const offer = await pc.createOffer({
      offerToReceiveAudio: true,
      offerToReceiveVideo: false,
    });

    await pc.setLocalDescription(offer);
    const rawSdp = pc.localDescription?.sdp || offer.sdp || '';
    return WebRtcVoiceService.normalizeSdp(rawSdp);
  }

  /**
   * Callee: Handle incoming WebRTC Offer SDP and create Answer SDP
   */
  public async handleIncomingOffer(offerSdp: string, callbacks: WebRtcCallbacks): Promise<string> {
    await this.acquireMicrophone();
    const pc = this.createPeerConnection(callbacks);

    const cleanOffer = WebRtcVoiceService.normalizeSdp(offerSdp);
    const rtcOffer = new RTCSessionDescription({
      type: 'offer',
      sdp: cleanOffer,
    });

    await pc.setRemoteDescription(rtcOffer);
    await this.flushPendingCandidates();

    const answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    const rawAnswer = pc.localDescription?.sdp || answer.sdp || '';
    return WebRtcVoiceService.normalizeSdp(rawAnswer);
  }

  private processedCandidates = new Set<string>();

  /**
   * Caller: Apply Answer SDP received from callee
   */
  public async applyAnswer(answerSdp: string): Promise<void> {
    if (!this.peer) {
      throw new Error('Peer connection not initialized');
    }

    // Idempotency: WebRTC signaling state check.
    // If answer is already applied, peer connection is already in 'stable' state.
    // Calling setRemoteDescription with an answer in 'stable' state throws InvalidStateError.
    if (this.peer.signalingState === 'stable') {
      console.log('[WebRTC] Answer already applied (signalingState is stable). Ignoring duplicate answer.');
      return;
    }

    if (this.peer.signalingState !== 'have-local-offer') {
      console.warn(`[WebRTC] Cannot apply answer in signalingState "${this.peer.signalingState}". Ignoring.`);
      return;
    }

    const cleanAnswer = WebRtcVoiceService.normalizeSdp(answerSdp);
    const rtcAnswer = new RTCSessionDescription({
      type: 'answer',
      sdp: cleanAnswer,
    });

    await this.peer.setRemoteDescription(rtcAnswer);
    await this.flushPendingCandidates();
  }

  /**
   * Add ICE candidate received from remote peer.
   * If remote description is not set yet, buffer candidate until ready.
   */
  public async addIceCandidate(candidateInit: RTCIceCandidateInit | any): Promise<void> {
    if (!candidateInit) return;

    const candKey =
      typeof candidateInit === 'string'
        ? candidateInit
        : candidateInit.candidate || JSON.stringify(candidateInit);

    if (this.processedCandidates.has(candKey)) {
      return;
    }
    this.processedCandidates.add(candKey);

    if (!this.peer || !this.peer.remoteDescription) {
      this.pendingCandidates.push(candidateInit);
      return;
    }

    try {
      const candidate = new RTCIceCandidate(candidateInit);
      await this.peer.addIceCandidate(candidate);
    } catch {
      // Ignore non-fatal ICE errors
    }
  }

  /**
   * Flush any buffered ICE candidates once remoteDescription is set.
   */
  private async flushPendingCandidates(): Promise<void> {
    if (!this.peer || !this.peer.remoteDescription) return;

    while (this.pendingCandidates.length > 0) {
      const cand = this.pendingCandidates.shift();
      if (cand) {
        try {
          await this.peer.addIceCandidate(new RTCIceCandidate(cand));
        } catch {
          // Ignore
        }
      }
    }
  }

  /**
   * Toggle microphone mute.
   */
  public setMuted(muted: boolean): boolean {
    this.isMuted = muted;
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach((track) => {
        track.enabled = !muted;
      });
    }
    return this.isMuted;
  }

  /**
   * Set remote audio volume (e.g., 0.0 to 1.0).
   */
  public setVolume(volume: number): void {
    if (this.remoteAudio) {
      this.remoteAudio.volume = Math.max(0, Math.min(1, volume));
    }
  }

  /**
   * Cleanup peer connection only.
   */
  private cleanupPeer(): void {
    if (this.peer) {
      try {
        this.peer.onicecandidate = null;
        this.peer.onconnectionstatechange = null;
        this.peer.ontrack = null;
        this.peer.close();
      } catch {
        // Ignore
      }
      this.peer = null;
    }
    this.pendingCandidates = [];
    this.processedCandidates.clear();
  }

  /**
   * Clean up all audio tracks and peer connections when call terminates.
   */
  public cleanup(): void {
    this.cleanupPeer();

    if (this.localStream) {
      this.localStream.getTracks().forEach((t) => {
        try {
          t.stop();
        } catch {
          // Ignore
        }
      });
      this.localStream = null;
    }

    if (this.remoteAudio) {
      try {
        this.remoteAudio.pause();
        this.remoteAudio.srcObject = null;
      } catch {
        // Ignore
      }
    }

    this.remoteStream = null;
    this.callbacks = null;
    this.isMuted = false;
  }
}

export const webrtcVoiceService = new WebRtcVoiceService();
