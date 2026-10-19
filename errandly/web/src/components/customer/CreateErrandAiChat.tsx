'use client';

import { useEffect, useRef, useState } from 'react';
import { Loader2, Mic, MicOff, Send, Volume2, Sparkles, CheckCircle2, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import { aiApi } from '@/lib/api';
import type { ErrandDraft } from '@/lib/errandDraft';
import { UniversalAudioRecorder } from '@/lib/mediaUtils';

type Message = {
  role: 'user' | 'assistant';
  text: string;
  draft?: ErrandDraft;
};

type Props = {
  onDraft: (draft: ErrandDraft, clarifyingQuestions?: string[]) => void;
};

function getSpeechRecognitionCtor(): (typeof SpeechRecognition) | null {
  if (typeof window === 'undefined') return null;
  return window.SpeechRecognition ?? window.webkitSpeechRecognition ?? null;
}

export default function CreateErrandAiChat({ onDraft }: Props) {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      text: 'Tell me what you need done — speak into the mic or type here. I will organize everything for your runner.',
    },
  ]);
  const [input, setInput] = useState('');
  const [sessionId, setSessionId] = useState<string>();
  const [loading, setLoading] = useState(false);
  const [isRecording, setIsRecording] = useState(false);
  const [recordSeconds, setRecordSeconds] = useState(0);
  const [voiceOut, setVoiceOut] = useState(false);
  const [latestDraft, setLatestDraft] = useState<ErrandDraft | null>(null);
  const [draftApplied, setDraftApplied] = useState(false);

  const bottomRef = useRef<HTMLDivElement>(null);
  const recorderRef = useRef<UniversalAudioRecorder | null>(null);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const recognitionRef = useRef<SpeechRecognition | null>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isRecording, loading]);

  useEffect(() => {
    return () => {
      if (recorderRef.current) {
        recorderRef.current.cancel();
      }
      if (timerRef.current) {
        clearInterval(timerRef.current);
      }
      try {
        recognitionRef.current?.abort();
      } catch {
        // ignore
      }
    };
  }, []);

  const speak = (text: string) => {
    if (!voiceOut || typeof window === 'undefined' || !window.speechSynthesis) return;
    try {
      window.speechSynthesis.cancel();
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'en-US';
      window.speechSynthesis.speak(utterance);
    } catch {
      // ignore
    }
  };

  const handleApplyDraft = (draft: ErrandDraft) => {
    onDraft(draft, draft.clarifying_questions);
    setDraftApplied(true);
    toast.success('Form filled with errand details!');
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
      const returnedDraft = data.draft as ErrandDraft | undefined;

      setMessages((m) => [
        ...m,
        {
          role: 'assistant',
          text: reply,
          draft: returnedDraft,
        },
      ]);
      speak(reply);

      if (returnedDraft && (returnedDraft.title || returnedDraft.category)) {
        setLatestDraft(returnedDraft);
        setDraftApplied(false);
        handleApplyDraft(returnedDraft);
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

  // Start recording using UniversalAudioRecorder (works in all browsers)
  const startRecording = async () => {
    try {
      if (isRecording) {
        await stopRecording();
        return;
      }

      const recorder = new UniversalAudioRecorder();
      recorderRef.current = recorder;
      await recorder.start();

      setIsRecording(true);
      setRecordSeconds(0);

      timerRef.current = setInterval(() => {
        setRecordSeconds((s) => s + 1);
      }, 1000);

      // Attempt web speech in parallel for live text preview if available
      const Ctor = getSpeechRecognitionCtor();
      if (Ctor) {
        try {
          const rec = new Ctor();
          recognitionRef.current = rec;
          rec.continuous = false;
          rec.interimResults = true;
          rec.lang = 'en-NG'; // Nigerian English fallback
          rec.onresult = (e: SpeechRecognitionEvent) => {
            const transcript = Array.from(e.results)
              .map((r) => r[0]?.transcript)
              .join(' ');
            if (transcript.trim()) {
              setInput(transcript.trim());
            }
          };
          rec.onerror = () => {};
          rec.start();
        } catch {
          // ignore web speech error, recorder handles audio anyway
        }
      }
    } catch (err: unknown) {
      setIsRecording(false);
      const msg = err instanceof Error ? err.message : 'Could not access microphone.';
      toast.error(msg);
    }
  };

  // Stop recording and send audio directly to Gemini parse-audio
  const stopRecording = async () => {
    if (!recorderRef.current || !isRecording) return;

    if (timerRef.current) {
      clearInterval(timerRef.current);
      timerRef.current = null;
    }
    setIsRecording(false);

    try {
      recognitionRef.current?.abort();
    } catch {
      // ignore
    }

    setLoading(true);
    setMessages((m) => [...m, { role: 'user', text: '🎤 [Voice Recording sent]' }]);

    try {
      const audioDataUrl = await recorderRef.current.stop();

      // Send directly to backend parse-audio endpoint
      const { data } = await aiApi.parseErrandAudio(audioDataUrl);
      const returnedDraft = data.draft as ErrandDraft;

      const reply = returnedDraft.title
        ? `I understood: "${returnedDraft.title}". I've filled the form with your instructions!`
        : "I've processed your voice note and filled the form!";

      setMessages((m) => [
        ...m,
        {
          role: 'assistant',
          text: reply,
          draft: returnedDraft,
        },
      ]);
      speak(reply);

      if (returnedDraft) {
        setLatestDraft(returnedDraft);
        setDraftApplied(false);
        handleApplyDraft(returnedDraft);
      }
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        'Could not transcribe voice audio. Please try speaking clearly or typing.';
      setMessages((m) => [...m, { role: 'assistant', text: msg }]);
      toast.error(msg);
    } finally {
      setLoading(false);
      setRecordSeconds(0);
      recorderRef.current = null;
    }
  };

  return (
    <div className="rounded-2xl border-2 border-[#F97316]/25 bg-gradient-to-b from-orange-50/80 to-white overflow-hidden flex flex-col min-h-[340px] max-h-[460px]">
      <div className="px-4 py-2.5 border-b border-orange-100 flex items-center justify-between bg-white/90">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-[#F97316]" />
          <div>
            <p className="text-sm font-semibold text-[#0E0F13]">Talk through your errand</p>
            <p className="text-[11px] text-gray-500">Tap mic to speak or type instructions</p>
          </div>
        </div>
        <button
          type="button"
          onClick={() => setVoiceOut((v) => !v)}
          className={`text-xs px-2.5 py-1 rounded-lg flex items-center gap-1 shrink-0 transition ${
            voiceOut ? 'bg-[#F97316] text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
          title="Read replies aloud"
        >
          <Volume2 className="w-3.5 h-3.5" />
          {voiceOut ? 'Voice on' : 'Voice off'}
        </button>
      </div>

      <div className="flex-1 overflow-y-auto px-3 py-3 space-y-3">
        {messages.map((msg, i) => (
          <div key={i} className="space-y-1.5">
            <div
              className={`max-w-[90%] rounded-2xl px-3.5 py-2.5 text-sm ${
                msg.role === 'user'
                  ? 'ml-auto bg-[#F97316] text-white shadow-sm'
                  : 'bg-white border border-orange-100 text-gray-800 shadow-sm'
              }`}
            >
              {msg.text}
            </div>

            {/* Embedded Errand Draft Preview Card */}
            {msg.draft && (
              <div className="max-w-[90%] bg-gradient-to-br from-orange-50 to-amber-50 border border-orange-200 rounded-xl p-3 shadow-sm space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-bold text-[#F97316] flex items-center gap-1">
                    <Sparkles className="w-3.5 h-3.5" />
                    Errand Draft Ready
                  </span>
                  {msg.draft.budget ? (
                    <span className="text-xs font-extrabold text-gray-900 bg-white/80 px-2 py-0.5 rounded-full border border-orange-200">
                      ₦{Number(msg.draft.budget).toLocaleString()}
                    </span>
                  ) : null}
                </div>

                {msg.draft.title && (
                  <p className="text-xs text-gray-800 font-semibold line-clamp-1">
                    {msg.draft.title}
                  </p>
                )}

                {msg.draft.destination_address && (
                  <p className="text-[11px] text-gray-600 line-clamp-1">
                    📍 <strong>Deliver to:</strong> {msg.draft.destination_address}
                  </p>
                )}

                {msg.draft.item_details && (
                  <div className="text-[11px] text-gray-600 bg-white/60 p-1.5 rounded border border-orange-100 max-h-16 overflow-y-auto whitespace-pre-line">
                    {msg.draft.item_details}
                  </div>
                )}

                <button
                  type="button"
                  onClick={() => handleApplyDraft(msg.draft!)}
                  className="w-full py-1.5 bg-[#F97316] hover:bg-orange-600 text-white rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5 transition"
                >
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  Apply to Form Below
                </button>
              </div>
            )}
          </div>
        ))}

        {loading && (
          <div className="flex items-center gap-2 text-gray-500 text-xs py-1 px-2">
            <Loader2 className="w-4 h-4 animate-spin text-[#F97316]" />
            AI is listening and writing runner instructions…
          </div>
        )}

        {isRecording && (
          <div className="flex items-center justify-between p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 animate-pulse text-xs">
            <div className="flex items-center gap-2 font-medium">
              <span className="w-2.5 h-2.5 rounded-full bg-red-600 animate-ping" />
              Recording voice note ({recordSeconds}s)… Speak your errand clearly
            </div>
            <button
              type="button"
              onClick={stopRecording}
              className="px-3 py-1 bg-red-600 text-white rounded-lg font-bold text-xs hover:bg-red-700"
            >
              Stop & Send
            </button>
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      <div
        className="p-3 border-t border-orange-100 bg-white flex items-center gap-2"
        role="group"
        aria-label="Chat input"
      >
        <button
          type="button"
          onClick={isRecording ? stopRecording : startRecording}
          disabled={loading}
          className={`p-2.5 rounded-xl border transition ${
            isRecording
              ? 'border-red-500 bg-red-500 text-white animate-bounce'
              : 'border-orange-200 text-[#F97316] hover:bg-orange-50'
          } disabled:opacity-50`}
          aria-label={isRecording ? 'Stop recording' : 'Start voice recording'}
          title={isRecording ? 'Stop recording' : 'Record voice errand'}
        >
          {isRecording ? <MicOff className="w-5 h-5" /> : <Mic className="w-5 h-5" />}
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
          placeholder={isRecording ? 'Listening to voice...' : 'Type errand or tap mic to speak…'}
          className="flex-1 rounded-xl border border-gray-200 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-[#F97316]/30 disabled:bg-gray-50"
          disabled={loading || isRecording}
        />

        <button
          type="button"
          onClick={() => send()}
          disabled={loading || !input.trim() || isRecording}
          className="p-2.5 rounded-xl bg-[#F97316] text-white hover:bg-orange-600 transition disabled:opacity-40 disabled:hover:bg-[#F97316]"
          aria-label="Send message"
        >
          <Send className="w-5 h-5" />
        </button>
      </div>
    </div>
  );
}
