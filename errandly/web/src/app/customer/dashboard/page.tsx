'use client';
import { useQuery } from '@tanstack/react-query';
import { customerApi, walletApi } from '@/lib/api';
import Link from 'next/link';
import { Plus, Wallet, MessageSquare, Shield, Package, TrendingUp, Sparkles } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const STATUS_COLORS: Record<string, string> = {
  posted: 'bg-blue-500/20 text-blue-400 border border-blue-500/30',
  pending_assignment: 'bg-yellow-500/20 text-yellow-400 border border-yellow-500/30',
  accepted: 'bg-amber-500/20 text-amber-400 border border-amber-500/30',
  runner_en_route: 'bg-purple-500/20 text-purple-400 border border-purple-500/30',
  in_progress: 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30',
  awaiting_confirmation: 'bg-[#F97316]/20 text-[#F97316] border border-[#F97316]/30',
  completed: 'bg-green-500/20 text-green-400 border border-green-500/30',
  cancelled: 'bg-gray-500/20 text-gray-400 border border-gray-500/30',
  disputed: 'bg-red-500/20 text-red-400 border border-red-500/30',
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
    <div className="p-6 w-full space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="font-['Bricolage_Grotesque'] text-2xl font-bold text-white">Dashboard</h1>
          <p className="text-[#e0c0b1] text-sm">What do you need done today?</p>
        </div>
        <Link href="/customer/errands/new" className="errand-btn-primary flex items-center gap-2">
          <Plus className="w-5 h-5" />
          Post Errand
        </Link>
      </div>

      {/* Wallet + Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div className="col-span-2 rounded-2xl p-6 bg-gradient-to-r from-[#F97316] to-[#FB923C] text-[#121317] flex items-center justify-between shadow-lg shadow-[#F97316]/20">
          <div>
            <p className="text-[#582200] text-xs uppercase font-bold tracking-wider">Wallet Balance</p>
            <p className="font-['Bricolage_Grotesque'] text-3xl font-extrabold text-[#121317] mt-1">
              ₦{(wallet?.balance ?? 0).toLocaleString()}
            </p>
            <p className="text-[#582200] text-xs mt-1 font-medium">
              ₦{(wallet?.escrow_balance ?? 0).toLocaleString()} in escrow
            </p>
          </div>
          <div className="text-right">
            <Link href="/customer/wallet" className="inline-flex items-center gap-1.5 bg-[#121317] hover:bg-[#1f1f24] text-white px-4 py-2.5 rounded-xl text-xs font-bold transition">
              <Wallet className="w-4 h-4 text-[#F97316]" />
              Fund Wallet
            </Link>
          </div>
        </div>
        {[
          { label: 'Total Errands', value: errands?.total ?? 0, icon: Package, color: 'text-[#F97316] bg-[#F97316]/10' },
          { label: 'Active Now', value: activeErrands.length, icon: TrendingUp, color: 'text-green-400 bg-green-500/10' },
        ].map((stat) => (
          <div key={stat.label} className="bg-[#17191F] border border-white/10 rounded-2xl p-5 flex items-center gap-4">
            <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${stat.color}`}>
              <stat.icon className="w-6 h-6" />
            </div>
            <div>
              <p className="text-gray-400 text-xs font-medium">{stat.label}</p>
              <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-white">{stat.value}</p>
            </div>
          </div>
        ))}
      </div>

      <Link
        href="/customer/assistant"
        className="bg-[#17191F] border border-[#F97316]/30 hover:border-[#F97316] rounded-2xl p-5 flex items-center gap-4 transition-all group"
      >
        <div className="w-12 h-12 rounded-xl bg-[#F97316]/10 flex items-center justify-center text-[#F97316] group-hover:scale-105 transition-transform">
          <Sparkles className="w-6 h-6" />
        </div>
        <div className="flex-1">
          <p className="font-['Bricolage_Grotesque'] font-bold text-white text-base">Ask the Errand Assistant</p>
          <p className="text-sm text-[#e0c0b1]">Escrow, policies, errand help — powered by AI</p>
        </div>
      </Link>

      {/* Active Errands */}
      {activeErrands.length > 0 && (
        <div>
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-lg text-white mb-3">Active Errands</h2>
          <div className="space-y-3">
            {activeErrands.map((errand: any) => (
              <Link key={errand.public_id} href={`/customer/errands/${errand.public_id}`}>
                <div className="bg-[#17191F] border border-white/10 hover:border-[#F97316] rounded-2xl p-5 transition-all flex items-center justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-10 h-10 bg-[#F97316]/10 rounded-xl flex items-center justify-center">
                      <Package className="w-5 h-5 text-[#F97316]" />
                    </div>
                    <div>
                      <p className="font-semibold text-white">{errand.title}</p>
                      <p className="text-xs text-[#e0c0b1]">{errand.runner?.full_name ?? 'Searching for runner...'}</p>
                    </div>
                  </div>
                  <div className="text-right">
                    <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[errand.status] || 'bg-gray-500/20 text-gray-400'}`}>
                      {STATUS_LABELS[errand.status] || errand.status}
                    </span>
                    <p className="text-sm font-bold text-[#F97316] mt-1">₦{errand.budget?.toLocaleString()}</p>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div>
        <h2 className="font-['Bricolage_Grotesque'] font-bold text-lg text-white mb-3">Quick Actions</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { href: '/customer/errands/new', icon: Plus, label: 'Post Errand', color: 'bg-[#F97316] text-[#121317] font-bold' },
            { href: '/customer/wallet', icon: Wallet, label: 'Fund Wallet', color: 'bg-[#17191F] border border-white/10 text-white hover:border-[#F97316]' },
            { href: '/customer/messages', icon: MessageSquare, label: 'Messages', color: 'bg-[#17191F] border border-white/10 text-white hover:border-[#F97316]' },
            { href: '/customer/support', icon: Shield, label: 'Report Issue', color: 'bg-[#17191F] border border-white/10 text-white hover:border-[#F97316]' },
          ].map((action) => (
            <Link key={action.label} href={action.href}>
              <div className={`rounded-xl p-4 flex flex-col items-center gap-2 text-center transition cursor-pointer ${action.color}`}>
                <action.icon className="w-6 h-6" />
                <span className="text-sm">{action.label}</span>
              </div>
            </Link>
          ))}
        </div>
      </div>

      {/* Recent Errands */}
      <div>
        <div className="flex items-center justify-between mb-3">
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-lg text-white">Recent Errands</h2>
          <Link href="/customer/errands" className="text-[#F97316] text-sm hover:underline font-medium">View all</Link>
        </div>
        <div className="space-y-2">
          {errands?.data?.slice(0, 5).map((errand: any) => (
            <Link key={errand.public_id} href={`/customer/errands/${errand.public_id}`}>
              <div className="flex items-center justify-between p-4 bg-[#17191F] rounded-xl border border-white/10 hover:border-[#F97316] transition">
                <div className="flex items-center gap-3">
                  <span className="text-xl">
                    {errand.category === 'grocery_purchase' ? '🛒' :
                     errand.category === 'package_pickup' ? '📦' :
                     errand.category === 'document_submission' ? '📄' : '🏃'}
                  </span>
                  <div>
                    <p className="font-medium text-white text-sm">{errand.title}</p>
                    <p className="text-xs text-gray-400">{formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[errand.status] || 'bg-gray-500/20 text-gray-400'}`}>
                    {STATUS_LABELS[errand.status] || errand.status}
                  </span>
                  <p className="text-sm font-bold text-[#F97316] mt-1">₦{errand.budget?.toLocaleString()}</p>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </div>
    </div>
  );
}
