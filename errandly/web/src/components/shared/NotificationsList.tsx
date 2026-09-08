'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { notificationApi } from '@/lib/api';
import { Bell, Loader2, CheckCheck } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';

export default function NotificationsList() {
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => notificationApi.list().then((r) => r.data),
    refetchInterval: 60000,
  });

  const markAllMutation = useMutation({
    mutationFn: () => notificationApi.markAllRead(),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] });
      toast.success('All notifications marked as read.');
    },
  });

  const markReadMutation = useMutation({
    mutationFn: (id: number) => notificationApi.markRead(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['notifications'] }),
  });

  const items = data?.notifications?.data ?? [];

  return (
    <div className="pb-20 p-4">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="font-bold text-xl text-foreground">Notifications</h1>
          {(data?.unread_count ?? 0) > 0 && (
            <p className="text-sm text-muted-foreground">{data.unread_count} unread</p>
          )}
        </div>
        {items.length > 0 && (
          <button
            type="button"
            onClick={() => markAllMutation.mutate()}
            disabled={markAllMutation.isPending}
            className="text-sm text-[#FF6B00] font-medium flex items-center gap-1"
          >
            <CheckCheck className="w-4 h-4" />
            Mark all read
          </button>
        )}
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
        </div>
      ) : items.length === 0 ? (
        <div className="text-center py-16">
          <Bell className="w-16 h-16 text-gray-200 mx-auto mb-4" />
          <p className="text-muted-foreground font-medium">No notifications yet</p>
          <p className="text-gray-400 text-sm mt-1">Updates about your errands will appear here</p>
        </div>
      ) : (
        <div className="space-y-2">
          {items.map((n: { id: number; title: string; body: string; read_at: string | null; created_at: string; type?: string }) => (
            <button
              key={n.id}
              type="button"
              onClick={() => !n.read_at && markReadMutation.mutate(n.id)}
              className={`w-full text-left bg-card rounded-2xl border p-4 transition ${
                n.read_at ? 'border-border' : 'border-[#FF6B00]/30 bg-orange-50/50'
              }`}
            >
              <div className="flex items-start justify-between gap-2">
                <p className="font-semibold text-foreground text-sm">{n.title}</p>
                <p className="text-xs text-gray-400 shrink-0">
                  {formatDistanceToNow(new Date(n.created_at), { addSuffix: true })}
                </p>
              </div>
              <p className="text-sm text-muted-foreground mt-1">{n.body}</p>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
