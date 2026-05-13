'use client';
import { useQuery } from '@tanstack/react-query';
import { messageApi } from '@/lib/api';
import Link from 'next/link';
import { MessageSquare, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

export default function CustomerMessagesPage() {
  const { data: conversations, isLoading } = useQuery({
    queryKey: ['conversations'],
    queryFn: () => messageApi.conversations().then((r) => r.data),
    refetchInterval: 30000,
  });

  return (
    <div className="pb-20 p-4">
      <h1 className="font-bold text-xl text-[#0A1628] mb-4">Messages</h1>

      {isLoading ? (
        <div className="flex justify-center py-12"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" /></div>
      ) : !Array.isArray(conversations) || conversations.length === 0 ? (
        <div className="text-center py-16">
          <MessageSquare className="w-16 h-16 text-gray-200 mx-auto mb-4" />
          <p className="text-gray-500 font-medium">No messages yet</p>
          <p className="text-gray-400 text-sm mt-1">Messages appear when a runner is assigned to your errand</p>
        </div>
      ) : (
        <div className="space-y-2">
          {conversations.map((conv: any) => {
            const other = conv.other_party;
            const last = conv.last_message;
            const unread = conv.unread_count ?? 0;

            return (
              <Link key={conv.errand_id} href={`/customer/messages/${conv.errand_id}`}>
                <div className="bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition flex items-center gap-3">
                  <div className="relative">
                    <div className="w-12 h-12 bg-[#FF6B00] rounded-full flex items-center justify-center text-white font-bold">
                      {other?.first_name?.[0]}{other?.last_name?.[0]}
                    </div>
                    {unread > 0 && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-xs font-bold">{unread}</span>
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between">
                      <p className="font-semibold text-[#0A1628]">{other?.first_name} {other?.last_name}</p>
                      {last?.created_at && (
                        <p className="text-xs text-gray-400">{formatDistanceToNow(new Date(last.created_at), { addSuffix: true })}</p>
                      )}
                    </div>
                    <p className="text-sm text-gray-500 truncate">{last?.content ?? conv.title}</p>
                  </div>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </div>
  );
}
