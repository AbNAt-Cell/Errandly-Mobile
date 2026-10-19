/**
 * Client-side media utilities for reliable AI image & audio intake.
 */

/**
 * Resizes and compresses an image file to a lightweight JPEG Data URL (typically 150KB - 400KB),
 * preventing massive camera upload payloads from timing out or hitting body limits.
 */
export async function compressImageToDataUrl(
  file: File,
  maxWidth = 1600,
  maxHeight = 1600,
  quality = 0.82,
): Promise<string> {
  return new Promise((resolve, reject) => {
    // If not an image or SVG/GIF that shouldn't be compressed via canvas
    if (!file.type.startsWith('image/') || file.type.includes('svg') || file.type.includes('gif')) {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(file);
      return;
    }

    const objectUrl = URL.createObjectURL(file);
    const img = new Image();

    img.onload = () => {
      URL.revokeObjectURL(objectUrl);

      let { width, height } = img;
      if (width > maxWidth || height > maxHeight) {
        if (width > height) {
          height = Math.round((height * maxWidth) / width);
          width = maxWidth;
        } else {
          width = Math.round((width * maxHeight) / height);
          maxHeight = height;
        }
      }

      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;

      const ctx = canvas.getContext('2d');
      if (!ctx) {
        // Fallback to direct FileReader
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = reject;
        reader.readAsDataURL(file);
        return;
      }

      ctx.drawImage(img, 0, 0, width, height);
      const dataUrl = canvas.toDataURL('image/jpeg', quality);
      resolve(dataUrl);
    };

    img.onerror = () => {
      URL.revokeObjectURL(objectUrl);
      // Fallback
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result as string);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    };

    img.src = objectUrl;
  });
}

/**
 * Helper to record audio via browser MediaRecorder.
 * Universally supported across Chrome, Edge, Safari iOS 14.5+, and Firefox.
 */
export class UniversalAudioRecorder {
  private mediaRecorder: MediaRecorder | null = null;
  private stream: MediaStream | null = null;
  private chunks: BlobPart[] = [];
  private mimeType = 'audio/webm';

  async start(): Promise<void> {
    if (typeof window === 'undefined' || !navigator.mediaDevices?.getUserMedia) {
      throw new Error('Audio recording is not supported in this browser.');
    }

    this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    this.chunks = [];

    // Find best supported mimeType
    const mimeTypes = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/mp4',
      'audio/aac',
      'audio/ogg',
    ];

    let chosenMime = '';
    for (const mime of mimeTypes) {
      if (MediaRecorder.isTypeSupported(mime)) {
        chosenMime = mime;
        break;
      }
    }
    this.mimeType = chosenMime || '';

    this.mediaRecorder = chosenMime
      ? new MediaRecorder(this.stream, { mimeType: chosenMime })
      : new MediaRecorder(this.stream);

    this.mediaRecorder.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) {
        this.chunks.push(e.data);
      }
    };

    this.mediaRecorder.start(250); // Slice every 250ms
  }

  isRecording(): boolean {
    return this.mediaRecorder?.state === 'recording';
  }

  async stop(): Promise<string> {
    return new Promise((resolve, reject) => {
      if (!this.mediaRecorder) {
        this.cleanup();
        reject(new Error('Recorder is not active.'));
        return;
      }

      this.mediaRecorder.onstop = () => {
        try {
          const blob = new Blob(this.chunks, {
            type: this.mimeType || this.mediaRecorder?.mimeType || 'audio/webm',
          });
          this.cleanup();

          const reader = new FileReader();
          reader.onload = () => resolve(reader.result as string);
          reader.onerror = reject;
          reader.readAsDataURL(blob);
        } catch (err) {
          this.cleanup();
          reject(err);
        }
      };

      try {
        this.mediaRecorder.stop();
      } catch (err) {
        this.cleanup();
        reject(err);
      }
    });
  }

  cancel(): void {
    try {
      if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
        this.mediaRecorder.stop();
      }
    } catch {
      // ignore
    }
    this.cleanup();
  }

  private cleanup(): void {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop());
      this.stream = null;
    }
    this.mediaRecorder = null;
    this.chunks = [];
  }
}
