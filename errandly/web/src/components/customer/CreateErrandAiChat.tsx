'use client';

import { useEffect, useRef, useState } from 'react';
import { Loader2, Mic, MicOff, Send, Volume2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { aiApi } from '@/lib/api';
import type { ErrandDraft } from '@/lib/errandDraft';

type Message = { role: 'user' | 'assistant'; text: string };

type Props = {
  onDraft: (draft: ErrandDraft, clarifyingQuestions?: string[]) => void;
};

function getSpeechRecognitionCtor(): (typeof SpeechRecognition) | null {
  if (typeof window === 'undefined') return null;
  return window.SpeechRecognition ?? window.webkitSpeechRecognition ?? null;
}

function voiceErrorMessage(error: string): string | null {
  switch (error) {
    case 'not-allowed':
    case 'service-not-allowed':
      return 'Microphone access was blocked. Allow the mic for this site in browser settings, then try again.';
    case 'audio-capture':
      return 'No microphone found. Plug in a mic or check Windows sound settings.';
    case 'network':
      return 'Voice recognition needs internet (Chrome uses an online service). Check your connection.';
    case 'language-not-supported':
      return 'Speech language not supported. Switching to English — try again.';
    case 'no-speech':
      return 'Did not hear anything. Hold the mic closer and speak clearly.';
    case 'aborted':
      return null;
    default:
      return 'Voice capture failed. Try Chrome or Edge, or type your errand instead.';
  }
}

export default function CreateErrandAiChat({ onDraft }: Props) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      text: 'Tell me what you need done — you can type or tap the mic. I will fill the form for your runner with clear instructions.',
    },
  ]);
  const [input, setInput] = useState('');
  const [sessionId, setSessionId] = useState<string>();
  const [loading, setLoading] = useState(false);
  const [listening, setListening] = useState(false);
  const [voiceOut, setVoiceOut] = useState(false);
  const [voiceSupported, setVoiceSupported] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);
  const recognitionRef = useRef<(SpeechRecognition | null)>(null);
  const startingRef = useRef(false);

  useEffect(() => {
    setVoiceSupported(getSpeechRecognitionCtor() !== null);
  }, []);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  useEffect(() => {
    return () => {
      recognitionRef.current?.abort();
      recognitionRef.current = null;
    };
  }, []);

  const speak = (text: string) => {
    if (!voiceOut || typeof window === 'undefined' || !window.speechSynthesis) return;
    window.speechSynthesis.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = 'en-US';
    window.speechSynthesis.speak(utterance);
  };

  const send = async (overrideText?: string) => {
    const text = (overrideText ?? input).trim();
    if (!text || loading) return;

    setInput('');
    setMessages((m) => [...m, { role: 'user', text }]);
    setLoading(true);

    try {
      const { data } = await aiApi.chat({
        message: text,
        session_id: sessionId,
        context: { intent: 'create_errand' },
      });

      if (data.session_id) setSessionId(data.session_id);

      const reply = data.reply || 'Got it.';
      setMessages((m) => [...m, { role: 'assistant', text: reply }]);
      speak(reply);

      if (data.draft) {
        onDraft(data.draft as ErrandDraft, data.draft.clarifying_questions);
        toast.success('Form updated for your runner — review the fields below.');
      }
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        'Something went wrong.';
      setMessages((m) => [...m, { role: 'assistant', text: msg }]);
    } finally {
      setLoading(false);
    }
  };

  const stopListening = () => {
    startingRef.current = false;
    setListening(false);
    try {
      recognitionRef.current?.stop();
    } catch {
      recognitionRef.current?.abort();
    }
  };

  const startListening = async () => {
    const Ctor = getSpeechRecognitionCtor();
    if (!Ctor) {
      toast.error('Voice input needs Chrome or Edge. You can type your errand instead.');
      return;
    }

    if (listening || startingRef.current) {
      stopListening();
      return;
    }

    startingRef.current = true;

    try {
      if (navigator.mediaDevices?.getUserMedia) {
        const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
        stream.getTracks().forEach((track) => track.stop());
      }
    } catch {
      startingRef.current = false;
      toast.error(
        'Microphone permission denied. Click the lock icon in the address bar and allow microphone access.',
      );
      return;
    }

    recognitionRef.current?.abort();

    const rec = new Ctor();
    recognitionRef.current = rec;
    rec.continuous = false;
    rec.interimResults = true;
    rec.maxAlternatives = 1;
    rec.lang = 'en-US';

    rec.onstart = () => {
      startingRef.current = false;
      setListening(true);
    };

    rec.onresult = (event: SpeechRecognitionEvent) => {
      let transcript = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        transcript += event.results[i][0]?.transcript ?? '';
      }
      if (transcript.trim()) {
        setInput((prev) => {
          const next = transcript.trim();
          if (!prev) return next;
          if (prev.endsWith(next) || next.startsWith(prev)) return next;
          return `${prev} ${next}`;
        });
      }
    };

    rec.onerror = (event: SpeechRecognitionErrorEvent) => {
      startingRef.current = false;
      setListening(false);
      const msg = voiceErrorMessage(event.error);
      if (msg) toast.error(msg);
    };

    rec.onend = () => {
      startingRef.current = false;
      setListening(false);
      recognitionRef.current = null;
    };

    try {
      rec.start();
    } catch {
      startingRef.current = false;
      setListening(false);
      toast.error('Could not start voice capture. Wait a moment and tap the mic again.');
    }
  };

  return (
    <div className="rounded-2xl border-2 border-[#FF6B00]/25 bg-gradient-to-b from-orange-50/80 to-white overflow-hidden flex flex-col min-h-[320px] max-h-[420px]">
      <div className="px-4 py-2 border-b border-orange-100 flex items-center justify-between bg-white/80">
        <div>
          <p className="text-sm font-semibold text-[#0A1628]">Talk through your errand</p>
          {!voiceSupported && (
            <p className="text-xs text-amber-700">Voice works best in Chrome or Edge on desktop.</p>
          )}
        </div>
        <button
          type="button"
          onClick={() => setVoiceOut((v) => !v)}
          className={`text-xs px-2 py-1 rounded-lg flex items-center gap-1 shrink-0 ${
            voiceOut ? 'bg-[#FF6B00] text-white' : 'bg-gray-100 text-gray-600'
          }`}
          title="Read replies aloud"
        >
          <Volume2 className="w-3.5 h-3.5" />
          {voiceOut ? 'Voice on' : 'Voice off'}
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-3 py-3 space-y-2">
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`max-w-[90%] rounded-2xl px-3 py-2 text-sm ${
              msg.role === 'user' ? 'ml-auto bg-[#FF6B00] text-white' : 'bg-white border border-gray-100 text-gray-800'
            }`}
          >
            {msg.text}
          </div>
        ))}
        {loading && (
          <div className="flex items-center gap-2 text-gray-400 text-xs">
            <Loader2 className="w-4 h-4 animate-spin" />
            Thinking…
          </div>
        )}
        {listening && (
          <p className="text-xs text-[#FF6B00] text-center animate-pulse">Listening… speak now</p>
        )}
        <div ref={bottomRef} />
      </div>

      <div
        className="p-3 border-t border-orange-100 bg-white flex gap-2"
        role="group"
        aria-label="Chat input"
      >
        <button
          type="button"
          onClick={startListening}
          disabled={loading}
          className={`p-3 rounded-xl border ${
            listening ? 'border-red-400 bg-red-50 text-red-600' : 'border-gray-200 text-gray-600'
          } disabled:opacity-50`}
          aria-label={listening ? 'Stop listening' : 'Start voice input'}
          title={listening ? 'Stop' : 'Speak your errand'}
        >
          {listening ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
        </button>
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
              e.preventDefault();
              send();
            }
          }}
          placeholder="e.g. Buy diapers from Shoprite and deliver to my house in Ewet…"
          className="flex-1 rounded-xl border border-gray-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00]/30"
          disabled={loading}
        />
        <button
          type="button"
          onClick={() => send()}
          disabled={loading || !input.trim()}
          className="p-3 rounded-xl bg-[#FF6B00] text-white disabled:opacity-50"
          aria-label="Send message"
        >
          <Send className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
