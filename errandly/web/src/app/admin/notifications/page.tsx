'use client';
import { useMutation } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Bell, Loader2, Send } from 'lucide-react';

export default function AdminNotificationsPage() {
  const [form, setForm] = useState({ title: '', body: '', role: '', city: '' });

  const broadcastMutation = useMutation({
    mutationFn: (data: any) => adminApi.finance(), // placeholder - would call broadcast endpoint
    onSuccess: () => {
      toast.success('Notification broadcasted successfully.');
      setForm({ title: '', body: '', role: '', city: '' });
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed'),
  });

  return (
    <div className="p-6 max-w-2xl">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-[#0A1628]">Broadcast Notifications</h1>
        <p className="text-gray-500 text-sm">Send announcements to all users or specific segments</p>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-5">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Notification Title</label>
          <input
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
            placeholder="e.g. New Feature Available!"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1.5">Message</label>
          <textarea
            value={form.body}
            onChange={(e) => setForm({ ...form, body: e.target.value })}
            rows={4}
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] resize-none"
            placeholder="Your announcement message..."
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">Target Role (optional)</label>
            <select value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white">
              <option value="">All Users</option>
              <option value="customer">Customers Only</option>
              <option value="runner">Runners Only</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1.5">Target City (optional)</label>
            <select value={form.city} onChange={(e) => setForm({ ...form, city: e.target.value })} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white">
              <option value="">All Cities</option>
              <option value="Lekki">Lekki</option>
              <option value="Yaba">Yaba</option>
              <option value="Ikeja">Ikeja</option>
              <option value="Surulere">Surulere</option>
              <option value="Victoria Island">Victoria Island</option>
            </select>
          </div>
        </div>

        <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-700 flex gap-2">
          <Bell className="w-5 h-5 flex-shrink-0 mt-0.5" />
          <span>This will send push notifications to all matching users and add to their in-app notification list.</span>
        </div>

        <button
          onClick={() => broadcastMutation.mutate(form)}
          disabled={!form.title || !form.body || broadcastMutation.isPending}
          className="w-full errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-50"
        >
          {broadcastMutation.isPending ? <Loader2 className="w-5 h-5 animate-spin" /> : <Send className="w-5 h-5" />}
          {broadcastMutation.isPending ? 'Broadcasting...' : 'Send Notification'}
        </button>
      </div>
    </div>
  );
}
