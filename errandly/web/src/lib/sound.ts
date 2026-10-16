// Audio alert utility for Errandly Web
// Uses HTML5 Audio with seamless fallback to Web Audio API oscillator synthesis.

class SoundService {
  private audioContext: AudioContext | null = null;

  private getAudioContext(): AudioContext | null {
    if (typeof window === 'undefined') return null;
    if (!this.audioContext) {
      const AudioCtx = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
      if (AudioCtx) {
        this.audioContext = new AudioCtx();
      }
    }
    if (this.audioContext && this.audioContext.state === 'suspended') {
      this.audioContext.resume().catch(() => {});
    }
    return this.audioContext;
  }

  private tryPlayFile(src: string): Promise<boolean> {
    return new Promise((resolve) => {
      try {
        const audio = new Audio(src);
        audio.volume = 0.85;
        const playPromise = audio.play();
        if (playPromise !== undefined) {
          playPromise
            .then(() => resolve(true))
            .catch(() => resolve(false));
        } else {
          resolve(true);
        }
      } catch {
        resolve(false);
      }
    });
  }

  // Synthesize Admin Chime (C5 - E5 - G5 - C6)
  private synthesizeAdminOrder(): void {
    const ctx = this.getAudioContext();
    if (!ctx) return;

    const notes = [523.25, 659.25, 783.99, 1046.5];
    const startTime = ctx.currentTime;

    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, startTime + idx * 0.1);

      gain.gain.setValueAtTime(0.001, startTime + idx * 0.1);
      gain.gain.exponentialRampToValueAtTime(0.35, startTime + idx * 0.1 + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + idx * 0.1 + (idx === 3 ? 0.6 : 0.18));

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime + idx * 0.1);
      osc.stop(startTime + idx * 0.1 + (idx === 3 ? 0.65 : 0.2));
    });
  }

  // Synthesize Runner Dispatch Alert (Urgent two-tone bursts)
  private synthesizeRunnerAlert(): void {
    const ctx = this.getAudioContext();
    if (!ctx) return;

    const startTime = ctx.currentTime;
    const pattern = [
      { f: 880, d: 0.12, pause: 0 },
      { f: 1175, d: 0.18, pause: 0.08 },
      { f: 880, d: 0.12, pause: 0 },
      { f: 1175, d: 0.18, pause: 0.08 },
      { f: 880, d: 0.12, pause: 0 },
      { f: 1397, d: 0.35, pause: 0 },
    ];

    let cursor = startTime;
    pattern.forEach((note) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sawtooth';
      osc.frequency.setValueAtTime(note.f, cursor);

      gain.gain.setValueAtTime(0.001, cursor);
      gain.gain.linearRampToValueAtTime(0.3, cursor + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.001, cursor + note.d);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(cursor);
      osc.stop(cursor + note.d);
      cursor += note.d + note.pause;
    });
  }

  // Synthesize Customer Accepted (Uplifting ascending major chord)
  private synthesizeErrandAccepted(): void {
    const ctx = this.getAudioContext();
    if (!ctx) return;

    const notes = [587.33, 739.99, 880.0, 1174.66];
    const startTime = ctx.currentTime;

    notes.forEach((freq, idx) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, startTime + idx * 0.08);

      gain.gain.setValueAtTime(0.001, startTime + idx * 0.08);
      gain.gain.linearRampToValueAtTime(0.3, startTime + idx * 0.08 + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.001, startTime + idx * 0.08 + (idx === 3 ? 0.7 : 0.25));

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start(startTime + idx * 0.08);
      osc.stop(startTime + idx * 0.08 + (idx === 3 ? 0.75 : 0.28));
    });
  }

  /**
   * Play Admin sound when an errand / order is placed.
   */
  public async playAdminOrderAlert(): Promise<void> {
    const played = await this.tryPlayFile('/sounds/admin_order_alert.wav');
    if (!played) {
      this.synthesizeAdminOrder();
    }
  }

  /**
   * Play Runner alert sound when a new errand is offered.
   */
  public async playRunnerAlert(): Promise<void> {
    const played = await this.tryPlayFile('/sounds/errand_alert.wav');
    if (!played) {
      this.synthesizeRunnerAlert();
    }
  }

  /**
   * Play Customer chime when an errand is accepted by a runner.
   */
  public async playErrandAccepted(): Promise<void> {
    const played = await this.tryPlayFile('/sounds/errand_accepted.wav');
    if (!played) {
      this.synthesizeErrandAccepted();
    }
  }
}

export const soundService = new SoundService();
