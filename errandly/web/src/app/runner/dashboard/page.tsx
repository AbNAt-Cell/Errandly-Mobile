'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { runnerApi } from '@/lib/api';
import Link from 'next/link';
import { MapPin, Star, Package, ToggleLeft, ToggleRight, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

const STATUS_COLORS: Record<string, string> = {
  accepted: 'bg-amber-500/20 text-amber-400 border border-amber-500/30',
  runner_en_route: 'bg-purple-500/20 text-purple-400 border border-purple-500/30',
  in_progress: 'bg-indigo-500/20 text-indigo-400 border border-indigo-500/30',
  awaiting_confirmation: 'bg-[#F97316]/20 text-[#F97316] border border-[#F97316]/30',
};

export default function RunnerDashboard() {
  const queryClient = useQueryClient();

  const { data: dashboard, isLoading } = useQuery({
    queryKey: ['runner-dashboard'],
    queryFn: () => runnerApi.dashboard().then((r) => r.data),
    refetchInterval: 30000,
  });

  const { data: availableErrands } = useQuery({
    queryKey: ['available-errands'],
    queryFn: () => runnerApi.availableErrands().then((r) => r.data),
    enabled: dashboard?.runner?.is_online,
    refetchInterval: 15000,
  });

  const toggleOnlineMutation = useMutation({
    mutationFn: (isOnline: boolean) => runnerApi.updateAvailability({ is_online: isOnline }),
    onSuccess: (_, isOnline) => {
      queryClient.invalidateQueries({ queryKey: ['runner-dashboard'] });
      toast.success(isOnline ? 'You are now online. Errands will appear below.' : 'You are now offline.');
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to update status');
    },
  });

  const acceptMutation = useMutation({
    mutationFn: (publicId: string) => runnerApi.acceptErrand(publicId),
    onSuccess: () => {
      toast.success('Errand accepted! Navigate to pickup location.');
      queryClient.invalidateQueries({ queryKey: ['runner-dashboard'] });
      queryClient.invalidateQueries({ queryKey: ['available-errands'] });
    },
    onError: (error: any) => {
      toast.error(error.response?.data?.message || 'Failed to accept errand');
    },
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#F97316]" />
      </div>
    );
  }

  const runner = dashboard?.runner;
  const isOnline = runner?.is_online;

  return (
    <div className="p-4 w-full space-y-5">
      {/* Online Toggle */}
      <div className={`rounded-2xl p-5 flex items-center justify-between ${
        isOnline
          ? 'bg-gradient-to-r from-green-600 to-emerald-700 shadow-lg shadow-green-900/30'
          : 'bg-[#17191F] border border-white/10'
      } text-white`}>
        <div>
          <p className="font-['Bricolage_Grotesque'] font-bold text-lg">{isOnline ? 'You are Online' : 'You are Offline'}</p>
          <p className="text-xs text-[#e0c0b1] mt-0.5">{isOnline ? 'Receiving errand requests nearby' : 'Toggle to start receiving errands'}</p>
        </div>
        <button
          onClick={() => toggleOnlineMutation.mutate(!isOnline)}
          disabled={toggleOnlineMutation.isPending}
          className="bg-white/10 hover:bg-white/20 rounded-xl p-3 transition active:scale-95"
        >
          {toggleOnlineMutation.isPending
            ? <Loader2 className="w-8 h-8 animate-spin" />
            : isOnline
            ? <ToggleRight className="w-8 h-8 text-white" />
            : <ToggleLeft className="w-8 h-8 text-gray-400" />
          }
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-[#17191F] border border-white/10 rounded-2xl p-5 text-center">
          <p className="text-gray-400 text-xs mb-1 font-medium">Today's Earnings</p>
          <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-white">₦{(dashboard?.today_earnings ?? 0).toLocaleString()}</p>
        </div>
        <div className="bg-[#17191F] border border-white/10 rounded-2xl p-5 text-center">
          <p className="text-gray-400 text-xs mb-1 font-medium">Wallet Balance</p>
          <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-[#F97316]">₦{(dashboard?.wallet_balance ?? 0).toLocaleString()}</p>
        </div>
        <div className="bg-[#17191F] border border-white/10 rounded-2xl p-5 text-center">
          <p className="text-gray-400 text-xs mb-1 font-medium">Trust Score</p>
          <div className="flex items-center justify-center gap-1">
            <Star className="w-5 h-5 fill-[#F97316] text-[#F97316]" />
            <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-white">{runner?.trust_score?.toFixed(0)}/100</p>
          </div>
        </div>
        <div className="bg-[#17191F] border border-white/10 rounded-2xl p-5 text-center">
          <p className="text-gray-400 text-xs mb-1 font-medium">Completion Rate</p>
          <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-green-400">{runner?.completion_rate ?? 100}%</p>
        </div>
      </div>

      {/* Active errand */}
      {dashboard?.active_errand && (
        <div>
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-white text-lg mb-3">Active Errand</h2>
          <Link href={`/runner/errands/${dashboard.active_errand.public_id}`}>
            <div className="bg-[#17191F] border-2 border-[#F97316] rounded-2xl p-5 hover:shadow-lg hover:shadow-[#F97316]/10 transition">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="font-bold text-white text-base">{dashboard.active_errand.title}</p>
                  <p className="text-xs text-[#e0c0b1] mt-1">Customer: {dashboard.active_errand.customer?.first_name}</p>
                  <div className="flex items-center gap-1 mt-2 text-xs text-gray-300">
                    <MapPin className="w-4 h-4 text-[#F97316]" />
                    <span>{dashboard.active_errand.pickup_address?.substring(0, 40)}...</span>
                  </div>
                </div>
                <div className="text-right ml-4">
                  <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[dashboard.active_errand.status] || 'bg-gray-500/20 text-gray-400'}`}>
                    {dashboard.active_errand.status?.replace(/_/g, ' ')}
                  </span>
                  <p className="font-['Bricolage_Grotesque'] font-bold text-[#F97316] text-lg mt-2">
                    ₦{dashboard.active_errand.runner_earnings?.toLocaleString()}
                  </p>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-white/10">
                <span className="text-[#F97316] text-xs font-bold">Tap to view details →</span>
              </div>
            </div>
          </Link>
        </div>
      )}

      {/* Available Errands */}
      {isOnline && !dashboard?.active_errand && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-['Bricolage_Grotesque'] font-bold text-white text-lg">Available Errands Nearby</h2>
            <span className="text-xs text-[#e0c0b1] bg-white/5 border border-white/10 px-2.5 py-1 rounded-full">
              {availableErrands?.data?.length ?? 0} available
            </span>
          </div>

          {availableErrands?.data?.length === 0 ? (
            <div className="bg-[#17191F] border border-white/10 rounded-2xl text-center py-12 p-6">
              <Package className="w-12 h-12 text-gray-500 mx-auto mb-3" />
              <p className="text-white font-medium">No errands available in your area</p>
              <p className="text-gray-400 text-xs mt-1">Refresh or check back in a few minutes</p>
            </div>
          ) : (
            <div className="space-y-3">
              {availableErrands?.data?.map((errand: any) => (
                <div key={errand.id} className="bg-[#17191F] border border-white/10 rounded-2xl p-5">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className={`text-xs px-2.5 py-0.5 rounded-full font-medium ${
                          errand.urgency === 'urgent'
                            ? 'bg-red-500/20 text-red-400 border border-red-500/30'
                            : 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                        }`}>
                          {errand.urgency === 'urgent' ? '⚡ Urgent' : '🕐 Standard'}
                        </span>
                        <span className="text-xs text-gray-400">{errand.distance_km?.toFixed(1)}km away</span>
                      </div>
                      <p className="font-semibold text-white mt-2">{errand.title}</p>
                      <p className="text-xs text-gray-400 mt-1 line-clamp-2">{errand.description}</p>
                      <div className="flex items-center gap-1 mt-2 text-xs text-gray-300">
                        <MapPin className="w-4 h-4 text-[#F97316]" />
                        <span>{errand.pickup_address?.substring(0, 50)}...</span>
                      </div>
                    </div>
                    <div className="ml-4 text-right">
                      <p className="font-['Bricolage_Grotesque'] text-2xl font-bold text-[#F97316]">
                        ₦{errand.budget?.toLocaleString()}
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5">Your earnings</p>
                    </div>
                  </div>
                  <div className="flex gap-2 mt-4">
                    <button
                      onClick={() => acceptMutation.mutate(errand.public_id)}
                      disabled={acceptMutation.isPending}
                      className="flex-1 bg-[#F97316] hover:bg-[#EA580C] text-[#121317] font-['Bricolage_Grotesque'] font-bold text-sm py-2.5 rounded-xl flex items-center justify-center gap-2 transition hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] disabled:opacity-70"
                    >
                      {acceptMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                      Accept Errand
                    </button>
                    <button className="px-4 py-2.5 bg-white/5 border border-white/10 rounded-xl text-sm text-gray-300 hover:bg-white/10 transition">
                      Ignore
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
