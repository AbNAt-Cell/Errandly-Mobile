'use client';
import { useQuery } from '@tanstack/react-query';
import { customerApi, walletApi } from '@/lib/api';
import Link from 'next/link';
import { Plus, MapPin, Wallet, MessageSquare, Shield, Clock, Package, TrendingUp, AlertCircle, Sparkles } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const STATUS_COLORS: Record<string, string> = {
  posted: 'bg-blue-100 text-blue-700',
  pending_assignment: 'bg-yellow-100 text-yellow-700',
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-indigo-100 text-indigo-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-700',
  disputed: 'bg-red-100 text-red-700',
};

const STATUS_LABELS: Record<string, string> = {
  posted: 'Posted',
  pending_assignment: 'Finding Runner...',
  accepted: 'Runner Assigned',
  runner_en_route: 'Runner En Route',
  item_picked: 'Item Picked Up',
  in_progress: 'In Progress',
  awaiting_confirmation: 'Awaiting Your Confirmation',
  completed: 'Completed',
  cancelled: 'Cancelled',
  disputed: 'Disputed',
};

export default function CustomerDashboard() {
  const { data: dashboard } = useQuery({
    queryKey: ['customer-dashboard'],
    queryFn: () => customerApi.dashboard().then((r) => r.data),
    refetchInterval: 30000,
  });

  const { data: wallet } = useQuery({
    queryKey: ['wallet'],
    queryFn: () => walletApi.get().then((r) => r.data),
  });

  const { data: errands } = useQuery({
    queryKey: ['customer-errands'],
    queryFn: () => customerApi.errands({ per_page: 5 }).then((r) => r.data),
  });

  const activeErrands = errands?.data?.filter((e: any) =>
    ['pending_assignment', 'accepted', 'runner_en_route', 'item_picked', 'in_progress', 'awaiting_confirmation'].includes(e.status)
  ) ?? [];

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#0A1628]">Dashboard</h1>
          <p className="text-gray-500 text-sm">What do you need done today?</p>
        </div>
        <Link href="/customer/errands/new" className="errandly-btn-primary flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Post Errand
        </Link>
      </div>

      {/* Wallet + Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="errandly-card col-span-2 flex items-center justify-between bg-gradient-to-r from-[#FF6B00] to-[#FF8C3A] text-white">
          <div>
            <p className="text-orange-200 text-sm">Wallet Balance</p>
            <p className="text-3xl font-bold">₦{(wallet?.balance ?? 0).toLocaleString()}</p>
            <p className="text-orange-200 text-xs mt-1">₦{(wallet?.escrow_balance ?? 0).toLocaleString()} in escrow</p>
          </div>
          <div className="text-right">
            <Link href="/customer/wallet" className="inline-flex items-center gap-1.5 bg-white/20 hover:bg-white/30 px-4 py-2 rounded-lg text-sm font-medium transition">
              <Wallet className="w-4 h-4" />
              Fund Wallet
            </Link>
          </div>
        </div>
        {[
          { label: 'Total Errands', value: errands?.total ?? 0, icon: Package, color: 'text-blue-600 bg-blue-100' },
          { label: 'Active Now', value: activeErrands.length, icon: TrendingUp, color: 'text-green-600 bg-green-100' },
        ].map((stat) => (
          <div key={stat.label} className="errandly-card flex items-center gap-4">
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${stat.color}`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-gray-500 text-xs">{stat.label}</p>
              <p className="text-2xl font-bold text-[#0A1628]">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      <Link
        href="/customer/assistant"
        className="errandly-card flex items-center gap-4 border border-[#FF6B00]/20 bg-orange-50/50 hover:bg-orange-50 transition"
      >
        <div className="w-12 h-12 rounded-xl bg-[#FF6B00]/10 flex items-center justify-center">
          <Sparkles className="w-6 h-6 text-[#FF6B00]" />
        </div>
        <div className="flex-1">
          <p className="font-semibold text-[#0A1628]">Ask the Errandly Assistant</p>
          <p className="text-sm text-gray-500">Escrow, policies, errand help — powered by AI</p>
        </div>
      </Link>

      {/* Active Errands */}
      {activeErrands.length > 0 && (
        <div>
          <h2 className="font-bold text-[#0A1628] mb-3">Active Errands</h2>
          <div className="space-y-3">
            {activeErrands.map((errand: any) => (
              <Link key={errand.public_id} href={`/customer/errands/${errand.public_id}`}>
                <div className="errandly-card hover:border-[#FF6B00] transition-all flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-[#FF6B00]/10 rounded-xl flex items-center justify-center">
                      <Package className="w-5 h-5 text-[#FF6B00]" />
                    </div>
                    <div>
                      <p className="font-semibold text-[#0A1628]">{errand.title}</p>
                      <p className="text-sm text-gray-500">{errand.runner?.full_name ?? 'Searching for runner...'}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'}`}>
                      {STATUS_LABELS[errand.status] || errand.status}
                    </span>
                    <p className="text-sm font-bold text-[#0A1628] mt-1">₦{errand.budget?.toLocaleString()}</p>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div>
        <h2 className="font-bold text-[#0A1628] mb-3">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { href: '/customer/errands/new', icon: Plus, label: 'Post Errand', color: 'bg-[#FF6B00] text-white' },
            { href: '/customer/wallet', icon: Wallet, label: 'Fund Wallet', color: 'bg-blue-50 text-blue-700' },
            { href: '/customer/messages', icon: MessageSquare, label: 'Messages', color: 'bg-purple-50 text-purple-700' },
            { href: '/customer/support', icon: Shield, label: 'Report Issue', color: 'bg-red-50 text-red-700' },
          ].map((action) => (
            <Link key={action.label} href={action.href}>
              <div className={`rounded-xl p-4 flex flex-col items-center gap-2 text-center hover:opacity-90 transition cursor-pointer ${action.color}`}>
                <action.icon className="w-6 h-6" />
                <span className="text-sm font-medium">{action.label}</span>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Recent Errands */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-bold text-[#0A1628]">Recent Errands</h2>
          <Link href="/customer/errands" className="text-[#FF6B00] text-sm hover:underline">View all</Link>
        </div>
        <div className="space-y-2">
          {errands?.data?.slice(0, 5).map((errand: any) => (
            <Link key={errand.public_id} href={`/customer/errands/${errand.public_id}`}>
              <div className="flex items-center justify-between p-4 bg-white rounded-xl border border-gray-100 hover:border-[#FF6B00] transition">
                <div className="flex items-center gap-3">
                  <span className="text-xl">
                    {errand.category === 'grocery_purchase' ? '🛒' :
                     errand.category === 'package_pickup' ? '📦' :
                     errand.category === 'document_submission' ? '📄' : '🏃'}
                  </span>
                  <div>
                    <p className="font-medium text-[#0A1628] text-sm">{errand.title}</p>
                    <p className="text-xs text-gray-500">{formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'}`}>
                    {STATUS_LABELS[errand.status] || errand.status}
                  </span>
                  <p className="text-sm font-bold text-[#0A1628] mt-1">₦{errand.budget?.toLocaleString()}</p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
