'use client';

import Link from 'next/link';
import { ArrowLeft, Mail, MessageSquare, AlertTriangle } from 'lucide-react';

export default function CustomerSupportPage() {
  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/dashboard" className="p-2 rounded-lg hover:bg-gray-100">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-[#0A1628]">Help & Support</h1>
      </div>

      <div className="space-y-4">
        <a
          href="mailto:support@errandly.com"
          className="flex items-center gap-4 bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition"
        >
          <Mail className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-[#0A1628]">Email support</p>
            <p className="text-sm text-gray-500">support@errandly.com</p>
          </div>
        </a>

        <Link
          href="/customer/messages"
          className="flex items-center gap-4 bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition"
        >
          <MessageSquare className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-[#0A1628]">Errand messages</p>
            <p className="text-sm text-gray-500">Chat with your runner on active errands</p>
          </div>
        </Link>

        <Link
          href="/customer/assistant"
          className="flex items-center gap-4 bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition"
        >
          <AlertTriangle className="w-6 h-6 text-[#FF6B00]" />
          <div>
            <p className="font-semibold text-[#0A1628]">AI assistant</p>
            <p className="text-sm text-gray-500">Ask about policies, refunds, and your errands</p>
          </div>
        </Link>
      </div>
    </div>
  );
}
