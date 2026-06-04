'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { runnerApi } from '@/lib/api';
import Link from 'next/link';
import { MapPin, DollarSign, Star, Package, ToggleLeft, ToggleRight, Loader2, TrendingUp, Clock } from 'lucide-react';
import toast from 'react-hot-toast';
import { useState } from 'react';

const STATUS_COLORS: Record<string, string> = {
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-indigo-100 text-indigo-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
};

export default function RunnerDashboard() {
  const queryClient = useQueryClient();
  const [isTogglingOnline, setIsTogglingOnline] = useState(false);

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
        <Loader2 className="w-8 h-8 animate-spin text-[#FF6B00]" />
      </div>
    );
  }

  const runner = dashboard?.runner;
  const isOnline = runner?.is_online;

  return (
    <div className="p-4 max-w-2xl mx-auto space-y-5">
      {/* Online Toggle */}
      <div className={`rounded-2xl p-5 flex items-center justify-between ${isOnline ? 'bg-gradient-to-r from-green-500 to-green-600' : 'bg-gradient-to-r from-gray-600 to-gray-700'} text-white`}>
        <div>
          <p className="font-bold text-lg">{isOnline ? 'You are Online' : 'You are Offline'}</p>
          <p className="text-sm opacity-80">{isOnline ? 'Receiving errand requests nearby' : 'Toggle to start receiving errands'}</p>
        </div>
        <button
          onClick={() => toggleOnlineMutation.mutate(!isOnline)}
          disabled={toggleOnlineMutation.isPending}
          className="bg-white/20 hover:bg-white/30 rounded-xl p-3 transition"
        >
          {toggleOnlineMutation.isPending
            ? <Loader2 className="w-8 h-8 animate-spin" />
            : isOnline
            ? <ToggleRight className="w-8 h-8" />
            : <ToggleLeft className="w-8 h-8" />
          }
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4">
        <div className="errandly-card text-center">
          <p className="text-gray-500 text-xs mb-1">Today's Earnings</p>
          <p className="text-2xl font-bold text-[#0A1628]">₦{(dashboard?.today_earnings ?? 0).toLocaleString()}</p>
        </div>
        <div className="errandly-card text-center">
          <p className="text-gray-500 text-xs mb-1">Wallet Balance</p>
          <p className="text-2xl font-bold text-[#FF6B00]">₦{(dashboard?.wallet_balance ?? 0).toLocaleString()}</p>
        </div>
        <div className="errandly-card text-center">
          <p className="text-gray-500 text-xs mb-1">Trust Score</p>
          <div className="flex items-center justify-center gap-1">
            <Star className="w-5 h-5 fill-[#FF6B00] text-[#FF6B00]" />
            <p className="text-2xl font-bold text-[#0A1628]">{runner?.trust_score?.toFixed(0)}/100</p>
          </div>
        </div>
        <div className="errandly-card text-center">
          <p className="text-gray-500 text-xs mb-1">Completion Rate</p>
          <p className="text-2xl font-bold text-green-600">{runner?.completion_rate ?? 100}%</p>
        </div>
      </div>

      {/* Active errand */}
      {dashboard?.active_errand && (
        <div>
          <h2 className="font-bold text-[#0A1628] mb-3">Active Errand</h2>
          <Link href={`/runner/errands/${dashboard.active_errand.public_id}`}>
            <div className="errandly-card border-2 border-[#FF6B00] hover:shadow-md transition">
              <div className="flex items-start justify-between">
                <div className="flex-1">
                  <p className="font-bold text-[#0A1628]">{dashboard.active_errand.title}</p>
                  <p className="text-sm text-gray-500 mt-1">Customer: {dashboard.active_errand.customer?.first_name}</p>
                  <div className="flex items-center gap-1 mt-2 text-sm text-gray-600">
                    <MapPin className="w-4 h-4 text-[#FF6B00]" />
                    <span>{dashboard.active_errand.pickup_address?.substring(0, 40)}...</span>
                  </div>
                </div>
                <div className="text-right ml-4">
                  <span className={`text-xs font-medium px-2.5 py-1 rounded-full ${STATUS_COLORS[dashboard.active_errand.status] || 'bg-gray-100 text-gray-700'}`}>
                    {dashboard.active_errand.status?.replace(/_/g, ' ')}
                  </span>
                  <p className="font-bold text-[#FF6B00] mt-2">₦{dashboard.active_errand.runner_earnings?.toLocaleString()}</p>
                </div>
              </div>
              <div className="mt-3 pt-3 border-t border-gray-100">
                <span className="text-[#FF6B00] text-sm font-medium">Tap to view details →</span>
              </div>
            </div>
          </Link>
        </div>
      )}

      {/* Available Errands */}
      {isOnline && !dashboard?.active_errand && (
        <div>
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-bold text-[#0A1628]">Available Errands Nearby</h2>
            <span className="text-xs text-gray-500 bg-gray-100 px-2 py-1 rounded-full">
              {availableErrands?.data?.length ?? 0} available
            </span>
          </div>

          {availableErrands?.data?.length === 0 ? (
            <div className="errandly-card text-center py-10">
              <Package className="w-12 h-12 text-gray-300 mx-auto mb-3" />
              <p className="text-gray-500">No errands available in your area</p>
              <p className="text-gray-400 text-sm mt-1">Refresh or expand your search area</p>
            </div>
          ) : (
            <div className="space-y-3">
              {availableErrands?.data?.map((errand: any) => (
                <div key={errand.id} className="errandly-card">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <span className={`text-xs px-2.5 py-0.5 rounded-full font-medium ${
                          errand.urgency === 'urgent' ? 'bg-red-100 text-red-700' : 'bg-blue-100 text-blue-700'
                        }`}>
                          {errand.urgency === 'urgent' ? '⚡ Urgent' : '🕐 Standard'}
                        </span>
                        <span className="text-xs text-gray-500">{errand.distance_km?.toFixed(1)}km away</span>
                      </div>
                      <p className="font-semibold text-[#0A1628] mt-2">{errand.title}</p>
                      <p className="text-sm text-gray-500 mt-1 line-clamp-2">{errand.description}</p>
                      <div className="flex items-center gap-1 mt-2 text-sm text-gray-600">
                        <MapPin className="w-4 h-4 text-[#FF6B00]" />
                        <span className="text-xs">{errand.pickup_address?.substring(0, 50)}...</span>
                      </div>
                    </div>
                    <div className="ml-4 text-right">
                      <p className="text-2xl font-bold text-[#FF6B00]">₦{errand.budget?.toLocaleString()}</p>
                      <p className="text-xs text-gray-500 mt-1">Your earnings</p>
                    </div>
                  </div>
                  <div className="flex gap-2 mt-4">
                    <button
                      onClick={() => acceptMutation.mutate(errand.public_id)}
                      disabled={acceptMutation.isPending}
                      className="flex-1 errandly-btn-primary text-sm py-2.5 flex items-center justify-center gap-2"
                    >
                      {acceptMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : null}
                      Accept Errand
                    </button>
                    <button className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm text-gray-600 hover:bg-gray-50 transition">
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
