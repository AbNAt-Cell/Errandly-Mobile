'use client';

import { useState } from 'react';
import { useParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { messageApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import Link from 'next/link';
import { ArrowLeft, Loader2, Send } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';

type Props = {
  backHref: string;
};

export default function ConversationThread({ backHref }: Props) {
  const params = useParams();
  const publicId = params.publicId as string;
  const { user } = useAuthStore();
  const queryClient = useQueryClient();
  const [text, setText] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['conversation', publicId],
    queryFn: () => messageApi.getConversation(publicId).then((r) => r.data),
    enabled: !!publicId,
    refetchInterval: 10000,
  });

  const sendMutation = useMutation({
    mutationFn: (content: string) => messageApi.send(publicId, { content, type: 'text' }),
    onSuccess: () => {
      setText('');
      queryClient.invalidateQueries({ queryKey: ['conversation', publicId] });
      queryClient.invalidateQueries({ queryKey: ['conversations'] });
    },
    onError: (e: { response?: { data?: { message?: string } } }) => {
      toast.error(e.response?.data?.message || 'Could not send message');
    },
  });

  const messages = data?.data ?? [];

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)] pb-20">
      <div className="flex items-center gap-3 p-4 border-b border-gray-100 bg-white sticky top-16 z-10">
        <Link href={backHref} className="p-2 rounded-lg hover:bg-gray-100">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-[#0A1628]">Chat</h1>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
          </div>
        ) : messages.length === 0 ? (
          <p className="text-center text-gray-400 text-sm py-8">No messages yet. Say hello!</p>
        ) : (
          messages.map((msg: {
            id: number;
            sender_id: number;
            content?: string;
            created_at: string;
            sender?: { first_name?: string };
          }) => {
            const mine = msg.sender_id === user?.id;
            return (
              <div
                key={msg.id}
                className={`flex ${mine ? 'justify-end' : 'justify-start'}`}
              >
                <div
                  className={`max-w-[80%] rounded-2xl px-4 py-2.5 text-sm ${
                    mine ? 'bg-[#FF6B00] text-white' : 'bg-white border border-gray-100 text-[#0A1628]'
                  }`}
                >
                  <p>{msg.content}</p>
                  <p className={`text-xs mt-1 ${mine ? 'text-orange-100' : 'text-gray-400'}`}>
                    {formatDistanceToNow(new Date(msg.created_at), { addSuffix: true })}
                  </p>
                </div>
              </div>
            );
          })
        )}
      </div>

      <form
        className="p-4 bg-white border-t border-gray-100 flex gap-2"
        onSubmit={(e) => {
          e.preventDefault();
          if (!text.trim()) return;
          sendMutation.mutate(text.trim());
        }}
      >
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Type a message…"
          className="flex-1 border border-gray-200 rounded-xl px-4 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00]/40"
        />
        <button
          type="submit"
          disabled={!text.trim() || sendMutation.isPending}
          className="p-3 bg-[#FF6B00] text-white rounded-xl disabled:opacity-50"
        >
          {sendMutation.isPending ? (
            <Loader2 className="w-5 h-5 animate-spin" />
          ) : (
            <Send className="w-5 h-5" />
          )}
        </button>
      </form>
    </div>
  );
}
