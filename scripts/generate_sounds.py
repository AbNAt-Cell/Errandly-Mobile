import math
import struct
import wave
import os

def create_tone_pcm(sample_rate, duration, freq, volume=0.5, fade_in=0.01, fade_out=0.03):
    num_samples = int(sample_rate * duration)
    samples = []
    for i in range(num_samples):
        t = i / sample_rate
        # Envelope
        env = 1.0
        if t < fade_in:
            env = t / fade_in
        elif t > (duration - fade_out):
            env = max(0.0, (duration - t) / fade_out)
        
        # Sine wave with gentle 2nd harmonic
        val = (math.sin(2 * math.pi * freq * t) * 0.85 + math.sin(2 * math.pi * freq * 2 * t) * 0.15) * env * volume
        sample = int(max(-32768, min(32767, val * 32767)))
        samples.append(sample)
    return samples

def create_silence(sample_rate, duration):
    return [0] * int(sample_rate * duration)

def save_wav(filepath, samples, sample_rate=44100):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as wav_file:
        wav_file.setnchannels(1)  # Mono
        wav_file.setsampwidth(2)  # 16-bit
        wav_file.setframerate(sample_rate)
        raw_data = struct.pack(f'<{len(samples)}h', *samples)
        wav_file.writeframes(raw_data)
    print(f"Generated {filepath} ({len(samples)/sample_rate:.2f}s)")

sample_rate = 44100

# 1. Errand Alert (Runner Dispatch Alarm)
# Punchy, urgent two-tone alternating chime repeated 3 times
samples_alert = []
for _ in range(2):
    samples_alert += create_tone_pcm(sample_rate, 0.12, 880, volume=0.7)
    samples_alert += create_tone_pcm(sample_rate, 0.18, 1175, volume=0.85)
    samples_alert += create_silence(sample_rate, 0.08)
samples_alert += create_tone_pcm(sample_rate, 0.12, 880, volume=0.7)
samples_alert += create_tone_pcm(sample_rate, 0.35, 1397, volume=0.9, fade_out=0.15)

# 2. Admin Order Alert (Crisp multi-tone chime)
samples_admin = []
samples_admin += create_tone_pcm(sample_rate, 0.09, 523, volume=0.6) # C5
samples_admin += create_tone_pcm(sample_rate, 0.09, 659, volume=0.7) # E5
samples_admin += create_tone_pcm(sample_rate, 0.10, 784, volume=0.8) # G5
samples_admin += create_tone_pcm(sample_rate, 0.60, 1046, volume=0.9, fade_out=0.35) # C6

# 3. Errand Accepted (Customer Celebration Chime)
samples_accepted = []
samples_accepted += create_tone_pcm(sample_rate, 0.09, 587, volume=0.6) # D5
samples_accepted += create_tone_pcm(sample_rate, 0.09, 740, volume=0.7) # F#5
samples_accepted += create_tone_pcm(sample_rate, 0.10, 880, volume=0.8) # A5
samples_accepted += create_tone_pcm(sample_rate, 0.65, 1175, volume=0.9, fade_out=0.4) # D6

# Target directories
targets = [
    # Web public sounds
    r"c:\Users\Keyna\Errandly-Mobile\errandly\web\public\sounds\errand_alert.wav",
    r"c:\Users\Keyna\Errandly-Mobile\errandly\web\public\sounds\admin_order_alert.wav",
    r"c:\Users\Keyna\Errandly-Mobile\errandly\web\public\sounds\errand_accepted.wav",
    
    # Also in Errandly-web if present
    r"c:\Users\Keyna\Errandly-web\public\sounds\errand_alert.wav",
    r"c:\Users\Keyna\Errandly-web\public\sounds\admin_order_alert.wav",
    r"c:\Users\Keyna\Errandly-web\public\sounds\errand_accepted.wav",

    # Mobile assets sounds
    r"c:\Users\Keyna\Errandly-Mobile\errandly\mobile\assets\sounds\errand_alert.wav",
    r"c:\Users\Keyna\Errandly-Mobile\errandly\mobile\assets\sounds\admin_order_alert.wav",
    r"c:\Users\Keyna\Errandly-Mobile\errandly\mobile\assets\sounds\errand_accepted.wav",

    # Android res/raw (for notification sound)
    r"c:\Users\Keyna\Errandly-Mobile\errandly\mobile\android\app\src\main\res\raw\errand_alert.wav",
    r"c:\Users\Keyna\Errandly-Mobile\errandly\mobile\android\app\src\main\res\raw\errand_accepted.wav",
]

for p in targets:
    if "errand_alert" in p:
        save_wav(p, samples_alert, sample_rate)
    elif "admin_order_alert" in p:
        save_wav(p, samples_admin, sample_rate)
    elif "errand_accepted" in p:
        save_wav(p, samples_accepted, sample_rate)

print("All audio files generated successfully!")
