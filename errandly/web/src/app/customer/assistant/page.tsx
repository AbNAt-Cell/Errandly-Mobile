'use client';

import { useState, useRef, useEffect } from 'react';
import { Sparkles, Send, Loader2 } from 'lucide-react';
import { aiApi } from '@/lib/api';

type Message = { role: 'user' | 'assistant'; text: string };

export default function CustomerAssistantPage() {
  const [messages, setMessages] = useState<Message[]>([
    {
      role: 'assistant',
      text: 'Hi! I can help with your errands, escrow, refunds, and posting a new task. What do you need?',
    },
  ]);
  const [input, setInput] = useState('');
  const [sessionId, setSessionId] = useState<string | undefined>();
  const [loading, setLoading] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const send = async () => {
    const text = input.trim();
    if (!text || loading) return;

    setInput('');
    setMessages((m) => [...m, { role: 'user', text }]);
    setLoading(true);

    try {
      const { data } = await aiApi.chat({ message: text, session_id: sessionId });
      if (data.session_id) setSessionId(data.session_id);
      setMessages((m) => [...m, { role: 'assistant', text: data.reply || 'Done.' }]);
    } catch (err: unknown) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        'Something went wrong. Please try again.';
      setMessages((m) => [...m, { role: 'assistant', text: msg }]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      <div className="px-4 py-4 border-b border-border bg-card">
        <div className="flex items-center gap-2">
          <div className="w-9 h-9 rounded-lg bg-[#FF6B00]/10 flex items-center justify-center">
            <Sparkles className="w-5 h-5 text-[#FF6B00]" />
          </div>
          <div>
            <h1 className="font-semibold text-foreground">DOOYN Assistant</h1>
            <p className="text-xs text-muted-foreground">Policies, errands, and help</p>
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {messages.map((msg, i) => (
          <div
            key={i}
            className={`max-w-[85%] rounded-2xl px-4 py-2.5 text-sm ${
              msg.role === 'user'
                ? 'ml-auto bg-[#FF6B00] text-white'
                : 'bg-card border border-border text-gray-800'
            }`}
          >
            {msg.text}
          </div>
        ))}
        {loading && (
          <div className="flex items-center gap-2 text-gray-400 text-sm">
            <Loader2 className="w-4 h-4 animate-spin" />
            Thinking…
          </div>
        )}
        <div ref={bottomRef} />
      </div>

      <div className="p-4 bg-card border-t border-border">
        <div className="flex gap-2 w-full">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), send())}
            placeholder="Ask about escrow, your errands…"
            className="flex-1 rounded-xl border border-input px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-primary/30"
            disabled={loading}
          />
          <button
            type="button"
            onClick={send}
            disabled={loading || !input.trim()}
            className="rounded-xl bg-[#FF6B00] text-white p-3 disabled:opacity-50"
            aria-label="Send"
          >
            <Send className="w-5 h-5" />
          </button>
        </div>
      </div>
    </div>
  );
}