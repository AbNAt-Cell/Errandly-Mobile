'use client';

import Link from 'next/link';
import { ArrowLeft, Mail, MessageSquare, AlertTriangle } from 'lucide-react';

export default function CustomerSupportPage() {
  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/dashboard" className="p-2 rounded-lg hover:bg-muted">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-foreground">Help & Support</h1>
      </div>

      <div className="space-y-4">
        <a
          href="mailto:support@dooyn.com"
          className="flex items-center gap-4 bg-card rounded-2xl border border-border p-4 hover:border-[#FF6B00] transition"
        >
          <Mail className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-foreground">Email support</p>
            <p className="text-sm text-muted-foreground">support@dooyn.com</p>
          </div>
        </a>

        <Link
          href="/customer/messages"
          className="flex items-center gap-4 bg-card rounded-2xl border border-border p-4 hover:border-[#FF6B00] transition"
        >
          <MessageSquare className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-foreground">Errand messages</p>
            <p className="text-sm text-muted-foreground">Chat with your runner on active errands</p>
          </div>
        </Link>

        <Link
          href="/customer/assistant"
          className="flex items-center gap-4 bg-card rounded-2xl border border-border p-4 hover:border-[#FF6B00] transition"
        >
          <AlertTriangle className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-foreground">AI assistant</p>
            <p className="text-sm text-muted-foreground">Ask about policies, refunds, and your errands</p>
          </div>
        </Link>
      </div>
    </div>
  );
}
